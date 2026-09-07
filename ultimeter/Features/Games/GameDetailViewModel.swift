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
    case invalidTarget(Int)
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notScheduled:
            "The game is not scheduled. This action is not allowed."
        case .alreadyStarted:
            "The game already started. This action is not allowed."
        case .invalidTarget(let target):
            "Invalid target \(target). Choose 13, 15, 17, 19, or 21."
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
        guard Game.allowedTargets.contains(game.targetPoints) else {
            throw GameDetailError.invalidTarget(game.targetPoints)
        }
        do {
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
}
