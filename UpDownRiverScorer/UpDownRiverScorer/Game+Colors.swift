import SwiftUI

extension Game {
    static let playerColorPalette: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .brown, .indigo, .mint]

    func color(for player: Player) -> Color {
        let players = orderedPlayers
        let idx = players.firstIndex { $0.id == player.id } ?? 0
        return Self.playerColorPalette[idx % Self.playerColorPalette.count]
    }
}
