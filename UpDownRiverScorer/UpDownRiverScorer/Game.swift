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

    /// The round index at which early back-down was triggered. Stored once so
    /// cardsPerPlayer(forRoundIndex:) has a stable pivot that doesn't shift as
    /// new rounds are appended.
    var backDownPivotIndex: Int? = nil

    /// The card count of the last played round when early back-down was triggered.
    var backDownPivotCards: Int? = nil

    /// When true, show a one-time hint in Game view instructing the user to tap Round 1 to begin.
    var showFirstVisitHint: Bool = true

    /// When true, suppresses the "Lock in Bids" confirmation sheet for the remainder of this game.
    var suppressBidLockConfirmation: Bool = false

    /// Stable clockwise seating order (Player 1, Player 2, ...)
    var orderedPlayers: [Player] {
        players.sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Rounds in ascending index order — use this instead of `rounds` wherever order matters.
    var roundsSorted: [Round] {
        rounds.sorted { $0.index < $1.index }
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
        precondition(!ps.isEmpty, "dealer(forRoundIndex:) called on a game with no players")
        return ps[index % ps.count]
    }

    /// Sequence: 1..max..1, with optional early back-down once `startedBackDown` is set
    func cardsPerPlayer(forRoundIndex index: Int) -> Int {
        if !startedBackDown {
            let seq = Rules.roundSequence(maxCards: maxCards)
            precondition(index < seq.count, "cardsPerPlayer(forRoundIndex:) out-of-bounds: index \(index), seq.count \(seq.count)")
            return seq[index]
        }
        // Use stable pivot values recorded when back-down was triggered.
        // Falling back to live data would shift the pivot each time a new round is appended.
        let pivotIndex = backDownPivotIndex ?? (roundsSorted.last?.index ?? -1)
        let pivotCards = backDownPivotCards ?? (roundsSorted.last?.cardsPerPlayer ?? 1)
        if pivotCards <= 1 { return 1 }
        let down = Array(stride(from: pivotCards - 1, through: 1, by: -1))
        let relative = index - pivotIndex - 1
        if relative >= 0 && relative < down.count {
            return down[relative]
        }
        assertionFailure("cardsPerPlayer(forRoundIndex:) out-of-bounds: index \(index), pivotIndex \(pivotIndex), pivotCards \(pivotCards)")
        return 1
    }

    /// Total number of rounds in this game. If we started back down early, cap the total to the current index plus the remaining rounds to 1.
    var totalRounds: Int {
        if !startedBackDown {
            return Rules.roundSequence(maxCards: maxCards).count
        }
        // Use stable pivot values so totalRounds doesn't shift as new rounds are appended.
        guard let pivotIndex = backDownPivotIndex, let pivotCards = backDownPivotCards else {
            return Rules.roundSequence(maxCards: maxCards).count
        }
        // Rounds up to and including the pivot + descending rounds from pivotCards-1 down to 1
        let remaining = max(0, pivotCards - 1)
        return (pivotIndex + 1) + remaining
    }

    /// True if the next round (based on existing rounds) would still be in the upward phase
    @Transient
    var isCurrentlyHeadingUp: Bool {
        // No rounds yet -> heading up
        guard let last = roundsSorted.last else { return true }
        return !startedBackDown && last.cardsPerPlayer < maxCards
    }

    @Transient
    var completedRounds: [Round] {
        roundsSorted.filter { $0.isValid(enforceDealerForbidden: dealerForbiddenBidEnabled) }
    }

    /// Returns true if the game is completed either by manual completion or by the final round being valid
    @Transient
    var isGameCompleted: Bool {
        if manualCompletionDate != nil {
            return true
        }
        let sorted = roundsSorted
        guard let lastRound = sorted.last else { return false }
        return lastRound.index == totalRounds - 1
            && lastRound.isValid(enforceDealerForbidden: dealerForbiddenBidEnabled)
    }
    /// Returns the completion date, either manual or inferred from the last round's creation date
    @Transient
    var gameCompletionDate: Date? {
        if let manualDate = manualCompletionDate {
            return manualDate
        }
        return roundsSorted.last?.createdAt
    }
}

