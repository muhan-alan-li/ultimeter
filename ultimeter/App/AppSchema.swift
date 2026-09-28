//
//  AppSchema.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The SwiftData models of the app.
enum AppSchema {
    /// Every model in the store. Keep this list complete.
    static let models: [any PersistentModel.Type] = [
        Team.self,
        Player.self,
        Game.self,
        Opponent.self,
        Tournament.self,
        Point.self,
        Stat.self,
        Halftime.self
    ]

    /// The schema of the store.
    static var schema: Schema {
        Schema(models)
    }

    /// Builds the store container of the app.
    static func container() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// Builds an in-memory container for previews.
    static func previewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }

    /// The location of the store on the device.
    private static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "ultimeter.store")
    }
}
