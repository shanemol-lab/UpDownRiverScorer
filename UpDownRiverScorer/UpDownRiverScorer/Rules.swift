//
//  Rules.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation

enum Rules {

    // MARK: - Game setup

    static func maxCards(playerCount: Int, reserveTrumpCard: Bool) -> Int {
        precondition((3...8).contains(playerCount), "Supported players: 3–8")
        let deckUsable = reserveTrumpCard ? 51 : 52
        return deckUsable / playerCount // floor
    }

    static func roundSequence(maxCards: Int) -> [Int] {
        precondition(maxCards >= 1)
        if maxCards == 1 { return [1] }
        let up = Array(1...maxCards)
        let down = Array((1..<(maxCards)).reversed())
        return up + down
    }

    // MARK: - Scoring (your exact rules)

    static func score(bid: Int, tricks: Int) -> Int {
        let diff = abs(tricks - bid)
        
        //Correct bid
        if diff == 0 {
            //Special case: 0 bid made scores 10 (not 50)
            if bid == 0 {
                return 10
            }
            // For 1+ bids made: 50 + 10 per trick
            return 50 + 10 * tricks
        }
        //Incorrect bid: -10 per trick off
        return -10 * diff
    }

    // MARK: - Validation

    struct BidValidationResult: Equatable {
        var isValid: Bool
        var forbiddenDealerBid: Int? // when applicable
        var message: String?         // for UI
    }

    /// Dealer forbidden bid: dealer cannot bid (R - sum(nonDealerBids)) when it's within 0...R
    static func validateBids(
        cardsPerPlayer R: Int,
        dealerPlayerId: UUID,
        bidsByPlayerId: [UUID: Int],
        enforceDealerForbidden: Bool = true
    ) -> BidValidationResult {
        // Require at least one bid entry — an empty dict has no bids to validate
        guard !bidsByPlayerId.isEmpty else {
            return .init(isValid: false, forbiddenDealerBid: nil, message: "No bids have been entered.")
        }

        // Range checks
        for (_, bid) in bidsByPlayerId {
            if bid < 0 || bid > R {
                return .init(isValid: false, forbiddenDealerBid: nil,
                             message: "Bids must be between 0 and \(R).")
            }
        }

        // If the dealer-forbidden rule is not enforced, skip the restriction entirely
        if !enforceDealerForbidden {
            return .init(isValid: true, forbiddenDealerBid: nil, message: nil)
        }

        let nonDealerSum = bidsByPlayerId
            .filter { $0.key != dealerPlayerId }
            .map(\.value)
            .reduce(0, +)

        let forbidden = R - nonDealerSum
        if (0...R).contains(forbidden) {
            if let dealerBid = bidsByPlayerId[dealerPlayerId], dealerBid == forbidden {
                return .init(
                    isValid: false,
                    forbiddenDealerBid: forbidden,
                    message: "Dealer cannot bid \(forbidden) this round."
                )
            } else {
                return .init(
                    isValid: true,
                    forbiddenDealerBid: forbidden,
                    message: "Dealer cannot bid \(forbidden)."
                )
            }
        }

        return .init(isValid: true, forbiddenDealerBid: nil, message: nil)
    }

    static func validateTricks(cardsPerPlayer R: Int, tricksByPlayerId: [UUID: Int]) -> (isValid: Bool, message: String?) {
        for (_, t) in tricksByPlayerId {
            if t < 0 || t > R {
                return (false, "Tricks must be between 0 and \(R).")
            }
        }
        let total = tricksByPlayerId.values.reduce(0, +)
        if total != R {
            return (false, "Total tricks must equal \(R). Currently \(total).")
        }
        return (true, nil)
    }
}

