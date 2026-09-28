//
//  TeamListViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the team list screen.
@Observable
@MainActor
final class TeamListViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    /// Deletes one team and its games.
    func delete(_ team: Team) {
        attempt { try deps.team.delete(team) }
    }
}
