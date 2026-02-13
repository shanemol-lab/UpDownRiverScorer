//
//  UpDownRiverScorerApp.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//

import SwiftUI
import SwiftData

@main
struct UpDownRiverScorerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self,
            Player.self,
            Round.self,
            RoundEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

