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

    private var currentRound: Round? {
        game.rounds.sorted(by: { $0.index < $1.index }).last
    }
    
    private var sortedRounds: [Round] {
        game.rounds.sorted { $0.index < $1.index }
    }

    private func validate(round: Round) -> String? {
        return RoundValidator.validate(round: round)
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
                    if round.isValid {
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
                }
                .id("top")

                // Custom Header for Rounds Section with Next Round button beside the title
                Section {
                    // The rounds list rows
                    ForEach(sortedRounds) { round in
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
                                        // Scroll to the new round first, then navigate
                                        DispatchQueue.main.async {
                                            proxy.scrollTo(newRound.id, anchor: .center)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                navigateToRound = newRound
                                            }
                                        }
                                    }
                                }
                            }
                            .disabled(game.isGameCompleted || currentRoundCompletionMessage() != nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.bottom, 4) // spacing below header for clarity
                }

                if let round = currentRound {
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
                    // Begin the downward sequence early
                    game.startedBackDown = true
                    // Add the next round which should be one fewer card than the current
                    if let newRound = addNextRound() {
                        // Navigate to the new round
                        navigateToRound = newRound
                    }
                }
                .disabled(!game.isCurrentlyHeadingUp)
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                // Ensure we scroll to the very top after the list lays out so the title is visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .onAppear {
                if game.showFirstVisitHint {
                    game.showFirstVisitHint = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showFirstVisitHint = true
                    }
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
        let nextIndex = (game.rounds.map(\.index).max() ?? -1) + 1
        guard nextIndex < game.totalRounds else { return nil }

        let dealer = game.dealer(forRoundIndex: nextIndex)
        let R = game.cardsPerPlayer(forRoundIndex: nextIndex)
        let round = Round(index: nextIndex, cardsPerPlayer: R, dealer: dealer, players: game.players)

        game.rounds.append(round)
        modelContext.insert(round)
        return round
    }
    
    private func currentRoundCompletionMessage() -> String? {
        guard let round = currentRound else { return nil }
        let R = round.cardsPerPlayer
        guard let dealerId = round.dealer?.id else { return "Missing dealer for this round." }

        // Build bids and tricks maps
        var bids: [UUID: Int] = [:]
        var tricks: [UUID: Int] = [:]
        for e in round.entries {
            if let pid = e.player?.id {
                bids[pid] = e.bid
                tricks[pid] = e.tricks
            }
        }

        // Validate bids
        let bidResult = Rules.validateBids(cardsPerPlayer: R, dealerPlayerId: dealerId, bidsByPlayerId: bids, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
        if !bidResult.isValid {
            return bidResult.message ?? "Bids are invalid."
        }

        // Validate tricks
        let trickResult = Rules.validateTricks(cardsPerPlayer: R, tricksByPlayerId: tricks)
        if !trickResult.isValid {
            return trickResult.message ?? "Tricks are invalid."
        }

        return nil // all good
    }
}

