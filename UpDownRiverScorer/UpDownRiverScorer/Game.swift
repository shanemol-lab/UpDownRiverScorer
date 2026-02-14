//
//  Game.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation
import SwiftData

@Model
final class Game {
    var id: UUID
    var createdAt: Date

    // Settings locked from your rules
    var reserveTrumpCard: Bool
    var dealerForbiddenBidEnabled: Bool = true
    var playerCount: Int
    var maxCards: Int

    // Relationship
    @Relationship(deleteRule: .cascade) var players: [Player]
    @Relationship(deleteRule: .cascade) var rounds: [Round]

    /// Allows manual early completion
    var manualCompletionDate: Date? = nil

    /// If true, the game has begun the downward sequence early
    var startedBackDown: Bool = false

    /// When true, show a one-time hint in Game view instructing the user to tap Round 1 to begin.
    var showFirstVisitHint: Bool = true

    /// When true, suppresses the "Lock in Bids" confirmation sheet for the remainder of this game.
    var suppressBidLockConfirmation: Bool = false

    /// Stable clockwise seating order (Player 1, Player 2, ...)
    var orderedPlayers: [Player] {
        players.sorted { $0.sortIndex < $1.sortIndex }
    }

    init(players: [Player], reserveTrumpCard: Bool = true, dealerForbiddenBidEnabled: Bool = true, customMaxCards: Int? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.reserveTrumpCard = reserveTrumpCard
        self.dealerForbiddenBidEnabled = dealerForbiddenBidEnabled
        self.players = players.sorted { $0.sortIndex < $1.sortIndex }
        self.rounds = []

        self.playerCount = players.count
        let defaultMax = Rules.maxCards(playerCount: players.count, reserveTrumpCard: reserveTrumpCard)
        if let cm = customMaxCards {
            self.maxCards = min(defaultMax, max(1, cm))
        } else {
            self.maxCards = defaultMax
        }
    }

    /// Dealer rotates by round index; round 0 dealer = Player 1 (orderedPlayers[0])
    func dealer(forRoundIndex index: Int) -> Player {
        let ps = orderedPlayers
        return ps[index % ps.count]
    }

    /// Sequence: 1..max..1, with optional early back-down once `startedBackDown` is set
    func cardsPerPlayer(forRoundIndex index: Int) -> Int {
        // Standard sequence if not started back down
        if !startedBackDown {
            let seq = Rules.roundSequence(maxCards: maxCards)
            return seq[index]
        }
        // Early back-down: compute from the current context
        // Determine the last played round's cardsPerPlayer, or assume 1 if none
        let sorted = rounds.sorted { $0.index < $1.index }
        let lastCards = sorted.last?.cardsPerPlayer ?? 1
        // If already at 1, stay at 1
        if lastCards <= 1 { return 1 }
        // Build a descending sequence from lastCards-1 to 1
        let down = Array(stride(from: lastCards - 1, through: 1, by: -1))
        // Index relative to when early back-down starts: the first call after setting the flag should return lastCards-1
        let relative = index - (sorted.last?.index ?? -1) - 1
        if relative >= 0 && relative < down.count {
            return down[relative]
        } else {
            // Clamp to 1 if we run out
            return 1
        }
    }

    /// Total number of rounds in this game. If we started back down early, cap the total to the current index plus the remaining rounds to 1.
    var totalRounds: Int {
        if !startedBackDown {
            return Rules.roundSequence(maxCards: maxCards).count
        }
        // When started back down early, determine how many more rounds remain from the current lastCards down to 1
        let sorted = rounds.sorted { $0.index < $1.index }
        guard let last = sorted.last else {
            // No rounds yet; fall back to standard sequence
            return Rules.roundSequence(maxCards: maxCards).count
        }
        let lastCards = last.cardsPerPlayer
        // Remaining rounds after the last index: (lastCards-1) rounds to reach 1
        let remaining = max(0, lastCards - 1)
        // Total rounds = rounds completed so far (last.index + 1) + remaining to reach 1
        return (last.index + 1) + remaining
    }

    /// True if the next round (based on existing rounds) would still be in the upward phase
    @Transient
    var isCurrentlyHeadingUp: Bool {
        // No rounds yet -> heading up
        guard let last = rounds.sorted(by: { $0.index < $1.index }).last else { return true }
        return last.cardsPerPlayer < maxCards
    }

    /// Returns true if the game is completed either by manual completion or by the final round being valid
    @Transient
    var isGameCompleted: Bool {
        if manualCompletionDate != nil {
            return true
        }
        guard let lastRound = rounds.last else { return false }
        return lastRound.isValid && rounds.count >= totalRounds
    }
    /// Returns the completion date, either manual or inferred from the last round's creation date
    @Transient
    var gameCompletionDate: Date? {
        if let manualDate = manualCompletionDate {
            return manualDate
        }
        return rounds.last?.createdAt
    }
}

