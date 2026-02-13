import Foundation
import SwiftData

extension Game {
    // Forwarders to the canonical properties defined in Game.swift
    var isCompleted: Bool { isGameCompleted }
    var completionDate: Date? { gameCompletionDate }
}
