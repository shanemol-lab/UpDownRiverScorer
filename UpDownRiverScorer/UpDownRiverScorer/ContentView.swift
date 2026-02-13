import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        GameListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Game.self, Player.self, Round.self], inMemory: true)
}
