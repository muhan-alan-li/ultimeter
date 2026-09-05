//
//  AddExistingPlayerViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the add-existing-player screen.
enum AddExistingPlayerError: Error, LocalizedError {
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let underlying):
            "The player could not be added. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `AddExistingPlayerView`. Owns existing-player adds.
@Observable
@MainActor
final class AddExistingPlayerViewModel {
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

    func add(_ player: Player, to team: Team) throws {
        guard !team.players.contains(where: { $0 === player }) else { return }
        team.players.append(player)
        do {
            try save()
        } catch {
            throw AddExistingPlayerError.saveFailed(underlying: error)
        }
    }
}
