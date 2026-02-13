import Foundation

enum RoundValidator {
    // Returns nil when round is valid; otherwise a user-friendly message.
    static func validate(round: Round) -> String? {
        let R = round.cardsPerPlayer
        guard let dealerId = round.dealer?.id else { return "Missing dealer for this round." }

        // Build bids and tricks maps
        var bids: [UUID: Int] = [:]
        var tricks: [UUID: Int] = [:]
        for e in round.entries {
            if let pid = e.player?.id {
                bids[pid] = e.bid
                tricks[pid] = e.tricks
            }
        }

        // Validate bids
        let bidResult = Rules.validateBids(cardsPerPlayer: R, dealerPlayerId: dealerId, bidsByPlayerId: bids, enforceDealerForbidden: true)
        if !bidResult.isValid {
            return bidResult.message ?? "Bids are invalid."
        }

        // Validate tricks
        let trickResult = Rules.validateTricks(cardsPerPlayer: R, tricksByPlayerId: tricks)
        if !trickResult.isValid {
            return trickResult.message ?? "Tricks are invalid."
        }

        return nil // all good
    }
}

