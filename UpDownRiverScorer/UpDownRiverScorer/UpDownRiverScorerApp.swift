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
    let sharedModelContainer: ModelContainer?
    let containerError: Error?

    init() {
        let schema = Schema([
            Game.self,
            Player.self,
            Round.self,
            RoundEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            containerError = nil
        } catch {
            sharedModelContainer = nil
            containerError = error
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                GameListView()
                    .modelContainer(container)
            } else {
                StorageErrorView(error: containerError)
            }
        }
    }
}

private struct StorageErrorView: View {
    let error: Error?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Unable to Load Data")
                .font(.title2).bold()
            Text("Your game data could not be loaded. This may be due to a storage issue or an app update that requires a reset.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let error {
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Text("Please try restarting the app. If the problem persists, deleting and reinstalling the app will resolve it.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
