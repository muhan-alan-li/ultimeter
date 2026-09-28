//
//  AddExistingPlayerViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the add-existing-player screen.
@Observable
@MainActor
final class AddExistingPlayerViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    private let team: Team

    init(team: Team) {
        self.team = team
    }

    /// The players who are not on the team yet.
    func available(in players: [Player]) -> [Player] {
        players.filter { player in
            !player.teams.contains { $0 === team }
        }
    }

    /// Adds one player to the team. Returns true on success.
    @discardableResult
    func add(_ player: Player) -> Bool {
        attempt { try deps.team.addExisting(player, to: team) }
    }
}
