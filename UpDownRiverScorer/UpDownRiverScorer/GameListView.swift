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

    var body: some View {
        NavigationStack {
            List {
                ForEach(games) { game in
                    NavigationLink {
                        GameDetailView(game: game)
                    } label: {
                        GameRowView(game: game)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if let index = games.firstIndex(where: { $0.id == game.id }) {
                                delete(offsets: IndexSet(integer: index))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
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
                    NavigationLink {
                        HowToPlayView()
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
        }
        .sheet(isPresented: $showingNewGame) {
            NewGameView()
        }
    }

    private func delete(offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(games[i])
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

