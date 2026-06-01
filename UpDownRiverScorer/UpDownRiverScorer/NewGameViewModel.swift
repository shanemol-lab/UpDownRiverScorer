//
//  NewGameViewModel.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class NewGameViewModel: ObservableObject {
    @Published var playerCount: Int = 4
    @Published var names: [String] = Array(repeating: "", count: 4)
    // Rule toggles (defaults)
    @Published var reserveTrumpCard: Bool = true
    @Published var dealerForbiddenBidEnabled: Bool = true
    @Published var maximumHandSizeEnabled: Bool = false
    @Published var maximumHandSize: Int? = nil

    var allowedMaxCards: Int {
        Rules.maxCards(playerCount: playerCount, reserveTrumpCard: reserveTrumpCard)
    }

    func setPlayerCount(_ count: Int) {
        let clamped = min(8, max(3, count))
        playerCount = clamped
        if names.count < clamped {
            names.append(contentsOf: Array(repeating: "", count: clamped - names.count))
        } else if names.count > clamped {
            names = Array(names.prefix(clamped))
        }
        // Clamp maximum hand size to allowed range when player count changes
        if maximumHandSizeEnabled {
            let allowed = Rules.maxCards(playerCount: clamped, reserveTrumpCard: reserveTrumpCard)
            if let m = maximumHandSize {
                maximumHandSize = min(max(1, m), allowed)
            }
        }
    }

    func createGame(modelContext: ModelContext) -> Game {
        let players = names.enumerated().map { idx, name in
            Player(name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Player \(idx+1)" : name,
                   sortIndex: idx)
        }
        let allowedDefault = Rules.maxCards(playerCount: players.count, reserveTrumpCard: reserveTrumpCard)
        let customMax = maximumHandSizeEnabled ? min(allowedDefault, max(1, maximumHandSize ?? allowedDefault)) : nil
        let game = Game(players: players, reserveTrumpCard: reserveTrumpCard, dealerForbiddenBidEnabled: dealerForbiddenBidEnabled, customMaxCards: customMax)
        // Persist the game
        modelContext.insert(game)
        return game
    }
}

