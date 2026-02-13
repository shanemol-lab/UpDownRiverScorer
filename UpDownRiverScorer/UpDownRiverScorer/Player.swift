//
//  Player.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var sortIndex: Int

    init(name: String, sortIndex: Int) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
    }
}
