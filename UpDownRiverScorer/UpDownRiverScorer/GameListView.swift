//
//  GameListView.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import SwiftUI
import SwiftData

struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Game.createdAt, order: .reverse) private var games: [Game]
    @State private var showingNewGame = false
    @State private var showingHowToPlay = false
    @State private var path: [UUID] = []
    @State private var showGameFullScreen = false
    @State private var createdGameForFullScreen: Game? = nil

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(games) { game in
                    NavigationLink(value: game.id) {
                        GameRowView(game: game)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Up/Down River")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewGame = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New game")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHowToPlay = true
                    } label: {
                        Image(systemName: "book")
                    }
                    .accessibilityLabel("How to Play")
                }
            }
            .overlay {
                if games.isEmpty {
                    ContentUnavailableView {
                        Label("No Games", systemImage: "rectangle.stack.badge.plus")
                    } description: {
                        Text("Tap the + to start a new game.")
                    } actions: {
                        Button {
                            showingNewGame = true
                        } label: {
                            Label("New Game", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { gameId in
                if let game = games.first(where: { $0.id == gameId }) {
                    GameDetailView(game: game)
                } else {
                    ContentUnavailableView("Game Not Found", systemImage: "trash", description: Text("This game has been deleted."))
                }
            }
            .navigationDestination(isPresented: $showingHowToPlay) {
                HowToPlayView()
            }
        }
        .sheet(isPresented: $showingNewGame) {
            NewGameView { game in
                createdGameForFullScreen = game
                showGameFullScreen = true
            }
        }
        .fullScreenCover(isPresented: $showGameFullScreen) {
            if let game = createdGameForFullScreen {
                NavigationStack {
                    GameDetailView(game: game, isModal: true)
                }
            } else {
                ContentUnavailableView("Loading Game", systemImage: "hourglass")
            }
        }
    }

    private func delete(offsets: IndexSet) {
        for i in offsets {
            let game = games[i]
            path.removeAll { $0 == game.id }
            modelContext.delete(game)
        }
    }
}

private struct GameRowView: View {
    let game: Game

    var subtitle: String {
        if game.isGameCompleted {
            if let completed = game.gameCompletionDate {
                return "Completed on \(completed.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Completed"
            }
        } else {
            let base = game.createdAt.formatted(date: .abbreviated, time: .shortened)
            return game.startedBackDown ? "\(base) (Back Down)" : base
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game (\(game.playerCount) players)")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if game.isGameCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

