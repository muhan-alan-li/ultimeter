//
//  TeamDetailViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the team detail screen.
enum TeamDetailError: Error, LocalizedError {
    case removeFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .removeFailed(let underlying):
            "The roster could not be updated. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `TeamDetailView`. Owns roster removal.
@Observable
@MainActor
final class TeamDetailViewModel {
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

    func removePlayer(_ player: Player, from team: Team) throws {
        guard team.players.contains(where: { $0 === player }) else { return }
        team.players.removeAll { $0 === player }
        do {
            try save()
        } catch {
            throw TeamDetailError.removeFailed(underlying: error)
        }
    }
}
