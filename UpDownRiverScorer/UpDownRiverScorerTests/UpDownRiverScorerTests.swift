//
//  UpDownRiverScorerTests.swift
//  UpDownRiverScorerTests
//
//  Created by Shane Moller on 02/01/2026.
//

import Testing
@testable import UpDownRiverScorer
import Foundation

struct RulesTests {

    @Test func correctBidScoresCorrectly() {
        #expect(Rules.score(bid: 3, tricks: 3) == 80)
    }

    @Test func correctZeroBidScoresTen() {
        #expect(Rules.score(bid: 0, tricks: 0) == 10)
    }

    @Test func overBidPenalisesCorrectly() {
        #expect(Rules.score(bid: 3, tricks: 1) == -20)
    }

    @Test func underBidPenalisesCorrectly() {
        #expect(Rules.score(bid: 1, tricks: 3) == -20)
    }

    @Test func correctBidOfOneScoresSixty() {
        #expect(Rules.score(bid: 1, tricks: 1) == 60)
    }
}

struct ValidateTricksTests {

    @Test func validTricksPass() {
        let tricks = [UUID(): 1, UUID(): 1, UUID(): 1]
        let result = Rules.validateTricks(cardsPerPlayer: 3, tricksByPlayerId: tricks)
        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test func tricksTotalExceedsRFails() {
        let tricks = [UUID(): 2, UUID(): 2, UUID(): 2]
        let result = Rules.validateTricks(cardsPerPlayer: 3, tricksByPlayerId: tricks)
        #expect(result.isValid == false)
        #expect(result.message == "Total tricks must equal 3. Currently 6.")
    }

    @Test func tricksTotalBelowRFails() {
        let tricks = [UUID(): 1, UUID(): 0, UUID(): 0]
        let result = Rules.validateTricks(cardsPerPlayer: 3, tricksByPlayerId: tricks)
        #expect(result.isValid == false)
        #expect(result.message == "Total tricks must equal 3. Currently 1.")
    }

    @Test func negativeTricksFails() {
        let tricks = [UUID(): -1, UUID(): 2, UUID(): 2]
        let result = Rules.validateTricks(cardsPerPlayer: 3, tricksByPlayerId: tricks)
        #expect(result.isValid == false)
        #expect(result.message == "Tricks must be between 0 and 3.")
    }

    @Test func emptyTricksFails() {
        let result = Rules.validateTricks(cardsPerPlayer: 3, tricksByPlayerId: [:])
        #expect(result.isValid == false)
        #expect(result.message == "No tricks have been entered.")
    }
}

struct RoundSequenceTests {

    @Test func singleCardReturnsOneRound() {
        #expect(Rules.roundSequence(maxCards: 1) == [1])
    }

    @Test func twoCardsSequence() {
        #expect(Rules.roundSequence(maxCards: 2) == [1, 2, 1])
    }

    @Test func threeCardsSequence() {
        #expect(Rules.roundSequence(maxCards: 3) == [1, 2, 3, 2, 1])
    }

    @Test func fiveCardsSequence() {
        #expect(Rules.roundSequence(maxCards: 5) == [1, 2, 3, 4, 5, 4, 3, 2, 1])
    }
}
