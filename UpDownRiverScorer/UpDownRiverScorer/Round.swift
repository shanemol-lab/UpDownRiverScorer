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

    /// Returns true when bids and tricks are both valid for this round.
    /// Pass the game's `dealerForbiddenBidEnabled` setting so the dealer-forbidden rule
    /// is applied consistently with how the game was configured.
    func isValid(enforceDealerForbidden: Bool) -> Bool {
        guard let dealerId = dealer?.id else { return false }
        let R = cardsPerPlayer

        var bidsByPlayer: [UUID: Int] = [:]
        var tricksByPlayer: [UUID: Int] = [:]
        for e in entries {
            if let pid = e.player?.id {
                bidsByPlayer[pid] = e.bid
                tricksByPlayer[pid] = e.tricks
            }
        }

        let bidsOK = Rules.validateBids(cardsPerPlayer: R, dealerPlayerId: dealerId, bidsByPlayerId: bidsByPlayer, enforceDealerForbidden: enforceDealerForbidden).isValid
        let tricksOK = Rules.validateTricks(cardsPerPlayer: R, tricksByPlayerId: tricksByPlayer).isValid
        return bidsOK && tricksOK
    }
}
