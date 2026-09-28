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
    var sharedModelContainer: ModelContainer = AppSchema.container()

    var body: some Scene {
        WindowGroup {
            TeamListView()
                .environment(AppDependencies(container: sharedModelContainer))
        }
        .modelContainer(sharedModelContainer)
    }
}
