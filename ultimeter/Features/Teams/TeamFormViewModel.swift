//
//  TeamFormViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the team form. Owns the draft and the name rules.
@Observable
@MainActor
final class TeamFormViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    /// The editable values of the form.
    var draft: TeamDraft

    private let team: Team?

    init(team: Team? = nil) {
        self.team = team
        draft = TeamDraft(team: team)
    }

    var isEditing: Bool { team != nil }

    /// The name without surrounding whitespace.
    var trimmedName: String {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether another team already uses this name.
    func hasDuplicate(in teams: [Team]) -> Bool {
        guard !trimmedName.isEmpty else { return false }
        return teams.contains { candidate in
            candidate.id != team?.id
                && candidate.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    /// Whether the form can save.
    func canSave(in teams: [Team]) -> Bool {
        !trimmedName.isEmpty && !hasDuplicate(in: teams)
    }

    /// Saves the team. Returns true on success.
    @discardableResult
    func save() -> Bool {
        attempt { try deps.team.saveTeam(draft, editing: team) }
    }
}
