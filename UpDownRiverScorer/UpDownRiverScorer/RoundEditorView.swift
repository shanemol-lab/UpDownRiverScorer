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
    @State private var dontShowBidLockAgain = false
    @State private var bidsLocked = false

    private var R: Int { round.cardsPerPlayer }
    
    // Computed property to detect if the round is complete (all tricks allocated and round marked as done)
    private var isRoundComplete: Bool { round.isValid }

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

            Picker("Phase", selection: $vm.phase) {
                ForEach(RoundEditorViewModel.Phase.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)

            Section(vm.phase == .bids ? "Bids" : "Tricks") {
                ForEach(sortedEntries) { entry in
                    HStack {
                        let isDealer = entry.player?.id == round.dealer?.id
                        Text("\(entry.player?.name ?? "Player")\(isDealer ? " (Dealer)" : "")")
                        Spacer()
                        if vm.phase == .bids {
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
                            // Disable editing tricks if round is complete
                            HStack(spacing: 12) {
                                Button {
                                    entry.tricks = max(0, entry.tricks - 1)
                                    _ = vm.validateTricks(round: round)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(entry.tricks <= 0 || isRoundComplete)

                                Text("\(entry.tricks)")
                                    .monospacedDigit()
                                    .frame(minWidth: 36, alignment: .center)

                                // Prevent total tricks exceeding R by capping based on other players' current tricks
                                let usedTotal = round.entries.reduce(0) { $0 + $1.tricks }
                                let otherUsed = usedTotal - entry.tricks
                                let maxForThisPlayer = max(0, R - otherUsed)

                                Button {
                                    entry.tricks = min(maxForThisPlayer, entry.tricks + 1)
                                    _ = vm.validateTricks(round: round)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(entry.tricks >= maxForThisPlayer || isRoundComplete)
                            }
                        }
                    }
                }
                if vm.phase == .bids {
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
                if vm.phase == .bids, vm.totalBids == R, let msg = vm.bidMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // (Removed invalid out-of-scope entry block)

            if vm.phase == .tricks {
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
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    // If the round is already complete, immediately dismiss without showing bid lock confirmation
                    if round.isValid {
                        dismiss()
                        return
                    }
                    // Enforce correctness before leaving
                    if vm.phase == .bids {
                        // Validate current bids
                        let bidsOK = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                        // Enforce dealer rule: total bids cannot equal total cards for the round
                        if game.dealerForbiddenBidEnabled {
                            if vm.totalBids == R {
                                let dealerId = round.dealer?.id
                                let nonDealerSum = round.entries.filter { $0.player?.id != dealerId }.reduce(0) { $0 + $1.bid }
                                let forbidden = R - nonDealerSum
                                if let dealerBid = round.entries.first(where: { $0.player?.id == dealerId })?.bid {
                                    vm.bidMessage = "Total bids equal total cards (\(R)). Dealer cannot bid \(forbidden). Dealer currently bid \(dealerBid). Adjust bids before continuing."
                                } else {
                                    vm.bidMessage = "Total bids equal total cards (\(R)). Dealer cannot bid \(forbidden). Adjust bids before continuing."
                                }
                            }
                        }
                        // New logic: If bids not locked and no suppression of confirmation, prompt user
                        if bidsOK && (game.dealerForbiddenBidEnabled ? vm.totalBids != R : true) {
                            if !bidsLocked && !dontShowBidLockAgain {
                                // Show sheet instead of confirmationDialog for bid lock confirmation
                                showBidLockConfirmation = true
                                // Do not advance phase yet
                                return
                            } else {
                                // Either already locked or user chose don't show again: lock bids and advance
                                bidsLocked = true
                                vm.phase = .tricks
                            }
                        }
                    } else {
                        let bidsOK = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                        let tricksOK = vm.validateTricks(round: round)
                        if bidsOK && tricksOK {
                            dismiss()
                        } else if !tricksOK {
                            showTricksIncompleteAlert = true
                        }
                    }
                }
            }
        }
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
                Toggle("Don't show again during this game", isOn: $dontShowBidLockAgain)
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
                        vm.phase = .tricks
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

