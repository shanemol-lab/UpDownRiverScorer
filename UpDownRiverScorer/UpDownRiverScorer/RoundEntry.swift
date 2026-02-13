//
//  RoundEntry.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation
import SwiftData

@Model
final class RoundEntry {
    var id: UUID
    var bid: Int
    var tricks: Int

    // Relationship
    var player: Player?

    init(player: Player) {
        self.id = UUID()
        self.player = player
        self.bid = 0
        self.tricks = 0
    }
}
