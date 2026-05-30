//
//  GameDetailView.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var game: Game
    var isModal: Bool = false
    
    @State private var showRoundIncompleteAlert = false
    @State private var roundIncompleteMessage: String = ""
    @State private var navigateToRound: Round?
    @State private var showEndGameOptions = false
    @State private var showFirstVisitHint = false

    private var totals: [(Player, Int)] {
        let t = ScoringEngine.totals(game: game)
        let playerTotals = game.players.map { ($0, t[$0.id, default: 0]) }
        let sortedPlayerTotals = playerTotals.sorted { $0.1 > $1.1 }
        return sortedPlayerTotals
    }

    private var currentRound: Round? { game.roundsSorted.last }

    private func validate(round: Round) -> String? {
        return RoundValidator.validate(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
    }
    
    private struct PlayerTotalRow: View {
        let player: Player
        let total: Int
        var body: some View {
            HStack {
                Text(player.name)
                Spacer()
                Text("\(total)").monospacedDigit()
            }
        }
    }
    
    private struct RoundRow: View {
        let game: Game
        let round: Round
        var body: some View {
            ZStack {
                NavigationLink {
                    RoundEditorView(game: game, round: round)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Round \(round.index + 1) — \(round.cardsPerPlayer) card(s)")
                        if let dealer = round.dealer?.name {
                            Text("Dealer: \(dealer)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                // Overlay a completed checkmark icon at trailing if the round is valid (completed)
                // Similar to the completed game tag style
                HStack {
                    Spacer()
                    if round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(.trailing, 18) // padding to align nicely with NavigationLink chevron
                .allowsHitTesting(false) // prevent blocking tap area of NavigationLink
            }
            .id(round.id)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section("Totals") {
                    if game.isGameCompleted {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Game completed")
                                    .font(.subheadline).bold()
                                if let d = game.gameCompletionDate {
                                    Text(d.formatted(date: .abbreviated, time: .shortened))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if game.startedBackDown && !game.isGameCompleted {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(.secondary)
                            Text("Back Down started")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Back down started")
                    }
                    ForEach(totals, id: \.0.id) { tuple in
                        PlayerTotalRow(player: tuple.0, total: tuple.1)
                    }
                    HStack {
                        Spacer()
                        NavigationLink {
                            RankProgressionView(game: game)
                        } label: {
                            Label("View Rank Progression", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.top, 6)
                    HStack {
                        Spacer()
                        NavigationLink {
                            OverallScoreProgressView(game: game)
                        } label: {
                            Label("View Overall Score Progress", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .id("top")

                // Custom Header for Rounds Section with Next Round button beside the title
                Section {
                    // The rounds list rows
                    ForEach(game.roundsSorted) { round in
                        RoundRow(game: game, round: round)
                    }
                    
                    if !game.isGameCompleted {
                        Button("End Game Early") {
                            showEndGameOptions = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                } header: {
                    // Header is a horizontal stack containing the section title and the Next Round button beside it
                    HStack {
                        Text("Rounds")
                            .font(.headline)
                        Spacer()
                        if !game.isGameCompleted {
                            Button("Next Round") {
                                if game.isGameCompleted { return }
                                if let msg = currentRoundCompletionMessage() {
                                    roundIncompleteMessage = msg
                                    showRoundIncompleteAlert = true
                                } else {
                                    if let newRound = addNextRound() {
                                        navigateToRound = newRound
                                    }
                                }
                            }
                            .disabled(game.isGameCompleted || currentRoundCompletionMessage() != nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.bottom, 4) // spacing below header for clarity
                }

                if let round = currentRound, !round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) {
                    Section {
                        NavigationLink {
                            RoundEditorView(game: game, round: round)
                        } label: {
                            Text("Continue current round")
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("Game")
            .toolbar {
                if isModal {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .accessibilityLabel("Back")
                    }
                }
            }
            // REMOVED the ToolbarItem placing "Next Round" button in the navigation bar
            .alert("Complete current round first", isPresented: $showRoundIncompleteAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(roundIncompleteMessage)
            }
            .confirmationDialog("End Game Early", isPresented: $showEndGameOptions) {
                Button("End game immediately", role: .destructive) {
                    game.manualCompletionDate = Date()
                    dismiss()
                }
                Button("Start back down") {
                    guard !game.startedBackDown else { return }
                    // Record the stable pivot before setting the flag so cardsPerPlayer
                    // has a fixed reference point that won't shift as rounds are appended.
                    if let last = game.roundsSorted.last {
                        game.backDownPivotIndex = last.index
                        game.backDownPivotCards = last.cardsPerPlayer
                    }
                    game.startedBackDown = true
                    if let newRound = addNextRound() {
                        navigateToRound = newRound
                    }
                }
                .disabled(!game.isCurrentlyHeadingUp)
                Button("Cancel", role: .cancel) {}
            }
            .task {
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo("top", anchor: .top)
                }
                if game.showFirstVisitHint {
                    game.showFirstVisitHint = false
                    try? await Task.sleep(for: .milliseconds(150))
                    showFirstVisitHint = true
                }
            }
            .alert("Welcome", isPresented: $showFirstVisitHint) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Tap Round 1 to begin the first round.")
            }
            // Removed .navigationDestination(for: Round.self) {...}
            .navigationDestination(item: $navigateToRound) { round in
                RoundEditorView(game: game, round: round)
            }
        }
    }

    @discardableResult private func addNextRound() -> Round? {
        let nextIndex = (game.roundsSorted.last?.index ?? -1) + 1
        guard nextIndex < game.totalRounds else { return nil }
        guard !game.rounds.contains(where: { $0.index == nextIndex }) else { return nil }

        let dealer = game.dealer(forRoundIndex: nextIndex)
        let R = game.cardsPerPlayer(forRoundIndex: nextIndex)
        let round = Round(index: nextIndex, cardsPerPlayer: R, dealer: dealer, players: game.orderedPlayers)

        game.rounds.append(round)
        modelContext.insert(round)
        round.entries.forEach { modelContext.insert($0) }
        return round
    }
    
    private func currentRoundCompletionMessage() -> String? {
        guard let round = currentRound else { return nil }
        return RoundValidator.validate(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
    }
}

