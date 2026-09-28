//
//  PointGuards.swift
//  ultimeter
//

import Foundation

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
        guard PointFold.hasPull(events(of: point)) else { throw AppError.missingPull }
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
        guard PointFold.hasPull(events(of: point)) else {
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

    static func stage(
        of point: Point,
        phase: PossessionState,
        hasHolder: Bool
    ) -> PointStage {
        if point.status == .complete { return .complete }
        if point.status == .scheduled { return .scheduled }
        switch phase {
        case .defense:
            return .defense
        case .awaitingPickup:
            return .looseDisc
        case .possession:
            return hasHolder ? .possession : .looseDisc
        case .none:
            return .scheduled
        }
    }

    static func lineProblem(point: Point, roster: [Player]) -> LineProblem? {
        guard point.status != .complete else { return nil }
        if roster.count < LineRules.size {
            return .rosterTooSmall(have: roster.count, required: LineRules.size)
        }
        if point.status == .active, !LineRules.isComplete(point) {
            return .incomplete(current: point.line.count, required: LineRules.size)
        }
        return nil
    }

    static func events(of point: Point) -> [PointEvent] {
        point.orderedStats.map {
            PointEvent(kind: $0.kind, player: $0.player, relatedPlayer: $0.relatedPlayer)
        }
    }

    static func activePoints(in game: Game) -> [Point] {
        game.points.filter { $0.status == .active }
    }

    static func openPoints(in game: Game) -> [Point] {
        game.points.filter { $0.status != .complete }
    }
}
