//
//  PointRules.swift
//  ultimeter
//

// swiftlint:disable file_length - the full guard table stays in one file by design.

import Foundation

/// The stage of a point on screen.
enum PointStage {
    case scheduled
    case defense
    case looseDisc
    case possession
    case complete
}

/// One action on a point.
enum PointAction: Equatable {
    case startPull
    case pull(Player)
    case block(Player)
    case pickup(Player)
    case pass(Player)
    case drop(Player)
    case score(Player)
    case ourTurnover
    case theirTurnover
    case sub
    case undoLastEvent
    case toggleLine(Player)
    case pruneLine
}

/// The state of one point and the actions it offers.
struct PointOffer {
    let stage: PointStage
    let holder: Player?
    let blockers: [Player]
    let scoredBy: ScoringTeam?
    /// The result of the point, when the point is complete.
    let outcome: PointOutcome?
    let line: [Player]
    let roster: [Player]
    let lineIsEditable: Bool
    let lineIssue: LineIssue?
    /// Whether the point started. A scheduled point hides the play details.
    let hasStarted: Bool
    /// Whether the user must pick a puller. True on a defense point.
    let pullerRequired: Bool
    let canPull: Bool
    let canSub: Bool
    let opponentCanScore: Bool
    /// Whether the last undoable point event can revert.
    let canUndo: Bool
    let isSubbing: Bool

    /// Whether the point is live and the line is locked.
    var isOngoing: Bool {
        stage == .defense || stage == .looseDisc || stage == .possession
    }

    /// Whether the line has every player it needs.
    var lineIsFull: Bool {
        line.count >= LineRules.size
    }
}

/// The rules of point entry.
/// The view model reads `offer`. The repository calls `check`.
/// Every function here is pure.
enum PointRules {
    /// Reads the point state and the actions it offers.
    static func offer(game: Game, point: Point) -> PointOffer {
        let isLive = game.status == .live
        let isComplete = LineRules.isComplete(point)
        let roster = LineRules.roster(of: game)
        let state = point.state
        let lineIsEditable = point.status == .scheduled
            || (point.status == .active && !state.lineLocked)
        return PointOffer(
            stage: stage(of: point, state: state),
            holder: state.holder,
            blockers: state.blockers,
            scoredBy: state.scoredBy,
            outcome: state.outcome,
            line: LineRules.sorted(point.line),
            roster: roster,
            lineIsEditable: lineIsEditable,
            lineIssue: LineRules.lineIssue(point: point, roster: roster),
            hasStarted: point.status != .scheduled,
            pullerRequired: point.startingPosition == .defense,
            canPull: isLive
                && point.status == .scheduled
                && isComplete
                && (point.startingPosition == .offense || state.puller != nil),
            canSub: isLive && point.status == .active && point.lineLocked,
            opponentCanScore: point.status == .active
                ? (isComplete && state.hasPull && state.lineLocked)
                : point.status == .complete,
            canUndo: point.orderedEvents.last(where: { isUndoable($0.kind) }) != nil,
            isSubbing: state.isSubbing
        )
    }

    /// Guards one action. Throws `AppError` when the action is not allowed.
    static func check(_ action: PointAction, game: Game, point: Point) throws {
        try requireBelongs(game, point: point)
        switch action {
        case .toggleLine, .pruneLine:
            try checkLine(action, game: game, point: point)
        case .startPull, .pull, .block, .pickup:
            try checkField(action, game: game, point: point)
        case .pass, .drop, .score, .ourTurnover, .theirTurnover:
            try checkDisc(action, game: game, point: point)
        case .sub, .undoLastEvent:
            try checkEdit(action, game: game, point: point)
        }
    }

    private static func checkLine(
        _ action: PointAction,
        game: Game,
        point: Point
    ) throws {
        switch action {
        case .toggleLine(let player):
            guard LineRules.isEditable(point) else { throw AppError.lineLocked }
            guard !point.line.contains(where: { $0 === player }) else { return }
            guard game.team.players.contains(where: { $0 === player }) else {
                throw AppError.notOnTeam
            }
            guard point.line.count < LineRules.size else {
                throw AppError.lineFull(required: LineRules.size)
            }
        case .pruneLine:
            return
        default:
            throw AppError.invalidAction
        }
    }

    private static func checkField(
        _ action: PointAction,
        game: Game,
        point: Point
    ) throws {
        switch action {
        case .startPull:
            try checkStartPull(game, point)
        case .pull(let player):
            try checkPull(game, point, player)
        case .block(let player):
            try checkBlock(game, point, player)
        case .pickup(let player):
            try checkPickup(game, point, player)
        default:
            throw AppError.invalidAction
        }
    }

    private static func checkDisc(
        _ action: PointAction,
        game: Game,
        point: Point
    ) throws {
        try requireLive(game)
        try requireActive(point)
        switch action {
        case .pass(let receiver):
            try checkPass(game, point, receiver)
        case .drop(let receiver):
            try checkDrop(game, point, receiver)
        case .score(let player):
            try checkScore(game, point, player)
        case .ourTurnover:
            guard point.phase == .possession else { throw AppError.invalidAction }
            guard point.holder != nil else { throw AppError.missingPickup }
        case .theirTurnover:
            guard point.phase == .defense else { throw AppError.invalidAction }
        default:
            throw AppError.invalidAction
        }
    }

    private static func checkEdit(
        _ action: PointAction,
        game: Game,
        point: Point
    ) throws {
        try requireLive(game)
        guard point.status == .active else { throw AppError.invalidAction }
        switch action {
        case .sub:
            return
        case .undoLastEvent:
            guard point.orderedEvents.last(where: { isUndoable($0.kind) }) != nil
            else {
                throw AppError.invalidAction
            }
        default:
            throw AppError.invalidAction
        }
    }

    /// Event kinds that revert with the general undo.
    /// Pulls start the point. Scores end it. Neither reverts.
    private static let undoableKinds: Set<EventKind> = [
        .pickup, .pass, .drop, .block, .turnover
    ]

    static func isUndoable(_ kind: EventKind) -> Bool {
        undoableKinds.contains(kind)
    }
}

// MARK: - Per-action guards and shared checks

/// The per-action guards and the shared checks of point entry.
extension PointRules {
    static func checkStartPull(_ game: Game, _ point: Point) throws {
        try requireLive(game)
        guard point.status == .scheduled else { throw AppError.notScheduled }
        guard activePoints(in: game).isEmpty else { throw AppError.multipleActivePoints }
        let open = openPoints(in: game)
        guard open.count == 1, open.first === point else { throw AppError.invalidAction }
        try requireCompleteLine(point)
        if point.startingPosition == .defense {
            guard let puller = point.puller else { throw AppError.missingPull }
            guard point.line.contains(where: { $0 === puller }) else {
                throw AppError.notOnLine
            }
        }
    }

    static func checkPull(_ game: Game, _ point: Point, _ player: Player) throws {
        try requireLive(game)
        guard point.status == .scheduled else { throw AppError.notScheduled }
        guard point.startingPosition == .defense else { throw AppError.invalidAction }
        guard point.line.contains(where: { $0 === player }) else {
            throw AppError.notOnLine
        }
    }

    static func checkBlock(_ game: Game, _ point: Point, _ player: Player) throws {
        try requireLive(game)
        try requireActive(point)
        guard point.phase == .defense else { throw AppError.invalidAction }
        guard point.line.contains(where: { $0 === player }) else {
            throw AppError.notOnLine
        }
    }

    static func checkPickup(_ game: Game, _ point: Point, _ player: Player) throws {
        try requireLive(game)
        try requireActive(point)
        switch point.phase {
        case .awaitingPickup:
            break
        case .possession:
            let holder = point.holder
            let holderOnLine = holder.map { held in
                point.line.contains { $0 === held }
            } ?? false
            guard !holderOnLine else { throw AppError.invalidAction }
        default:
            throw AppError.invalidAction
        }
        guard point.line.contains(where: { $0 === player }) else {
            throw AppError.notOnLine
        }
    }

    static func checkPass(_ game: Game, _ point: Point, _ receiver: Player) throws {
        try requireLive(game)
        try requireActive(point)
        try requireLocked(point)
        guard point.phase == .possession else { throw AppError.invalidAction }
        guard let holder = point.holder else { throw AppError.missingPickup }
        guard point.line.contains(where: { $0 === holder }) else {
            throw AppError.notOnLine
        }
        guard point.line.contains(where: { $0 === receiver }) else {
            throw AppError.notOnLine
        }
        guard receiver !== holder else { throw AppError.invalidAction }
    }

    static func checkDrop(_ game: Game, _ point: Point, _ receiver: Player) throws {
        try requireLive(game)
        try requireActive(point)
        try requireLocked(point)
        guard point.phase == .possession else { throw AppError.invalidAction }
        guard let holder = point.holder,
            point.line.contains(where: { $0 === holder }) else {
            throw AppError.missingPickup
        }
        guard point.line.contains(where: { $0 === receiver }) else {
            throw AppError.notOnLine
        }
        guard receiver !== holder else { throw AppError.invalidAction }
    }

    static func checkScore(_ game: Game, _ point: Point, _ player: Player) throws {
        try requireLive(game)
        try requireActive(point)
        try requireLocked(point)
        let active = activePoints(in: game)
        guard active.count == 1, active.first === point else {
            throw AppError.multipleActivePoints
        }
        try requireCompleteLine(point)
        guard point.hasPull else { throw AppError.missingPull }
        guard point.phase == .possession else { throw AppError.invalidAction }
        guard let holder = point.holder,
            point.line.contains(where: { $0 === holder }) else {
            throw AppError.missingPickup
        }
        guard point.line.contains(where: { $0 === player }) else {
            throw AppError.notOnLine
        }
        guard player !== holder else { throw AppError.invalidAction }
    }

    /// Guards the completion of one point, or the edit of a result.
    static func checkResult(_ game: Game, point: Point, scoredBy: ScoringTeam) throws {
        try requireBelongs(game, point: point)
        switch point.status {
        case .active:
            try checkActiveResult(game, point: point, scoredBy: scoredBy)
        case .complete:
            guard game.status == .live || game.status == .ended else {
                throw AppError.notLive
            }
        case .scheduled:
            throw AppError.invalidAction
        }
    }

    /// Guards the completion of a live point.
    private static func checkActiveResult(
        _ game: Game,
        point: Point,
        scoredBy: ScoringTeam
    ) throws {
        try requireLocked(point)
        let active = activePoints(in: game)
        guard active.count == 1, active.first === point else {
            throw AppError.multipleActivePoints
        }
        try requireCompleteLine(point)
        guard point.hasPull else {
            throw AppError.missingPull
        }
        guard scoredBy == .us else { return }
        guard let holder = point.holder else { throw AppError.missingPickup }
        guard let scorer = point.scorer else { throw AppError.missingScorer }
        guard scorer === holder else { throw AppError.notHolder }
        guard point.line.contains(where: { $0 === scorer }) else {
            throw AppError.notOnLine
        }
    }

    // MARK: - Shared checks

    static func requireBelongs(_ game: Game, point: Point) throws {
        guard point.game === game else { throw AppError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw AppError.detachedPoint
        }
    }

    static func requireLive(_ game: Game) throws {
        guard game.status == .live else { throw AppError.notLive }
    }

    static func requireActive(_ point: Point) throws {
        guard point.status == .active else { throw AppError.invalidAction }
    }

    /// Requires a locked line. Pass, drop, and score stay blocked while subbing.
    static func requireLocked(_ point: Point) throws {
        guard point.lineLocked else { throw AppError.invalidAction }
    }

    static func requireCompleteLine(_ point: Point) throws {
        guard LineRules.isComplete(point) else {
            throw AppError.lineIncomplete(
                current: point.line.count,
                required: LineRules.size
            )
        }
    }

    static func stage(of point: Point, state: PointState) -> PointStage {
        if point.status == .complete { return .complete }
        if point.status == .scheduled { return .scheduled }
        switch state.phase {
        case .defense:
            return .defense
        case .awaitingPickup:
            return .looseDisc
        case .possession:
            guard let holder = state.holder else { return .looseDisc }
            return point.line.contains { $0 === holder } ? .possession : .looseDisc
        case .none:
            return .scheduled
        }
    }

    static func activePoints(in game: Game) -> [Point] {
        game.points.filter { $0.status == .active }
    }

    static func openPoints(in game: Game) -> [Point] {
        game.points.filter { $0.status != .complete }
    }
}
