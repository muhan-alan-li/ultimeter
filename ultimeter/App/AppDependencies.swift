//
//  AppDependencies.swift
//  ultimeter
//

import Foundation
import Observation
import SwiftData

/// The repositories of the app. The app installs one in the environment.
@Observable
final class AppDependencies {
    let team: any TeamRepository
    let game: any GameRepository
    let point: any PointRepository

    /// Builds the repositories for one store container.
    init(container: ModelContainer) {
        let context = container.mainContext
        team = SwiftDataTeamRepository(context: context)
        game = SwiftDataGameRepository(context: context)
        point = SwiftDataPointRepository(context: context)
    }
}
