//
//  PointRules.swift
//  ultimeter
//

import Foundation

/// The stage of a point on screen.
enum PointStage {
    case scheduled
    case defense
    case looseDisc
    case possession
    case complete
}

/// A problem with the line of a point.
enum LineProblem: Equatable {
    case incomplete(current: Int, required: Int)
    case rosterTooSmall(have: Int, required: Int)
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
    case undoBlock
    case undoDrop
    case undoLastTurnover
    case undoLastPass
    case toggleLine(Player)
    case pruneLine
}

/// The state of one point and the actions it offers.
struct PointOffer {
    let stage: PointStage
    let phase: PossessionState
    let holder: Player?
    let puller: Player?
    let blockers: [Player]
    let scoredBy: ScoringTeam?
    /// The result of the point, when the point is complete.
    let outcome: PointOutcome?
    let passCount: Int
    let dropCount: Int
    let line: [Player]
    let roster: [Player]
    let lineIsEditable: Bool
    let lineProblem: LineProblem?
    /// Whether the point started. A scheduled point hides the play details.
    let hasStarted: Bool
    /// Whether the user must pick a puller. True on a defense point.
    let pullerRequired: Bool
    let canPull: Bool
    let canSub: Bool
    let canScore: Bool
    let opponentCanScore: Bool
    let canUndoLastPass: Bool
    let canUndoTurnover: Bool
    let canUndoDrop: Bool
    let canUndoBlock: Bool
    let needsPickup: Bool

    /// Whether the point is live and the line is locked.
    var isOngoing: Bool {
        stage == .defense || stage == .looseDisc || stage == .possession
    }

    /// Whether a sub is in progress. The line is open on a live point.
    var isSubbing: Bool {
        lineIsEditable && isOngoing
    }

    /// Whether the line has every player it needs.
    var lineIsFull: Bool {
        line.count >= LineRules.size
    }

    /// Whether the holder is on the line.
    var holderOnLine: Bool {
        guard let holder else { return false }
        return line.contains { $0 === holder }
    }
}

/// The rules of point entry.
/// The view model reads `offer`. The repository calls `check`.
/// Every function here is pure.
enum PointRules {
    /// Reads the point state and the actions it offers.
    static func offer(game: Game, point: Point) -> PointOffer {
        let events = events(of: point)
        let phase = point.phase
        let holder = PointFold.holder(events)
        let hasPull = PointFold.hasPull(events)
        let isLive = game.status == .live
        let isComplete = LineRules.isComplete(point)
        let lastKind = point.orderedStats.last?.kind
        let roster = LineRules.roster(of: game)
        let holderOnLine = holder.map { held in
            point.line.contains { $0 === held }
        } ?? false

        return PointOffer(
            stage: stage(of: point, phase: phase, hasHolder: holderOnLine),
            phase: phase,
            holder: holder,
            puller: PointFold.puller(events),
            blockers: PointFold.blockers(events),
            scoredBy: point.scoredBy,
            outcome: point.outcome,
            passCount: PointFold.passCount(events),
            dropCount: PointFold.dropCount(events),
            line: LineRules.sorted(point.line),
            roster: roster,
            lineIsEditable: LineRules.isEditable(point),
            lineProblem: lineProblem(point: point, roster: roster),
            hasStarted: point.status != .scheduled,
            pullerRequired: point.startingPosition == .defense,
            canPull: isLive
                && point.status == .scheduled
                && isComplete
                && (point.startingPosition == .offense || point.puller != nil),
            canSub: isLive && point.status == .active && point.lineLocked,
            canScore: point.status == .complete
                || (point.status == .active && isComplete && point.lineLocked),
            opponentCanScore: point.status == .active
                ? (isComplete && hasPull && point.lineLocked)
                : point.status == .complete,
            canUndoLastPass: point.passCount > 0,
            canUndoTurnover: lastKind == .turnover,
            canUndoDrop: lastKind == .drop,
            canUndoBlock: lastKind == .block,
            needsPickup: point.status == .active && !holderOnLine
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
        case .sub, .undoBlock, .undoDrop, .undoLastTurnover, .undoLastPass:
            try checkUndo(action, game: game, point: point)
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

    private static func checkUndo(
        _ action: PointAction,
        game: Game,
        point: Point
    ) throws {
        try requireLive(game)
        guard point.status == .active else { throw AppError.invalidAction }
        switch action {
        case .sub:
            return
        case .undoBlock:
            try requireLastStat(.block, in: point)
        case .undoDrop:
            try requireLastStat(.drop, in: point)
        case .undoLastTurnover:
            guard point.orderedStats.last(where: { $0.kind == .turnover }) != nil else {
                throw AppError.invalidAction
            }
        case .undoLastPass:
            guard point.phase == .possession,
                point.orderedStats.contains(where: { $0.kind == .pass })
            else {
                throw AppError.invalidAction
            }
        default:
            throw AppError.invalidAction
        }
    }

    /// Requires the last stat of a point to have one kind.
    private static func requireLastStat(_ kind: StatKind, in point: Point) throws {
        guard point.orderedStats.last?.kind == kind else {
            throw AppError.invalidAction
        }
    }
}
