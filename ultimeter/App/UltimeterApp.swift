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
            Tournament.self
        ])
        let storeURL = URL.applicationSupportDirectory.appending(path: "ultimeter.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        // Past games are discarded: use a fresh store and remove the legacy
        // default.store left by earlier builds.
        try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "default.store"))
        try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "default.store-shm"))
        try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "default.store-wal"))

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If the fresh store still fails to load, remove it and retry
            // rather than crash on launch.
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "ultimeter.store-shm"))
            try? FileManager.default.removeItem(at: URL.applicationSupportDirectory.appending(path: "ultimeter.store-wal"))
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            TeamListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
