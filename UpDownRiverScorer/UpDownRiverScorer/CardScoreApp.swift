//
//  CardScoreApp.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import SwiftUI
import SwiftData

// Removed duplicate @main app entry; use UpDownRiverScorerApp as the single app entry.
struct CardScoreApp: App {
    var body: some Scene {
        WindowGroup {
            GameListView()
        }
        .modelContainer(for: [Game.self, Player.self, Round.self, RoundEntry.self])
    }
}
