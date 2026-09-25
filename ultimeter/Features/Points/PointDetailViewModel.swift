//
//  PointDetailViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the point detail screen.
enum PointDetailError: Error, LocalizedError {
    case notLive
    case noActivePoint
    case multipleActivePoints
    case notScheduledPoint
    case notActivePoint
    case lineIncomplete(current: Int, required: Int)
    case missingPull
    case missingPickup
    case missingScorer
    case notHolder
    case notOnLine
    case invalidPoint
    case detachedPoint
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notLive:
            "The game is not live. This action is not allowed."
        case .noActivePoint:
            "There is no active point."
        case .multipleActivePoints:
            "There is more than one active point."
        case .notScheduledPoint:
            "This point already started. This action is not allowed."
        case .notActivePoint:
            "This point is not active. This action is not allowed."
        case .lineIncomplete(let current, let required):
            "The line has \(current) of \(required) players. Add more players."
        case .missingPull:
            "This point has no puller. Select a puller."
        case .missingPickup:
            "This point has no pickup. Select who picks up."
        case .missingScorer:
            "This point has no scorer. Select a scorer."
        case .notHolder:
            "Only the holder can score."
        case .notOnLine:
            "This player is not on the line."
        case .invalidPoint:
            "This point cannot change in its current state."
        case .detachedPoint:
            "This point does not belong to this game."
        case .saveFailed(let underlying):
            "The point could not be updated. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `PointDetailView`. Owns point result entry.
@Observable
@MainActor
final class PointDetailViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    private func activePoints(in game: Game) -> [Point] {
        game.points.filter { $0.status == .active }
    }

    private func maxCompletedNumber(in game: Game) -> Int? {
        game.points.filter { $0.status == .complete }.map(\.number).max()
    }

    private func lastCompletedPoint(in game: Game) -> Point? {
        game.points.filter { $0.status == .complete }.max { $0.number < $1.number }
    }

    private func opposite(of side: StartingPosition) -> StartingPosition {
        side == .offense ? .defense : .offense
    }

    private func sideForNextPoint(in game: Game, nextNumber: Int) -> StartingPosition {
        if let half = game.halftime, nextNumber == half.pointNumber {
            return opposite(of: game.startingPosition)
        }
        guard let last = lastCompletedPoint(in: game) else {
            return game.startingPosition
        }
        switch last.scoredBy {
        case .us:
            return .defense
        case .them:
            return .offense
        case nil:
            return game.startingPosition
        }
    }

    private func insertPoint(in game: Game, number: Int, side: StartingPosition, status: PointStatus) -> Point {
        let point = game.makePoint(number: number, side: side, status: status)
        context.insert(point)
        game.points.append(point)
        return point
    }

    private func insertHalftime(in game: Game, pointNumber: Int) {
        let half = game.makeHalftime(pointNumber: pointNumber)
        context.insert(half)
        game.halftime = half
    }

    private func deletePoint(_ point: Point, from game: Game) {
        game.points.removeAll { $0 === point }
        context.delete(point)
    }

    private func openPoints(in game: Game) -> [Point] {
        game.points.filter { $0.status != .complete }
    }

    private func pullStat(in point: Point) -> Stat? {
        point.orderedStats.first { $0.kind == .pull }
    }

    private func goalStat(in point: Point) -> Stat? {
        point.orderedStats.first { $0.kind == .goal }
    }

    private func deleteStat(_ stat: Stat, from point: Point) {
        point.stats.removeAll { $0 === stat }
        context.delete(stat)
    }

    private func setStatPlayer(in point: Point, kind: StatKind, to player: Player?) -> Stat {
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

    /// Pull with one player in a single tap on a scheduled defense point.
    func pullForUs(_ game: Game, point: Point, player: Player) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw PointDetailError.detachedPoint
        }
        guard point.status == .scheduled else { throw PointDetailError.notScheduledPoint }
        guard point.startingPosition == .defense else { throw PointDetailError.invalidPoint }
        guard point.line.contains(where: { $0 === player }) else {
            throw PointDetailError.notOnLine
        }
        do {
            _ = setStatPlayer(in: point, kind: .pull, to: player)
            try startPull(game, point: point)
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Record a block by one player. Blocks stack over stands.
    /// The disc stays loose. Pick up to take possession.
    func recordBlock(_ game: Game, point: Point, player: Player) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw PointDetailError.detachedPoint
        }
        guard point.status == .active else { throw PointDetailError.notActivePoint }
        guard point.phase == .defense else { throw PointDetailError.invalidPoint }
        guard point.line.contains(where: { $0 === player }) else {
            throw PointDetailError.notOnLine
        }
        do {
            let stat = point.makeStat(kind: .block)
            stat.player = player
            context.insert(stat)
            point.stats.append(stat)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Delete the last block to fix a wrong tap.
    func clearLastBlock(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard let last = point.orderedStats.last, last.kind == .block else {
            throw PointDetailError.invalidPoint
        }
        do {
            deleteStat(last, from: point)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Score on one receiver in a single tap.
    /// Logs the final pass from the holder, then the goal.
    func scoreForUs(_ game: Game, point: Point, player: Player) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard point.phase == .possession else { throw PointDetailError.invalidPoint }
        guard let holder = point.holder,
            point.line.contains(where: { $0 === holder }) else {
            throw PointDetailError.missingPickup
        }
        guard point.line.contains(where: { $0 === player }) else {
            throw PointDetailError.notOnLine
        }
        guard player !== holder else { throw PointDetailError.invalidPoint }
        do {
            try recordPass(game, point: point, receiver: player)
            _ = setStatPlayer(in: point, kind: .goal, to: player)
            try completeActivePoint(game, scoredBy: .us)
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    private func requireActiveOffer(_ game: Game, point: Point) throws {
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw PointDetailError.detachedPoint
        }
        guard point.status == .active else { throw PointDetailError.notActivePoint }
    }

    /// Record who picks up. Works after their pull on offense
    /// and after our block on defense. Allows a new pickup
    /// when the holder leaves the line.
    func recordPickup(_ game: Game, point: Point, player: Player) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        switch point.phase {
        case .awaitingPickup:
            break
        case .possession:
            if let holder = point.holder,
                point.line.contains(where: { $0 === holder }) {
                throw PointDetailError.invalidPoint
            }
        default:
            throw PointDetailError.invalidPoint
        }
        guard point.line.contains(where: { $0 === player }) else {
            throw PointDetailError.notOnLine
        }
        do {
            let stat = point.makeStat(kind: .pickup)
            stat.player = player
            context.insert(stat)
            point.stats.append(stat)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Record a pass from the holder to one receiver.
    /// Works on offense and on defense after pickup.
    func recordPass(_ game: Game, point: Point, receiver: Player) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard point.phase == .possession else { throw PointDetailError.invalidPoint }
        guard let holder = point.holder else { throw PointDetailError.missingPickup }
        guard point.line.contains(where: { $0 === holder }) else {
            throw PointDetailError.notOnLine
        }
        guard point.line.contains(where: { $0 === receiver }) else {
            throw PointDetailError.notOnLine
        }
        guard receiver !== holder else { throw PointDetailError.invalidPoint }
        do {
            let stat = point.makeStat(kind: .pass)
            stat.player = holder
            stat.relatedPlayer = receiver
            context.insert(stat)
            point.stats.append(stat)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Log a dropped pass to one receiver in a single tap.
    /// Records the throw plus the drop. They take possession.
    func recordDrop(_ game: Game, point: Point, receiver: Player) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard point.phase == .possession else { throw PointDetailError.invalidPoint }
        guard let holder = point.holder,
            point.line.contains(where: { $0 === holder }) else {
            throw PointDetailError.missingPickup
        }
        guard point.line.contains(where: { $0 === receiver }) else {
            throw PointDetailError.notOnLine
        }
        guard receiver !== holder else { throw PointDetailError.invalidPoint }
        do {
            let stat = point.makeStat(kind: .drop)
            stat.player = holder
            stat.relatedPlayer = receiver
            context.insert(stat)
            point.stats.append(stat)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Delete the last drop to undo it.
    func clearDrop(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard let last = point.orderedStats.last, last.kind == .drop else {
            throw PointDetailError.invalidPoint
        }
        do {
            deleteStat(last, from: point)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Delete the last pass to fix a wrong pick.
    func clearLastPass(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard point.phase == .possession else { throw PointDetailError.invalidPoint }
        guard let last = point.orderedStats.last(where: { $0.kind == .pass }) else {
            throw PointDetailError.invalidPoint
        }
        do {
            deleteStat(last, from: point)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Log that we gave it away. They take possession.
    func logOurTurnover(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard point.phase == .possession else { throw PointDetailError.invalidPoint }
        guard point.holder != nil else { throw PointDetailError.missingPickup }
        do {
            let stat = point.makeStat(kind: .turnover)
            context.insert(stat)
            point.stats.append(stat)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Log that they threw it away. The disc stays loose.
    func logTheirTurnover(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard point.phase == .defense else { throw PointDetailError.invalidPoint }
        do {
            let stat = point.makeStat(kind: .turnover)
            context.insert(stat)
            point.stats.append(stat)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Delete the last turnover to undo it. The phase follows the log.
    func clearTurnover(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        try requireActiveOffer(game, point: point)
        guard let turnover = point.orderedStats.last(where: { $0.kind == .turnover }) else {
            throw PointDetailError.invalidPoint
        }
        do {
            deleteStat(turnover, from: point)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Start a scheduled point. Locks in the 7-player line.
    func startPull(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw PointDetailError.detachedPoint
        }
        guard point.status == .scheduled else { throw PointDetailError.notScheduledPoint }
        let actives = activePoints(in: game)
        guard actives.isEmpty else { throw PointDetailError.multipleActivePoints }
        let opens = openPoints(in: game)
        guard opens.count == 1, opens.first === point else { throw PointDetailError.invalidPoint }
        guard point.line.count == PointLineViewModel.maxLineSize else {
            throw PointDetailError.lineIncomplete(
                current: point.line.count,
                required: PointLineViewModel.maxLineSize
            )
        }
        do {
            if point.startingPosition == .defense {
                guard let pull = pullStat(in: point), let puller = pull.player else {
                    throw PointDetailError.missingPull
                }
                guard point.line.contains(where: { $0 === puller }) else {
                    throw PointDetailError.notOnLine
                }
            } else {
                _ = setStatPlayer(in: point, kind: .pull, to: nil)
            }
            point.status = .active
            point.lineLocked = true
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    /// Unlock the line on an active point so players can sub in.
    /// The point stays active. No new pull is needed.
    func unlockForSub(_ game: Game, point: Point) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw PointDetailError.detachedPoint
        }
        guard point.status == .active else { throw PointDetailError.notActivePoint }
        do {
            point.lineLocked = false
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    func completeActivePoint(_ game: Game, scoredBy: ScoringTeam) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        let active = activePoints(in: game)
        guard active.count == 1, let point = active.first else {
            if active.isEmpty { throw PointDetailError.noActivePoint }
            throw PointDetailError.multipleActivePoints
        }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard point.line.count == PointLineViewModel.maxLineSize else {
            throw PointDetailError.lineIncomplete(
                current: point.line.count,
                required: PointLineViewModel.maxLineSize
            )
        }
        guard pullStat(in: point) != nil else { throw PointDetailError.missingPull }
        do {
            if scoredBy == .us {
                guard let holder = point.holder else {
                    throw PointDetailError.missingPickup
                }
                guard let goal = goalStat(in: point), let scorer = goal.player else {
                    throw PointDetailError.missingScorer
                }
                guard scorer === holder else { throw PointDetailError.notHolder }
                guard point.line.contains(where: { $0 === scorer }) else {
                    throw PointDetailError.notOnLine
                }
            } else if let goal = goalStat(in: point) {
                deleteStat(goal, from: point)
            }
            point.scoredBy = scoredBy
            point.status = .complete
            point.lineLocked = true
            if game.ourScore >= game.targetPoints || game.theirScore >= game.targetPoints {
                game.status = .ended
                try save()
                return
            }
            if game.halftime == nil
                && (game.ourScore == game.halfTarget || game.theirScore == game.halfTarget) {
                insertHalftime(in: game, pointNumber: point.number + 1)
            }
            let nextNumber = (maxCompletedNumber(in: game) ?? 0) + 1
            let side = sideForNextPoint(in: game, nextNumber: nextNumber)
            _ = insertPoint(in: game, number: nextNumber, side: side, status: .scheduled)
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }

    private func insertHalftimeIfNeeded(in game: Game) {
        guard game.halftime == nil else { return }
        guard game.ourScore == game.halfTarget || game.theirScore == game.halfTarget else { return }
        let nextNumber = (maxCompletedNumber(in: game) ?? 0) + 1
        insertHalftime(in: game, pointNumber: nextNumber)
    }

    private func reachedTarget(_ game: Game) -> Bool {
        game.ourScore >= game.targetPoints || game.theirScore >= game.targetPoints
    }

    private func endLiveGame(_ game: Game) {
        for open in openPoints(in: game) {
            deletePoint(open, from: game)
        }
        game.status = .ended
    }

    private func reopenEndedGame(_ game: Game) {
        game.status = .live
        let nextNumber = (maxCompletedNumber(in: game) ?? 0) + 1
        let side = sideForNextPoint(in: game, nextNumber: nextNumber)
        _ = insertPoint(in: game, number: nextNumber, side: side, status: .scheduled)
    }

    func updatePointResult(_ game: Game, point: Point, scoredBy: ScoringTeam) throws {
        guard game.status == .live || game.status == .ended else {
            throw PointDetailError.notLive
        }
        guard point.status == .complete else { throw PointDetailError.invalidPoint }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        guard game.points.contains(where: { $0 === point }) else {
            throw PointDetailError.detachedPoint
        }
        if point.scoredBy == scoredBy { return }
        do {
            point.scoredBy = scoredBy
            if scoredBy == .them, let goal = goalStat(in: point) {
                deleteStat(goal, from: point)
            }
            insertHalftimeIfNeeded(in: game)
            let done = reachedTarget(game)
            if game.status == .live && done {
                endLiveGame(game)
                try save()
                return
            }
            if game.status == .ended && !done {
                reopenEndedGame(game)
            }
            if let active = game.currentPoint {
                active.startingPosition = sideForNextPoint(in: game, nextNumber: active.number)
            }
            try save()
        } catch let error as PointDetailError {
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }
}
