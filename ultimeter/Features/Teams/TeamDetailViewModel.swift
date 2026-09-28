//
//  TeamDetailViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the team detail screen. Owns the roster.
@Observable
@MainActor
final class TeamDetailViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    private let team: Team

    init(team: Team) {
        self.team = team
    }

    /// The roster sorted by name.
    var roster: [Player] {
        team.players.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// Removes the players at the given rows.
    func remove(at offsets: IndexSet) {
        for player in offsets.map({ roster[$0] }) {
            attempt { try deps.team.remove(player, from: team) }
        }
    }
}
