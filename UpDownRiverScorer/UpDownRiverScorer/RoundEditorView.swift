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

    private var R: Int { round.cardsPerPlayer }

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
                                .disabled(entry.bid <= 0)

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
                                .disabled(entry.bid >= R)
                            }
                        } else {
                            HStack(spacing: 12) {
                                Button {
                                    entry.tricks = max(0, entry.tricks - 1)
                                    _ = vm.validateTricks(round: round)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .disabled(entry.tricks <= 0)

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
                                .disabled(entry.tricks >= maxForThisPlayer)
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
                        if bidsOK && (game.dealerForbiddenBidEnabled ? vm.totalBids != R : true) {
                            vm.phase = .tricks
                        }
                    } else {
                        let bidsOK = vm.validateBids(round: round, enforceDealerForbidden: game.dealerForbiddenBidEnabled)
                        let tricksOK = vm.validateTricks(round: round)
                        if bidsOK && tricksOK { dismiss() }
                    }
                }
            }
        }
    }
}

