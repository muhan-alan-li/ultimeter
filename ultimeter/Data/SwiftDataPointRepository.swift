//
//  SwiftDataPointRepository.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The SwiftData implementation of the point aggregate.
/// Every method is one guard and one write.
@MainActor
final class SwiftDataPointRepository: PointRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Line

    func toggleLine(_ player: Player, in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.toggleLine(player), game: game, point: point)
        let holder = point.holder
        try context.write {
            if let index = point.line.firstIndex(where: { $0 === player }) {
                point.line.remove(at: index)
                return
            }
            point.line.append(player)
            if point.status == .active, let holder, player !== holder,
                !point.line.contains(where: { $0 === holder }) {
                transferHolder(from: holder, to: player, in: point)
            }
            if point.status == .active, LineRules.isComplete(point) {
                point.lineLocked = true
            }
        }
    }

    func pruneLine(in point: Point) throws {
        let game = try requireGame(of: point)
        let remaining = LineRules.pruned(point.line, roster: game.team.players)
        guard remaining.count != point.line.count else { return }
        let wasLocked = point.status == .active && point.lineLocked
        guard wasLocked || LineRules.isEditable(point) else { return }
        try context.write {
            point.line = remaining
            if wasLocked { point.lineLocked = false }
        }
    }

    func unlockLine(in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.sub, game: game, point: point)
        try context.write {
            point.lineLocked = false
        }
    }

    // MARK: - Pull

    func startPull(in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.startPull, game: game, point: point)
        try context.write {
            if point.startingPosition != .defense {
                _ = setStatPlayer(in: point, kind: .pull, to: nil)
            }
            activate(point)
        }
    }

    func pull(in point: Point, by player: Player) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.pull(player), game: game, point: point)
        try context.write {
            _ = setStatPlayer(in: point, kind: .pull, to: player)
            activate(point)
        }
    }

    // MARK: - Disc

    func recordPickup(in point: Point, by player: Player) throws {
        try append(.pickup(player), kind: .pickup, to: point) { stat in
            stat.player = player
        }
    }

    func recordPass(in point: Point, to receiver: Player) throws {
        let holder = point.holder
        try append(.pass(receiver), kind: .pass, to: point) { stat in
            stat.player = holder
            stat.relatedPlayer = receiver
        }
    }

    func recordDrop(in point: Point, to receiver: Player) throws {
        let holder = point.holder
        try append(.drop(receiver), kind: .drop, to: point) { stat in
            stat.player = holder
            stat.relatedPlayer = receiver
        }
    }

    func recordBlock(in point: Point, by player: Player) throws {
        try append(.block(player), kind: .block, to: point) { stat in
            stat.player = player
        }
    }

    func recordOurTurnover(in point: Point) throws {
        try append(.ourTurnover, kind: .turnover, to: point) { _ in }
    }

    func recordTheirTurnover(in point: Point) throws {
        try append(.theirTurnover, kind: .turnover, to: point) { _ in }
    }

    // MARK: - Undo

    func undoLastPass(in point: Point) throws {
        try remove(.undoLastPass, kind: .pass, from: point)
    }

    func undoDrop(in point: Point) throws {
        try remove(.undoDrop, kind: .drop, from: point)
    }

    func undoBlock(in point: Point) throws {
        try remove(.undoBlock, kind: .block, from: point)
    }

    func undoLastTurnover(in point: Point) throws {
        try remove(.undoLastTurnover, kind: .turnover, from: point)
    }

    // MARK: - Result

    func scoreByPlayer(_ player: Player, in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.score(player), game: game, point: point)
        let holder = point.holder
        try context.write {
            let pass = point.makeStat(kind: .pass)
            pass.player = holder
            pass.relatedPlayer = player
            context.insert(pass)
            point.stats.append(pass)
            _ = setStatPlayer(in: point, kind: .goal, to: player)
            finish(point, in: game, scoredBy: .us)
        }
    }

    /// Completes a live point, or edits the result of a finished point.
    func recordScore(
        of point: Point,
        in game: Game,
        scoredBy: ScoringTeam
    ) throws {
        try PointRules.checkResult(game, point: point, scoredBy: scoredBy)
        if point.status == .active {
            try context.write {
                if scoredBy == .them, let goal = goalStat(in: point) {
                    deleteStat(goal, from: point)
                }
                finish(point, in: game, scoredBy: scoredBy)
            }
            return
        }
        guard point.scoredBy != scoredBy else { return }
        try context.write {
            point.scoredBy = scoredBy
            if scoredBy == .them, let goal = goalStat(in: point) {
                deleteStat(goal, from: point)
            }
            insertHalftimeIfNeeded(in: game)
            let reachedTarget = GameProgress.reachedTarget(game)
            if game.status == .live && reachedTarget {
                endGame(game)
                return
            }
            if game.status == .ended && !reachedTarget {
                reopenGame(game)
            }
            if let open = game.currentPoint {
                open.startingPosition = GameProgress.side(
                    ofPoint: open.number,
                    in: game
                )
            }
        }
    }

    // MARK: - Result helpers

    /// Marks a point complete and opens the next point.
    private func finish(_ point: Point, in game: Game, scoredBy: ScoringTeam) {
        point.scoredBy = scoredBy
        point.status = .complete
        point.lineLocked = true
        guard !GameProgress.reachedTarget(game) else {
            game.status = .ended
            return
        }
        insertHalftimeIfNeeded(in: game)
        insertPoint(in: game, number: GameProgress.nextPointNumber(in: game))
    }

    /// Opens the second half when a score reaches the halftime target.
    private func insertHalftimeIfNeeded(in game: Game) {
        guard GameProgress.isHalftimeReached(game) else { return }
        let number = GameProgress.nextPointNumber(in: game)
        let half = game.makeHalftime(pointNumber: number)
        context.insert(half)
        game.halftime = half
    }

    private func endGame(_ game: Game) {
        for open in game.points.filter({ $0.status != .complete }) {
            game.points.removeAll { $0 === open }
            context.delete(open)
        }
        game.status = .ended
    }

    private func reopenGame(_ game: Game) {
        game.status = .live
        insertPoint(in: game, number: GameProgress.nextPointNumber(in: game))
    }

    private func insertPoint(in game: Game, number: Int) {
        let side = GameProgress.side(ofPoint: number, in: game)
        let point = game.makePoint(number: number, side: side, status: .scheduled)
        context.insert(point)
        game.points.append(point)
    }
}

// MARK: - Stat helpers

extension SwiftDataPointRepository {

    /// Moves the disc to the incoming sub when the holder subs out.
    /// Finds the pickup or pass that defines the holder and repoints it.
    /// Runs inside the line write, so the swap stays atomic.
    private func transferHolder(from old: Player, to new: Player, in point: Point) {
        var defining: Stat?
        var isPass = false
        for stat in point.orderedStats {
            switch stat.kind {
            case .turnover, .drop:
                defining = nil
            case .pickup:
                defining = stat
                isPass = false
            case .pass:
                defining = stat
                isPass = true
            default:
                break
            }
        }
        guard let defining else { return }
        if isPass {
            defining.relatedPlayer = new
        } else {
            defining.player = new
        }
    }

    private func activate(_ point: Point) {
        point.status = .active
        point.lineLocked = true
    }

    /// Guards one append action, then adds the stat in one write.
    private func append(
        _ action: PointAction,
        kind: StatKind,
        to point: Point,
        configure: (Stat) -> Void
    ) throws {
        let game = try requireGame(of: point)
        try PointRules.check(action, game: game, point: point)
        try context.write {
            let stat = point.makeStat(kind: kind)
            configure(stat)
            context.insert(stat)
            point.stats.append(stat)
        }
    }

    /// Guards one undo action, then removes the stat in one write.
    /// Drop and block undos remove the last stat. The guard proved its kind.
    private func remove(
        _ action: PointAction,
        kind: StatKind,
        from point: Point
    ) throws {
        let game = try requireGame(of: point)
        try PointRules.check(action, game: game, point: point)
        let stat: Stat?
        switch action {
        case .undoDrop, .undoBlock:
            stat = point.orderedStats.last
        default:
            stat = point.orderedStats.last(where: { $0.kind == kind })
        }
        guard let stat else { throw AppError.invalidAction }
        try context.write {
            deleteStat(stat, from: point)
        }
    }

    private func setStatPlayer(
        in point: Point,
        kind: StatKind,
        to player: Player?
    ) -> Stat {
        if let existing = point.orderedStats.first(where: { $0.kind == kind }) {
            existing.player = player
            return existing
        }
        let stat = point.makeStat(kind: kind)
        stat.player = player
        context.insert(stat)
        point.stats.append(stat)
        return stat
    }

    private func goalStat(in point: Point) -> Stat? {
        point.orderedStats.first { $0.kind == .goal }
    }

    private func deleteStat(_ stat: Stat, from point: Point) {
        point.stats.removeAll { $0 === stat }
        context.delete(stat)
    }

    private func requireGame(of point: Point) throws -> Game {
        guard let game = point.game, game.points.contains(where: { $0 === point }) else {
            throw AppError.detachedPoint
        }
        return game
    }
}
