//
//  ScoringEngine.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation

struct ScoringEngine {

    /// Returns totals by playerId across all rounds (using entries as source of truth).
    static func totals(game: Game) -> [UUID: Int] {
        var totals: [UUID: Int] = [:]
        for p in game.players { totals[p.id] = 0 }

        for round in game.rounds.sorted(by: { $0.index < $1.index }) {
            let R = round.cardsPerPlayer
            let trickValues = round.entries.map { $0.tricks }
            let totalTricks = trickValues.reduce(0, +)
            let tricksInRange = trickValues.allSatisfy { $0 >= 0 && $0 <= R }

            // Only count a round when all tricks have been assigned and the sum equals R
            guard tricksInRange && totalTricks == R else { continue }

            for entry in round.entries {
                guard let pid = entry.player?.id else { continue }
                totals[pid, default: 0] += Rules.score(bid: entry.bid, tricks: entry.tricks)
            }
        }
        return totals
    }
}
