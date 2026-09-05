//
//  ultimeterApp.swift
//  ultimeter
//
//  Created by Muhan Li on 2026-08-26.
//

import SwiftUI
import SwiftData

@main
struct UltimeterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Team.self,
            Player.self,
            Game.self,
            Opponent.self,
            Tournament.self,
            Point.self,
            Halftime.self
        ])
        let storeURL = URL.applicationSupportDirectory.appending(path: "ultimeter.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TeamListView(context: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }
}
