//
//  GameDetailViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the game detail screen.
enum GameDetailError: Error, LocalizedError {
    case notScheduled
    case alreadyStarted
    case notLive
    case invalidScore
    case invalidTarget(Int)
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notScheduled:
            "The game is not scheduled. This action is not allowed."
        case .alreadyStarted:
            "The game already started. This action is not allowed."
        case .notLive:
            "The game is not live. This action is not allowed."
        case .invalidScore:
            "Invalid score. Scores must be zero or higher."
        case .invalidTarget(let target):
            "Invalid target \(target). Choose a value from 1 to 21."
        case .saveFailed(let underlying):
            "The game could not be updated. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `GameDetailView`. Owns game start.
@Observable
@MainActor
final class GameDetailViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw GameDetailError.saveFailed(underlying: error)
        }
    }

    func startGame(_ game: Game) throws {
        guard game.status == .scheduled else { throw GameDetailError.notScheduled }
        guard game.points.isEmpty else { throw GameDetailError.alreadyStarted }
        guard Game.validTargetRange.contains(game.targetPoints) else {
            throw GameDetailError.invalidTarget(game.targetPoints)
        }
        do {
            game.halftimeTarget = (game.targetPoints + 1) / 2
            let point = game.makePoint(number: 1, side: game.startingPosition, status: .active)
            context.insert(point)
            game.points.append(point)
            game.status = .live
            try save()
        } catch let error as GameDetailError {
            throw error
        } catch {
            context.rollback()
            throw GameDetailError.saveFailed(underlying: error)
        }
    }

    func setPointCap(_ game: Game, to newCap: Int) throws {
        guard game.status == .live else { throw GameDetailError.notLive }
        let minimum = max(game.ourScore, game.theirScore) + 1
        guard (minimum ... Game.validTargetRange.upperBound).contains(newCap) else {
            throw GameDetailError.invalidTarget(newCap)
        }
        do {
            game.targetPoints = newCap
            try save()
        } catch let error as GameDetailError {
            throw error
        } catch {
            context.rollback()
            throw GameDetailError.saveFailed(underlying: error)
        }
    }

    func endGame(_ game: Game, ourScore: Int, theirScore: Int) throws {
        guard game.status == .live else { throw GameDetailError.notLive }
        guard ourScore >= 0 && theirScore >= 0 else { throw GameDetailError.invalidScore }
        do {
            if ourScore == game.ourScore && theirScore == game.theirScore {
                if let active = game.points.first(where: { $0.status == .active }) {
                    game.points.removeAll { $0 === active }
                    context.delete(active)
                }
                game.status = .ended
                try save()
                return
            }
            for point in game.points {
                context.delete(point)
            }
            game.points.removeAll()
            if let half = game.halftime {
                context.delete(half)
                game.halftime = nil
            }
            game.nextSequence = 0
            var number = 1
            for _ in 0 ..< ourScore {
                let point = game.makePoint(number: number, side: game.startingPosition, status: .complete)
                point.scoredBy = .us
                context.insert(point)
                game.points.append(point)
                number += 1
            }
            for _ in 0 ..< theirScore {
                let point = game.makePoint(number: number, side: game.startingPosition, status: .complete)
                point.scoredBy = .them
                context.insert(point)
                game.points.append(point)
                number += 1
            }
            game.status = .ended
            try save()
        } catch let error as GameDetailError {
            throw error
        } catch {
            context.rollback()
            throw GameDetailError.saveFailed(underlying: error)
        }
    }
}
