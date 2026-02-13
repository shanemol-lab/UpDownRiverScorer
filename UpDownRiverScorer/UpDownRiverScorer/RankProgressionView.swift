import SwiftUI
import Charts

struct RankProgressionView: View {
    let game: Game

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

    private let playerColors: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink, .teal, .brown, .black, .gray
    ]
    
    private func color(for player: Player) -> Color {
        let idx = game.orderedPlayers.firstIndex(where: { $0.id == player.id }) ?? 0
        return playerColors[idx % playerColors.count]
    }

    private var completedRounds: [Round] {
        game.rounds
            .sorted { $0.index < $1.index }
            .filter { round in
                let R = round.cardsPerPlayer
                let tricks = round.entries.map { $0.tricks }
                let sum = tricks.reduce(0, +)
                return tricks.count == game.playerCount && tricks.allSatisfy { $0 >= 0 && $0 <= R } && sum == R
            }
    }

    private var dataPoints: [Point] {
        // For each round up to completed, compute cumulative totals per player, then rank with ties allowed
        let players = game.orderedPlayers
        var totalsByPlayer: [UUID: Int] = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        var points: [Point] = []

        for round in completedRounds { // already sorted
            // update totals
            for entry in round.entries {
                guard let p = entry.player else { continue }
                totalsByPlayer[p.id, default: 0] += Rules.score(bid: entry.bid, tricks: entry.tricks)
            }
            // sort by total desc, ties allowed -> same rank for equal totals
            let sorted = players.sorted { totalsByPlayer[$0.id, default: 0] > totalsByPlayer[$1.id, default: 0] }
            var rankByPlayer: [UUID: Int] = [:]
            var currentRank = 0
            var lastScore: Int? = nil
            for (idx, p) in sorted.enumerated() {
                let score = totalsByPlayer[p.id, default: 0]
                if let ls = lastScore, ls == score {
                    // same rank as previous
                } else {
                    currentRank = idx + 1
                    lastScore = score
                }
                rankByPlayer[p.id] = currentRank
            }
            // emit points for this round index
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
                color: color(for: p),
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
        .foregroundStyle(by: .value("Player", series.id.uuidString))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if completedRounds.isEmpty {
                ContentUnavailableView("No completed rounds yet", systemImage: "chart.line.uptrend.xyaxis", description: Text("Finish at least one round to see rank progression."))
            } else {
                let xUpperBound = max(1, completedRounds.count == 1 ? 2 : completedRounds.count)
                Chart {
                    // One series per player: connect their points across rounds
                    ForEach(chartSeries, id: \.id) { series in
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

                // Combined Legend: shape + color per player
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(game.orderedPlayers, id: \.id) { p in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(color(for: p).opacity(0.2))
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        Circle().stroke(color(for: p), lineWidth: 2)
                                    }
                                Text(p.name).font(.footnote)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.thinMaterial, in: Capsule())
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


