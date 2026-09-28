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
    var draft = PlayerDraft()

    private let team: Team

    init(team: Team) {
        self.team = team
    }

    /// The name without surrounding whitespace.
    var trimmedName: String {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the form can save.
    var canSave: Bool { !trimmedName.isEmpty }

    /// Adds the player to the team. Returns true on success.
    @discardableResult
    func save() -> Bool {
        attempt { try deps.team.addPlayer(draft, to: team) }
    }
}
