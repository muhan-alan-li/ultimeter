//
//  PlayerFormViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the new-player screen.
enum PlayerFormError: Error, LocalizedError {
    case emptyName
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Player name cannot be empty."
        case .saveFailed(let underlying):
            "The player could not be saved. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `PlayerFormView`. Owns new-player creation.
@Observable
@MainActor
final class PlayerFormViewModel {
    private let context: ModelContext
    private let team: Team

    var name: String = ""
    var gender: Gender = .nonBinary
    var isSaving = false

    init(context: ModelContext, team: Team) {
        self.context = context
        self.team = team
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
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

    func savePlayer() throws {
        guard !trimmedName.isEmpty else { throw PlayerFormError.emptyName }
        let player = Player(name: trimmedName, gender: gender)
        context.insert(player)
        team.players.append(player)
        do {
            try save()
        } catch let error as PlayerFormError {
            throw error
        } catch {
            throw PlayerFormError.saveFailed(underlying: error)
        }
    }
}
