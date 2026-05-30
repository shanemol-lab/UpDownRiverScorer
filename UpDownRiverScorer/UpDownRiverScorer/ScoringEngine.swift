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

        for round in game.roundsSorted {
            // Use the same validity gate as the UI so scored rounds are consistent
            // with rounds shown as complete.
            guard round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) else { continue }

            for entry in round.entries {
                guard let pid = entry.player?.id else { continue }
                totals[pid, default: 0] += Rules.score(bid: entry.bid, tricks: entry.tricks)
            }
        }
        return totals
    }
}
