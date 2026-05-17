# CLAUDE.md — UpDownRiverScorer (Bugger It Scorer)

## Project Overview

iOS/iPadOS card game scoring app for the "Up/Down River" card game (displayed as "Bugger It Scorer"). Built entirely with native Apple frameworks — no third-party dependencies.

- **Bundle ID**: com.moller.UpDownRiverScorer
- **Min Platform**: iOS 17+ (requires SwiftData and Charts)
- **Language**: Swift + SwiftUI
- **Persistence**: SwiftData (SQLite-backed)
- **~2,300 lines of Swift across 21 files**

---

## Architecture: MVVM + SwiftData

```
Models (SwiftData @Model)  →  ViewModels (@MainActor, @Published)  →  Views (SwiftUI)
```

- **Models** are the single source of truth; they persist automatically via SwiftData.
- **ViewModels** (`NewGameViewModel`, `RoundEditorViewModel`) own transient UI state and validation logic. Always `@MainActor`.
- **Views** bind to models via `@Bindable` and access the context via `@Environment(\.modelContext)`.
- **Business logic is stateless**: `Rules` (enum), `ScoringEngine`, `RoundValidator` — no global state, no singletons.

---

## Data Model Hierarchy

```
Game  (aggregate root)
├── [Player]    cascade-deleted, sorted by sortIndex
└── [Round]     cascade-deleted, indexed sequentially
     ├── dealer → Player?
     └── [RoundEntry]  cascade-deleted, one per player per round
          └── player → Player?
```

All four model types (`Game`, `Player`, `Round`, `RoundEntry`) are `@Model`-decorated SwiftData entities.

---

## Key Files

| File | Responsibility |
|------|---------------|
| `Game.swift` | Aggregate root: round sequences, dealer rotation, scoring, completion |
| `Player.swift` | Minimal model: UUID, name, sortIndex |
| `Round.swift` | One round: card count, dealer ref, cascade RoundEntries |
| `RoundEntry.swift` | Bid and trick count for one player in one round |
| `Rules.swift` | **Stateless enum**: scoring formula, bid validation, trick validation, round sequences |
| `ScoringEngine.swift` | Cumulative score totals across valid rounds |
| `RoundValidator.swift` | User-friendly validation messages wrapping `Rules` |
| `Game+Colors.swift` | Player color assignment extension |
| `Game+Completion.swift` | Game completion status extension |
| `NewGameViewModel.swift` | @MainActor VM: player setup, rule toggles before game creation |
| `RoundEditorViewModel.swift` | @MainActor VM: bid/trick validation UI state during round editing |
| `UpDownRiverScorerApp.swift` | App entry point: `ModelContainer` with schema [Game, Player, Round, RoundEntry] |

---

## Scoring Rules (encoded in `Rules.swift`)

- **Correct bid**: 50 + (10 × tricks)
- **Zero bid made**: 10 points
- **Incorrect bid**: −10 × |bid − actual|
- **Dealer forbidden bid**: Dealer cannot bid the value that would make total bids equal the card count (optional rule)
- **Reserve trump card**: Reduces max cards by 1 (optional rule)

---

## Navigation

```
GameListView (NavigationStack root)
├── GameDetailView          (navigationDestination for UUID)
│   ├── RoundEditorView     (full round editing)
│   ├── RankProgressionView (Charts — player rankings over rounds)
│   └── OverallScoreProgressView (Charts — cumulative scores)
├── HowToPlayView
└── NewGameView             (sheet → full-screen cover on create)
```

- **NavigationStack** with UUID-typed `navigationDestination`.
- **Sheets** for: new game, dealer hint, max hand size config, variant confirmation, bid lock confirmation.
- **Full-screen cover** for newly created games (prevents accidental dismissal).
- **ScrollViewReader** used to anchor scroll position after round navigation.

---

## State Management

| Layer | Mechanism | Used For |
|-------|-----------|----------|
| Persistent | SwiftData `@Model` | All game data |
| View-local | `@State` | UI flow: alert visibility, sheet toggles, nav state |
| ViewModel | `@Published` + `@StateObject` | Validation messages, player setup, bid totals |
| Binding | `Binding(get:set:)` | Computed/derived state passed into child views |

---

## Coding Conventions

- **One public type per file**; private nested types within the file that owns them (e.g., `GameRowView` inside `GameListView.swift`).
- **Extensions in separate files** grouped by concern: `Game+Colors.swift`, `Game+Completion.swift`.
- **Naming**: Models = singular nouns; ViewModels = `*ViewModel`; Views = `*View`; computed properties are descriptive (`isGameCompleted`, `currentRound`, `sortedRounds`).
- **Thread safety**: ViewModels are `@MainActor`; `@Transient` used for non-persistent model properties.
- **Guard statements** for optional unwrapping; `precondition` for defensive invariants in `Rules`.
- **`reduce`** for aggregations; `.sorted(by:)` for stable ordering on collections.
- **No comments by default**; names are self-documenting. Comments only appear where behavior is non-obvious.
- **No third-party libraries** — only SwiftUI, SwiftData, Charts, Foundation, Combine.

---

## Testing

- Tests directory exists (`UpDownRiverScorerTests`, `UpDownRiverScorerUITests`) but contains only stubs.
- Uses Swift's `Testing` framework (not XCTest).
- The stateless `Rules` enum, `ScoringEngine`, and `RoundValidator` are prime candidates for unit tests.
- SwiftUI previews exist in most views for manual verification.

---

## Game Domain Glossary

- **Up/Down River**: Card game where rounds go up (increasing cards) then back down.
- **R**: Number of cards dealt in the current round (max cards for that hand).
- **Bid**: Player's prediction of how many tricks they'll win.
- **Dealer forbidden bid**: Rule preventing dealer from bidding a value that makes total bids = R.
- **Reserve trump card**: Rule that reduces max cards by 1 (one card "reserved" face-up as trump).
- **Early back-down**: Variant that shortens the descending portion of the round sequence.
