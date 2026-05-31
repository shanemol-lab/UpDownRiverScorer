import SwiftUI

struct PlayerFilterLegend: View {
    let game: Game
    @Binding var filteredPlayer: Player?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(game.orderedPlayers, id: \.id) { p in
                    let isSelected = filteredPlayer?.id == p.id
                    HStack(spacing: 8) {
                        Circle()
                            .fill(game.color(for: p).opacity(isSelected ? 0.5 : 0.2))
                            .frame(width: 18, height: 18)
                            .overlay {
                                Circle().stroke(game.color(for: p), lineWidth: 2)
                            }
                        Text(p.name)
                            .font(.footnote)
                            .fontWeight(isSelected ? .bold : .regular)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(isSelected ? game.color(for: p).opacity(0.2) : Color(.systemBackground).opacity(0.7))
                    .clipShape(Capsule())
                    .onTapGesture {
                        filteredPlayer = isSelected ? nil : p
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
