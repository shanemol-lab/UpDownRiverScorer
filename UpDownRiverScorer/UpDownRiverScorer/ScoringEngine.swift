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
            guard round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) else { continue }
            for entry in round.entries {
                guard let pid = entry.player?.id else { continue }
                totals[pid, default: 0] += Rules.score(bid: entry.bid, tricks: entry.tricks)
            }
        }
        return totals
    }

    /// Returns cumulative totals per player after each completed round, in round order.
    /// Used by chart views to build progressive score and rank series without
    /// duplicating the scoring accumulation logic.
    static func cumulativeTotalsPerRound(game: Game) -> [(round: Round, totals: [UUID: Int])] {
        var running: [UUID: Int] = Dictionary(uniqueKeysWithValues: game.players.map { ($0.id, 0) })
        var result: [(round: Round, totals: [UUID: Int])] = []
        for round in game.roundsSorted where round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) {
            for entry in round.entries {
                guard let pid = entry.player?.id else { continue }
                running[pid, default: 0] += Rules.score(bid: entry.bid, tricks: entry.tricks)
            }
            result.append((round: round, totals: running))
        }
        return result
    }
}
