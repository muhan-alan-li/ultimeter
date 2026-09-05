//
//  GameDetailViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the game detail screen.
enum GameDetailError: Error, LocalizedError {
    case notScheduled
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notScheduled:
            "The game is not scheduled. This action is not allowed."
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
    var isSaving = false

    init(context: ModelContext) {
        self.context = context
    }

    func startGame(_ game: Game) throws {
        guard game.status == .scheduled else { throw GameDetailError.notScheduled }
        game.status = .live
        isSaving = true
        defer { isSaving = false }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw GameDetailError.saveFailed(underlying: error)
        }
    }
}
