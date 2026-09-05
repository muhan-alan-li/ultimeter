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
    var isSaving = false

    init(context: ModelContext) {
        self.context = context
    }

    private func save() throws {
        isSaving = true
        defer { isSaving = false }
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
        let point = Point(
            sequence: game.nextSequence,
            number: number,
            status: status,
            startingPosition: side,
            game: game
        )
        game.nextSequence += 1
        context.insert(point)
        game.points.append(point)
        return point
    }

    private func insertHalftime(in game: Game, pointNumber: Int) {
        let half = Halftime(
            sequence: game.nextSequence,
            pointNumber: pointNumber,
            game: game
        )
        game.nextSequence += 1
        context.insert(half)
        game.halftime = half
    }

    private func deletePoint(_ point: Point, from game: Game) {
        game.points.removeAll { $0 === point }
        context.delete(point)
    }

    func completeActivePoint(_ game: Game, scoredBy: ScoringTeam) throws {
        guard game.status == .live else { throw PointDetailError.notLive }
        let active = activePoints(in: game)
        guard active.count == 1, let point = active.first else {
            if active.isEmpty { throw PointDetailError.noActivePoint }
            throw PointDetailError.multipleActivePoints
        }
        guard point.game === game else { throw PointDetailError.detachedPoint }
        do {
            point.scoredBy = scoredBy
            point.status = .complete
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
            _ = insertPoint(in: game, number: nextNumber, side: side, status: .active)
            try save()
        } catch let error as PointDetailError {
            context.rollback()
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
        if let active = activePoints(in: game).first {
            deletePoint(active, from: game)
        }
        game.status = .ended
    }

    private func reopenEndedGame(_ game: Game) {
        game.status = .live
        let nextNumber = (maxCompletedNumber(in: game) ?? 0) + 1
        let side = sideForNextPoint(in: game, nextNumber: nextNumber)
        _ = insertPoint(in: game, number: nextNumber, side: side, status: .active)
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
            try save()
        } catch let error as PointDetailError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw PointDetailError.saveFailed(underlying: error)
        }
    }
}
