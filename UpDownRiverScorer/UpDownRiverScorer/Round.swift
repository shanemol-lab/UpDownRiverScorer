//
//  Round.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation
import SwiftData

@Model
final class Round {
    var id: UUID
    var index: Int
    var cardsPerPlayer: Int
    var createdAt: Date

    // Relationship
    var dealer: Player?
    @Relationship(deleteRule: .cascade) var entries: [RoundEntry]

    init(index: Int, cardsPerPlayer: Int, dealer: Player, players: [Player]) {
        self.id = UUID()
        self.index = index
        self.cardsPerPlayer = cardsPerPlayer
        self.createdAt = Date()
        self.dealer = dealer

        // Precreate entries for stable ordering & easy UI binding
        self.entries = players
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { RoundEntry(player: $0) }
    }

    /// Computed validity of the round based on current bids and tricks
    @Transient
    var isValid: Bool {
        // Require a dealer
        guard let dealerId = dealer?.id else { return false }
        let R = cardsPerPlayer

        // Build maps of bids and tricks per player
        var bidsByPlayer: [UUID: Int] = [:]
        var tricksByPlayer: [UUID: Int] = [:]
        for e in entries {
            if let pid = e.player?.id {
                bidsByPlayer[pid] = e.bid
                tricksByPlayer[pid] = e.tricks
            }
        }

        // Validate using Rules (dealer forbidden bid is enforced by game settings elsewhere; default to true here)
        let bidsOK = Rules.validateBids(cardsPerPlayer: R, dealerPlayerId: dealerId, bidsByPlayerId: bidsByPlayer, enforceDealerForbidden: true).isValid
        let tricksOK = Rules.validateTricks(cardsPerPlayer: R, tricksByPlayerId: tricksByPlayer).isValid
        return bidsOK && tricksOK
    }
}
