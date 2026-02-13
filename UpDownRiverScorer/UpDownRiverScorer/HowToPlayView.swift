import SwiftUI

struct HowToPlayView: View {
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Table of Contents
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Table of Contents")
                            .font(.headline)
                            .padding(.bottom, 4)
                        Group {
                            Button("Game Overview") {
                                withAnimation {
                                    proxy.scrollTo("GameOverview", anchor: .top)
                                }
                            }
                            Button("What Happens Each Round") {
                                withAnimation {
                                    proxy.scrollTo("WhatHappensEachRound", anchor: .top)
                                }
                            }
                            Button("Bidding Rules") {
                                withAnimation {
                                    proxy.scrollTo("BiddingRules", anchor: .top)
                                }
                            }
                            Button("Trick Play Rules") {
                                withAnimation {
                                    proxy.scrollTo("TrickPlayRules", anchor: .top)
                                }
                            }
                            Button("Scoring") {
                                withAnimation {
                                    proxy.scrollTo("Scoring", anchor: .top)
                                }
                            }
                            Button("Missed Bids") {
                                withAnimation {
                                    proxy.scrollTo("MissedBids", anchor: .top)
                                }
                            }
                            Button("Configurable Variants") {
                                withAnimation {
                                    proxy.scrollTo("ConfigurableVariants", anchor: .top)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.callout)
                    }
                    .padding(.vertical, 8)

                    Image(systemName: "book.pages")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                        .padding(.top, 8)

                    Text("How to Play Up/Down River")
                        .font(.largeTitle).bold()

                    SectionBlock(title: "Game Overview") {
                        Text("Up / Down the River is a trick-taking card game where players bid how many tricks they expect to win each round. Rounds increase in size, then decrease, giving the game its name.")
                        Text("The objective is to accurately predict how many tricks you will take, not necessarily to take the most tricks.")
                    }
                    .id("GameOverview")

                    Divider()

                    SectionBlock(title: "Players") {
                        Bullet("3–8 players (best with 4–6)")
                        Bullet("Individual play (no teams)")
                    }

                    Divider()

                    SectionBlock(title: "Cards") {
                        Bullet("Standard 52-card deck")
                        Bullet("Ace is high")
                        Bullet("No Jokers, no special bowers")
                    }

                    Divider()

                    SectionBlock(title: "Round Structure (\"Up the River, Down the River\")") {
                        Numbered(text: "The game starts with 1 card per player.", number: 1)
                        Numbered(text: "Each round increases by one card until a maximum is reached.", number: 2)
                        Numbered(text: "Rounds then decrease back down to 1 card per player.", number: 3)

                        Example("maximum 7 cards", content: "1 → 2 → 3 → 4 → 5 → 6 → 7 → 6 → 5 → 4 → 3 → 2 → 1")
                    }

                    Divider()

                    SectionBlock(title: "What happens each round") {
                        Subsection(title: "Dealing") {
                            Bullet("The Dealer deals cards clockwise, starting with the player to their left.")
                            Bullet("Each player receives the same number of cards for that round.")
                        }

                        Subsection(title: "Trump") {
                            Bullet("After all hands are dealt, the next undealt card is turned face up.")
                            Bullet("The suit of this card is trump for the round.")
                        }

                        Subsection(title: "Bidding") {
                            Bullet("Starting with the player to the left of the Dealer, each player bids how many tricks they expect to win.")
                            Bullet("Bidding goes clockwise, once around the table.")
                            Bullet("The Dealer bids last (see Dealer Restriction below).")
                        }

                        Subsection(title: "Playing Tricks") {
                            Bullet("Starting with the player to the left of the Dealer, players play tricks.")
                            Bullet("Each trick is played clockwise.")
                            Bullet("The winner of a trick leads the next trick.")
                        }

                        Subsection(title: "Scoring") {
                            Bullet("Scores are calculated at the end of the round.")
                        }
                    }
                    .id("WhatHappensEachRound")

                    Divider()

                    SectionBlock(title: "Bidding Rules") {
                        Bullet("A bid is the number of tricks a player expects to win in that round.")
                        Bullet("Zero (0) bids are allowed.")
                        Bullet("There is no upper limit on bids.")
                        Bullet("Each player bids once per round.")
                        Bullet("The Dealer always bids last.")

                        Example("", content: "If a round has 4 tricks available. A player may legally bid 0, 1, 2, 3, or 4. The bid represents intent, not a capped value.")
                    }
                    .id("BiddingRules")

                    Divider()

                    SectionBlock(title: "Dealer Restriction (default: ON)") {
                        Bullet("The Dealer may not bid a number that would cause the total of all bids to equal the number of tricks available.")
                        Bullet("This ensures that at least one player will miss their bid each round.")

                        Example("", content: "A round has 4 tricks available. All players except the Dealer have bid a total of 3 tricks. The Dealer cannot bid 1, but may bid 0, 2, or any higher number.")
                    }

                    Divider()

                    SectionBlock(title: "Trick Play Rules") {
                        Bullet("Players must follow suit if they can. If a Spade is led and you have a Spade, you must play a Spade.")
                        Bullet("If you cannot follow suit, you may play any card.")
                        Bullet("Trump beats all non-trump suits.")
                        Bullet("The highest card of the led suit (or trump, if played) wins the trick.")
                        Bullet("The trick winner leads the next trick.")
                    }
                    .id("TrickPlayRules")

                    Divider()

                    SectionBlock(title: "Scoring") {
                        Bullet("Bid 0 and take 0 tricks: +10 points (no 50-point bonus)")
                        Bullet("Bid 1 or more and make it exactly: +50 point bonus plus 10 points per trick taken")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example:")
                                .bold()
                            Bullet("Bid 0, take 0 → 10 points")
                            Bullet("Bid 1, take 1 → 60 points")
                            Bullet("Bid 3, take 3 → 80 points")
                            Text("The 50-point bonus only applies when one or more tricks are bid and made.")
                        }
                        .padding(.leading, 4)
                    }
                    .id("Scoring")

                    Divider()

                    SectionBlock(title: "Missed Bids") {
                        Bullet("–10 points for each trick over or under the bid.")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example:")
                                .bold()
                            Bullet("Bid 3, take 1 → –20 points")
                            Bullet("Bid 3, take 4 → –10 points")
                            Text("There is no base score and no partial credit.")
                        }
                        .padding(.leading, 4)
                    }
                    .id("MissedBids")

                    Divider()

                    SectionBlock(title: "End of the Game") {
                        Bullet("The game ends after the final 1-card round.")
                        Bullet("The player with the highest total score wins.")
                    }

                    Divider()

                    SectionBlock(title: "Configurable Variants (set at game start)") {
                        Subsection(title: "Dealer Forbidden Bid") {
                            Bullet("On (default) or Off.")
                            Bullet("When on, the Dealer may not bid a number that makes total bids equal available tricks.")
                        }

                        Subsection(title: "Maximum Hand Size") {
                            Bullet("Fixed maximum: hands increase from 1 card up to the chosen maximum, then decrease back to 1.")
                            Bullet("Based on player count (default): Maximum hand size = 51 ÷ number of players). One card is always reserved to determine trump.")

                            Example("", content: "With 4 players: 51 ÷ 4 = 12.75, so the maximum hand size is 12 cards.")
                        }
                    }
                    .id("ConfigurableVariants")

                    Text("All variants are chosen when starting a new game and cannot be changed once the game has begun.")
                        .font(.footnote)
                        .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("How to Play")
        }
    }
}

// MARK: - Reusable Views

struct Bullet: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct Numbered: View {
    let text: String
    let number: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .frame(width: 24, alignment: .trailing)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct Example: View {
    let title: String
    let content: String

    init(_ title: String = "", content: String) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.isEmpty ? "Example:" : "Example: \(title)")
                .bold()
            Text(content)
        }
        .padding(.leading, 4)
    }
}

struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()
            content
        }
    }
}

struct Subsection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .bold()
            content
        }
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack { HowToPlayView() }
}

