//
//  RoundEditorViewModel.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation
import SwiftUI
import Combine

@MainActor
final class RoundEditorViewModel: ObservableObject {

    let titleLeadingPadding: CGFloat = 12
    let doneTrailingPadding: CGFloat = 12

    enum Phase: String, CaseIterable {
        case bids = "Bids"
        case tricks = "Tricks"
    }

    @Published var bidMessage: String?
    @Published var trickMessage: String?

    @Published var totalBids: Int = 0

    /// Recompute the total bids from the given round and publish the result.
    func updateTotalBids(from round: Round) {
        var sum = 0
        for e in round.entries {
            sum += e.bid
        }
        totalBids = sum
    }

    func validateBids(round: Round, enforceDealerForbidden: Bool = true) -> Bool {
        guard let dealerId = round.dealer?.id else { return false }
        let R = round.cardsPerPlayer

        var bids: [UUID: Int] = [:]
        for e in round.entries {
            if let pid = e.player?.id { bids[pid] = e.bid }
        }

        let result = Rules.validateBids(cardsPerPlayer: R, dealerPlayerId: dealerId, bidsByPlayerId: bids, enforceDealerForbidden: enforceDealerForbidden)
        bidMessage = result.message
        updateTotalBids(from: round)
        return result.isValid
    }

    func validateTricks(round: Round) -> Bool {
        let R = round.cardsPerPlayer

        var tricks: [UUID: Int] = [:]
        for e in round.entries {
            if let pid = e.player?.id { tricks[pid] = e.tricks }
        }

        let result = Rules.validateTricks(cardsPerPlayer: R, tricksByPlayerId: tricks)
        trickMessage = result.message
        return result.isValid
    }
}

