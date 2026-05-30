import SwiftUI

extension Game {
    var playerColorPalette: [Color] {
        [.red, .blue, .green, .orange, .purple, .pink, .teal, .brown, .indigo, .mint]
    }

    func color(for player: Player) -> Color {
        let players = orderedPlayers
        let idx = players.firstIndex { $0.id == player.id } ?? 0
        return playerColorPalette[idx % playerColorPalette.count]
    }
}
