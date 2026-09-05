//
//  GameListViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the game list screen.
enum GameListError: Error, LocalizedError {
    case deleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let underlying):
            "The game could not be deleted. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `GameListView`. Owns game deletion.
@Observable
@MainActor
final class GameListViewModel {
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
            throw error
        }
    }

    func deleteGame(_ game: Game) throws {
        context.delete(game)
        do {
            try save()
        } catch {
            throw GameListError.deleteFailed(underlying: error)
        }
    }
}
