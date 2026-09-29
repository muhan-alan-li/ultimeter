//
//  PlayerFormViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the new-player form. Owns the draft.
@Observable
@MainActor
final class PlayerFormViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    /// The editable values of the form.
    var draft: PlayerDraft

    private let team: Team

    init(team: Team) {
        self.team = team
        draft = PlayerDraft(team: team)
    }

    /// Whether the form can save.
    var canSave: Bool {
        draft.names.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Adds an empty player row.
    func addName() {
        draft.names.append(PlayerNameDraft())
    }

    /// Removes a player row while keeping one row available.
    func removeName(id: UUID) {
        guard draft.names.count > 1 else { return }
        draft.names.removeAll { $0.id == id }
    }

    /// Adds the player to the team. Returns true on success.
    @discardableResult
    func save() -> Bool {
        attempt { try deps.team.addPlayers(draft, to: team) }
    }
}
