//
//  GameFormViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the game form. Owns the draft.
@Observable
@MainActor
final class GameFormViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    /// The editable values of the form.
    var draft: GameDraft

    private let team: Team
    private let game: Game?

    init(team: Team, game: Game? = nil) {
        self.team = team
        self.game = game
        draft = GameDraft(game: game)
    }

    var isEditing: Bool { game != nil }

    /// The opponent name without surrounding whitespace.
    var trimmedOpponentName: String {
        draft.opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the form can save.
    var canSave: Bool { !trimmedOpponentName.isEmpty }

    /// Setup controls stay enabled before the game starts only.
    var isSetupEditable: Bool {
        guard let game else { return true }
        return GameProgress.isSetupEditable(game)
    }

    /// Saves the game. Returns true on success.
    @discardableResult
    func save() -> Bool {
        attempt { try deps.game.saveGame(draft, for: team, editing: game) }
    }
}
