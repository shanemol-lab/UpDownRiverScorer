import SwiftUI
import Charts

struct OverallScoreProgressView: View {
    let game: Game

    @State private var filteredPlayer: Player? = nil

    private var completedRounds: [Round] {
        game.roundsSorted.filter { $0.isValid(enforceDealerForbidden: game.dealerForbiddenBidEnabled) }
    }

    struct Point: Identifiable, Hashable {
        let player: Player
        let roundIndex: Int // 1-based for display
        let total: Int
        var id: String { "\(player.id)-\(roundIndex)" }
    }

    struct PlayerSeries: Identifiable {
        let id: UUID
        let color: Color
        let points: [Point]
    }

    private var chartSeries: [PlayerSeries] {
        let players = game.orderedPlayers
        var seriesForPlayer: [UUID: [Point]] = Dictionary(uniqueKeysWithValues: players.map { ($0.id, []) })

        for (round, totals) in ScoringEngine.cumulativeTotalsPerRound(game: game) {
            for p in players {
                let point = Point(player: p, roundIndex: round.index + 1, total: totals[p.id, default: 0])
                seriesForPlayer[p.id, default: []].append(point)
            }
        }

        return players.map { p in
            PlayerSeries(id: p.id, color: game.color(for: p), points: seriesForPlayer[p.id] ?? [])
        }
        .filter { !$0.points.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if completedRounds.isEmpty {
                ContentUnavailableView("No completed rounds yet", systemImage: "chart.line.uptrend.xyaxis", description: Text("Finish at least one round to see score progress."))
            } else {
                // Clear Filter Button
                Button("Clear Filter") {
                    filteredPlayer = nil
                }
                .disabled(filteredPlayer == nil)
                .opacity(filteredPlayer == nil ? 0.5 : 1.0)
                .padding(.bottom, 4)

                // +1 pads the right edge so the last data point isn't flush against the axis
                let xUpperBound = max(1, completedRounds.count)

                Chart {
                    ForEach(chartSeries.filter { filteredPlayer == nil || $0.id == filteredPlayer!.id }, id: \.id) { series in
                        ForEach(series.points, id: \.id) { point in
                            LineMark(
                                x: .value("Round", point.roundIndex),
                                y: .value("Total", point.total)
                            )
                            .symbol(Circle())
                        }
                        .foregroundStyle(by: .value("Player", series.id.uuidString))
                    }
                }
                .chartForegroundStyleScale(
                    domain: chartSeries.map { $0.id.uuidString },
                    range: chartSeries.map { $0.color }
                )
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
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) { Text("Rounds") }
                .chartYAxisLabel(position: .leading) { Text("Cumulative Score") }
                .chartXScale(domain: 1...(xUpperBound + 1))
                .chartLegend(.hidden)
                .frame(minHeight: 280)
                .padding(.top, 4)

                PlayerFilterLegend(game: game, filteredPlayer: $filteredPlayer)
            }
        }
        .padding()
        .navigationTitle("Overall Score Progress")
    }
}

