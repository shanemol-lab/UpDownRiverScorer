//
//  NewGameView.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import SwiftUI
import SwiftData

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onGameCreated: (Game) -> Void = { _ in }

    @StateObject private var vm = NewGameViewModel()
    @State private var showDealerInfo = true
    @State private var showMaxHandSizeSheet = false
    @State private var maxHandSizeValue: Int = 1
    @State private var showVariantConfirmation = false
    @State private var pendingStart = false

    private var isDealerBidChanged: Bool { vm.dealerForbiddenBidEnabled == false }
    private var isMaxHandSizeChanged: Bool { vm.maximumHandSizeEnabled == true }

    private var variantMessages: [String] {
        var messages: [String] = []
        if isDealerBidChanged {
            messages.append("Dealer Forbidden Bid: Off")
        }
        if isMaxHandSizeChanged {
            if vm.maximumHandSizeEnabled {
                if let maxHand = vm.maximumHandSize {
                    messages.append("Maximum Hand Size: On (\(maxHand) card\(maxHand == 1 ? "" : "s"))")
                } else {
                    messages.append("Maximum Hand Size: On (Not set)")
                }
            } else {
                messages.append("Maximum Hand Size: Off")
            }
        }
        return messages
    }
    
    private var combinedVariantMessage: String {
        variantMessages.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Count: \(vm.playerCount)", value: Binding(
                        get: { vm.playerCount },
                        set: { vm.setPlayerCount($0) }
                    ), in: 3...8)

                    ForEach(0..<vm.playerCount, id: \.self) { i in
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundStyle(.secondary)
                            TextField("Player \(i + 1)", text: $vm.names[i], prompt: Text("Player \(i + 1)"))
                                .textInputAutocapitalization(.words)
                        }
                    }
                } header: {
                    Text("Players")
                } footer: {
                    Text("Tip: Tap a name to rename players. You can keep the defaults if you prefer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Rules") {
                    Toggle(isOn: $vm.dealerForbiddenBidEnabled) {
                        Text("Dealer Forbidden Bid")
                    }
                    Toggle(isOn: $vm.maximumHandSizeEnabled) {
                        Text("Maximum Hand Size")
                    }
                    if vm.maximumHandSizeEnabled {
                        Button {
                            let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                            if let m = vm.maximumHandSize {
                                maxHandSizeValue = min(max(1, m), allowed)
                            } else {
                                maxHandSizeValue = allowed
                            }
                            showMaxHandSizeSheet = true
                        } label: {
                            HStack {
                                Text("Set Maximum")
                                Spacer()
                                Text(vm.maximumHandSize != nil ? "\(vm.maximumHandSize!) cards" : "Not set")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    NavigationLink {
                        HowToPlayView()
                    } label: {
                        Label("See full rules and variants", systemImage: "book")
                            .font(.body)
                    }
                }
            }
            .navigationTitle("New Game")
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        if !isDealerBidChanged && !isMaxHandSizeChanged {
                            startGame()
                        } else {
                            showVariantConfirmation = true
                            pendingStart = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showDealerInfo) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.crop.square.stack")
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        Text("Choose the First Dealer")
                            .font(.title2).bold()
                    }

                    Text("Before entering player names, decide who will be the first dealer.")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Enter the first dealer as \"Player 1\".")
                        Text("• The player to their left is \"Player 2\" and so on.")
                    }
                    .font(.body)

                    Spacer()

                    Button {
                        showDealerInfo = false
                    } label: {
                        Text("Got it")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMaxHandSizeSheet) {
                NavigationStack {
                    Form {
                        Section("Choose maximum hand size") {
                            let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                            Text("Up to \(allowed) cards based on player count.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Stepper(value: Binding(
                                get: {
                                    let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                                    return min(maxHandSizeValue, allowed)
                                },
                                set: { newVal in
                                    let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                                    maxHandSizeValue = min(max(1, newVal), allowed)
                                }
                            ), in: 1...Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)) {
                                HStack {
                                    Text("Maximum: ")
                                    Spacer()
                                    Text("\(maxHandSizeValue) card(s)")
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                    .navigationTitle("Maximum Hand Size")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showMaxHandSizeSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                                maxHandSizeValue = min(max(1, maxHandSizeValue), allowed)
                                vm.maximumHandSize = maxHandSizeValue
                                showMaxHandSizeSheet = false
                            }
                        }
                    }
                }
                .onAppear {
                    // Initialize the stepper value from the existing selection or default to allowed
                    let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                    if let m = vm.maximumHandSize {
                        maxHandSizeValue = min(max(1, m), allowed)
                    } else {
                        maxHandSizeValue = allowed
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: vm.maximumHandSizeEnabled) { oldValue, enabled in
                if enabled && vm.maximumHandSize == nil {
                    maxHandSizeValue = 1
                    showMaxHandSizeSheet = true
                }
            }
            .onChange(of: vm.playerCount) { oldValue, newValue in
                // If a maximum is selected and becomes invalid due to fewer players, force re-selection
                if vm.maximumHandSizeEnabled {
                    let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
                    if let m = vm.maximumHandSize, m > allowed {
                        // Force user to change the maximum
                        maxHandSizeValue = allowed
                        showMaxHandSizeSheet = true
                    }
                }
            }
            .sheet(isPresented: $showVariantConfirmation) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Confirm Variants")
                        .font(.title2).bold()
                        .padding(.bottom, 4)
                    Text("You have chosen to change the following rule variant(s):")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    ForEach(variantMessages, id: \.self) { msg in
                        Text(msg)
                            .font(.body)
                    }
                    Text("If you are happy with these changes, select Proceed. Otherwise, use Change Selection to adjust your choices.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Spacer(minLength: 20)
                    HStack {
                        Button("Change Selection") {
                            showVariantConfirmation = false
                            pendingStart = false
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Proceed") {
                            showVariantConfirmation = false
                            pendingStart = false
                            startGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func startGame() {
        if vm.maximumHandSizeEnabled {
            let allowed = Rules.maxCards(playerCount: vm.playerCount, reserveTrumpCard: true)
            if let n = vm.maximumHandSize { vm.maximumHandSize = min(max(1, n), allowed) }
        }
        let game = vm.createGame(modelContext: modelContext)
        ensureCurrentRoundExists(game: game, modelContext: modelContext)
        dismiss()
        onGameCreated(game)
    }

    private func ensureCurrentRoundExists(game: Game, modelContext: ModelContext) {
        if game.rounds.isEmpty {
            let idx = 0
            let dealer = game.dealer(forRoundIndex: idx)
            let R = game.cardsPerPlayer(forRoundIndex: idx)
            let round = Round(index: idx, cardsPerPlayer: R, dealer: dealer, players: game.players)
            game.rounds.append(round)
            modelContext.insert(round)
        }
    }
}

