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
    case finalScoreBelowCurrent
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
        case .finalScoreBelowCurrent:
            "Invalid final score. Final score cannot be below the current score."
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
            let point = game.makePoint(number: 1, side: game.startingPosition, status: .scheduled)
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
        guard ourScore >= game.ourScore && theirScore >= game.theirScore else {
            throw GameDetailError.finalScoreBelowCurrent
        }
        do {
            let opens = game.points.filter { $0.status != .complete }
            for open in opens {
                game.points.removeAll { $0 === open }
                context.delete(open)
            }
            if ourScore == game.ourScore && theirScore == game.theirScore {
                game.status = .ended
                try save()
                return
            }
            let additionalUs = ourScore - game.ourScore
            let additionalThem = theirScore - game.theirScore
            var number = (game.points.filter { $0.status == .complete }.map(\.number).max() ?? 0) + 1
            for _ in 0 ..< additionalUs {
                let point = game.makePoint(number: number, side: sideForNextPoint(in: game), status: .complete)
                point.scoredBy = .us
                context.insert(point)
                game.points.append(point)
                number += 1
            }
            for _ in 0 ..< additionalThem {
                let point = game.makePoint(number: number, side: sideForNextPoint(in: game), status: .complete)
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

    private func sideForNextPoint(in game: Game) -> StartingPosition {
        if let last = game.points.filter({ $0.status == .complete }).max(by: { $0.number < $1.number }) {
            switch last.scoredBy {
            case .us:
                return .defense
            case .them:
                return .offense
            case nil:
                return game.startingPosition
            }
        }
        return game.startingPosition
    }
}
