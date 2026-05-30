//
//  RoundEditorView.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import SwiftUI
import SwiftData

struct RoundEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var game: Game
    @Bindable var round: Round

    @StateObject private var vm = RoundEditorViewModel()
    @State private var showTricksIncompleteAlert = false

    // New state variables for bid locking confirmation and state
    @State private var showBidLockConfirmation = false
    @State private var bidsLocked = false

    // New state variable for tricks locking state
    @State private var tricksLocked = false

    @State private var phase: RoundEditorViewModel.Phase = .bids

    private var R: Int { round.cardsPerPlayer }
    
    // Computed property to detect if the round is complete (all tricks allocated and round marked as done)
    private var isRoundComplete: Bool { round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) }
    
    // Added computed property per instructions
    private var isActiveRound: Bool { game.roundsSorted.last?.id == round.id }
    
    // Updated computed property per instructions
    private var isTrickEditingLocked: Bool { isActiveRound ? tricksLocked : true }

    /// Derived from already-published vm.bidMessage — avoids calling validateBids (which has
    /// side effects) inside a view modifier during layout.
    private var isBidsDoneButtonDisabled: Bool {
        bidsLocked || isRoundComplete || vm.bidMessage != nil
    }

    private var sortedEntries: [RoundEntry] {
        round.entries.sorted { ($0.player?.sortIndex ?? 0) < ($1.player?.sortIndex ?? 0) }
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Round") { Text("\(round.index + 1)") }
                LabeledContent("Cards") { Text("\(R)") }
                LabeledContent("Dealer") { Text(round.dealer?.name ?? "—") }
            }

            Picker("Phase", selection: $phase) {
                ForEach(RoundEditorViewModel.Phase.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)

            // MARK: - Custom header with phase title and Done button above player list
            HStack {
                Text(phase == .bids ? "Bids" : "Tricks")
                    .font(.headline)
                    .padding(.leading, vm.titleLeadingPadding)
                Spacer()
                Button("Done") {
                    // Same logic as toolbar Done button
                    if round.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) {
                        dismiss()
                        return
                    }
                    if phase == .bids {
                        let bidsOK = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                        if bidsOK {
                            if !bidsLocked && !game.suppressBidLockConfirmation {
                                showBidLockConfirmation = true
                                return
                            } else {
                                bidsLocked = true
                                phase = .tricks
                            }
                        }
                    } else {
                        let bidsOK = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                        let tricksOK = vm.validateTricks(round: round)
                        if bidsOK && tricksOK {
                            tricksLocked = true
                            dismiss()
                        } else if !tricksOK {
                            showTricksIncompleteAlert = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.trailing, vm.doneTrailingPadding)
                .disabled(phase == .bids && isBidsDoneButtonDisabled)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            Section {
                ForEach(sortedEntries) { entry in
                    HStack {
                        let isDealer = entry.player?.id == round.dealer?.id
                        Text("\(entry.player?.name ?? "Player")\(isDealer ? " (Dealer)" : "")")
                        Spacer()
                        if phase == .bids {
                            // Disable editing bids if round is complete or bids are locked
                            HStack(spacing: 12) {
                                Button {
                                    entry.bid = max(0, entry.bid - 1)
                                    vm.updateTotalBids(from: round)
                                    _ = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(entry.bid <= 0 || bidsLocked || isRoundComplete)

                                Text("\(entry.bid)")
                                    .monospacedDigit()
                                    .frame(minWidth: 36, alignment: .center)

                                Button {
                                    entry.bid = min(R, entry.bid + 1)
                                    vm.updateTotalBids(from: round)
                                    _ = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(entry.bid >= R || bidsLocked || isRoundComplete)
                            }
                        } else {
                            // Updated trick editing HStack per instructions: only disable minus if tricks <= 0 or tricksLocked
                            HStack(spacing: 12) {
                                Button {
                                    entry.tricks = max(0, entry.tricks - 1)
                                    _ = vm.validateTricks(round: round)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(entry.tricks <= 0 || isTrickEditingLocked)

                                Text("\(entry.tricks)")
                                    .monospacedDigit()
                                    .frame(minWidth: 36, alignment: .center)

                                let otherAllocated = round.entries.filter { $0.id != entry.id }.reduce(0) { $0 + $1.tricks }
                                let canIncrement = entry.tricks < R && (otherAllocated + entry.tricks) < R && !tricksLocked

                                Button {
                                    if canIncrement {
                                        entry.tricks += 1
                                        _ = vm.validateTricks(round: round)
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canIncrement || isTrickEditingLocked)
                            }
                        }
                    }
                }
                if phase == .bids {
                    HStack {
                        Text("Total Bids Made")
                            .font(.subheadline)
                        Spacer()
                        Text("\(vm.totalBids)")
                            .font(.subheadline)
                            .bold()
                            .monospacedDigit()
                    }
                    .accessibilityLabel("Total bids made")
                }
                if phase == .bids, vm.totalBids == R, let msg = vm.bidMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if phase == .tricks {
                Section("Tricks remaining") {
                    let used = round.entries.reduce(0) { $0 + $1.tricks }
                    Text("\(max(0, R - used))")
                        .monospacedDigit()
                }

                if let msg = vm.trickMessage {
                    Section {
                        Text(msg).foregroundStyle(.secondary)
                    }
                }

                Section("Round scores") {
                    ForEach(sortedEntries) { entry in
                        let s = Rules.score(bid: entry.bid, tricks: entry.tricks)
                        HStack {
                            Text(entry.player?.name ?? "Player")
                            Spacer()
                            Text("\(s)")
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Round \(round.index + 1)")
        .onAppear {
            _ = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
            _ = vm.validateTricks(round: round)
            vm.updateTotalBids(from: round)
            if isRoundComplete {
                phase = .tricks
                bidsLocked = true
            } else {
                phase = .bids
            }
        }
        // Removed toolbar Done button as per instructions
        // MARK: - Sheet for bid lock confirmation (replacing confirmationDialog)
        .sheet(isPresented: $showBidLockConfirmation) {
            VStack(spacing: 20) {
                Text("Lock in Bids?")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                Text("Bids cannot be changed after proceeding. Are you sure you want to lock in these bids?")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                // Toggle for suppressing dialog in current game session
                Toggle("Don't show again during this game", isOn: Binding(
                    get: { game.suppressBidLockConfirmation },
                    set: { game.suppressBidLockConfirmation = $0 }
                ))
                .toggleStyle(SwitchToggleStyle())
                .padding(.horizontal)

                HStack {
                    Button("Change Bids") {
                        // Dismiss sheet to allow edits
                        showBidLockConfirmation = false
                    }
                    Spacer()
                    Button("Proceed") {
                        // Lock bids and advance to tricks phase, then dismiss sheet
                        bidsLocked = true
                        phase = .tricks
                        showBidLockConfirmation = false
                    }
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            // Ensure the sheet content adapts nicely on all device sizes
            .presentationDetents([.fraction(0.35)])
        }
        .alert("Incomplete Tricks Allocation", isPresented: $showTricksIncompleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All tricks must be allocated before the round can be completed. Adjust the trick values so the total matches the required tricks for this round.")
        }
    }
}

