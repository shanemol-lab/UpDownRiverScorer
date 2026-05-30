import SwiftUI
import Charts

struct RankProgressionView: View {
    let game: Game

    @State private var filteredPlayer: Player? = nil // State to track filtered player for chart

    struct Point: Identifiable, Hashable {
        let id = UUID()
        let player: Player
        let roundIndex: Int // 0-based
        let rank: Int       // 1 is top
    }

    struct PlayerSeries: Identifiable {
        let id: UUID
        let color: Color
        let points: [Point]
    }

    private var completedRounds: [Round] {
        game.roundsSorted.filter { $0.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) }
    }

    private var dataPoints: [Point] {
        let players = game.orderedPlayers
        var points: [Point] = []

        for (round, totals) in ScoringEngine.cumulativeTotalsPerRound(game: game) {
            // Sort by total desc, assign ranks with ties allowed
            let sorted = players.sorted { totals[$0.id, default: 0] > totals[$1.id, default: 0] }
            var rankByPlayer: [UUID: Int] = [:]
            var currentRank = 0
            var lastScore: Int? = nil
            for (idx, p) in sorted.enumerated() {
                let score = totals[p.id, default: 0]
                if lastScore == score {
                    // same rank as previous
                } else {
                    currentRank = idx + 1
                    lastScore = score
                }
                rankByPlayer[p.id] = currentRank
            }
            for p in players {
                if let r = rankByPlayer[p.id] {
                    points.append(Point(player: p, roundIndex: round.index, rank: r))
                }
            }
        }
        return points
    }

    private var chartSeries: [PlayerSeries] {
        game.orderedPlayers.map { p in
            let seriesPoints = dataPoints
                .filter { $0.player.id == p.id }
                .sorted { $0.roundIndex < $1.roundIndex }
            return PlayerSeries(
                id: p.id,
                color: game.color(for: p),
                points: seriesPoints
            )
        }
        .filter { !$0.points.isEmpty }
    }

    private var maxRank: Int { max(1, game.playerCount) }

    @ChartContentBuilder
    private func seriesMarks(series: PlayerSeries, maxRank: Int) -> some ChartContent {
        ForEach(series.points, id: \.id) { point in
            let xValue = point.roundIndex + 1
            let yValue = maxRank - point.rank + 1

            LineMark(
                x: .value("Round", xValue),
                y: .value("Rank", yValue)
            )
            .symbol(Circle())
        }
        .foregroundStyle(series.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if completedRounds.isEmpty {
                ContentUnavailableView("No completed rounds yet", systemImage: "chart.line.uptrend.xyaxis", description: Text("Finish at least one round to see rank progression."))
            } else {
                // Clear Filter Button always visible, disabled if no filter active
                Button("Clear Filter") {
                    filteredPlayer = nil
                }
                .disabled(filteredPlayer == nil)
                .opacity(filteredPlayer == nil ? 0.5 : 1.0)
                .padding(.bottom, 4)

                // +1 pads the right edge so the last data point isn't flush against the axis
                let xUpperBound = max(1, completedRounds.count)
                Chart {
                    // Filter series by selected player if any
                    ForEach(chartSeries.filter { filteredPlayer == nil || $0.id == filteredPlayer!.id }, id: \.id) { series in
                        seriesMarks(series: series, maxRank: maxRank)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom, values: Array(1...completedRounds.count)) { v in
                        AxisGridLine()
                        AxisTick()
                        if let val = v.as(Int.self) {
                            AxisValueLabel("\(val)")
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: Array(1...maxRank)) { v in
                        AxisGridLine()
                        AxisTick()
                        if let val = v.as(Int.self) {
                            let rank = maxRank - val + 1
                            AxisValueLabel("\(rank)")
                        }
                    }
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) { Text("Rounds") }
                .chartYAxisLabel(position: .leading) { Text("Rank") }
                .chartYScale(domain: 1...maxRank, type: .linear)
                .chartXScale(domain: 1...(xUpperBound + 1))
                .chartLegend(.hidden)
                .frame(minHeight: 280)
                .padding(.top, 4)

                // Combined Legend: shape + color per player, tappable to filter
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
        .padding()
        .navigationTitle("Rank Progression")
    }
}


