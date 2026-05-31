# CLAUDE.md — UpDownRiverScorer (Bugger It Scorer)

---

## PROJECT CONTEXT

- **Stack:** Swift / SwiftUI / SwiftData / Charts — iOS 17+, no third-party dependencies
- **Entry point:** UpDownRiverScorerApp.swift (ModelContainer schema: Game, Player, Round, RoundEntry)
- **Test command:** Cmd+U in Xcode (Swift Testing framework, not XCTest — test targets: UpDownRiverScorerTests, UpDownRiverScorerUITests)
- **Key conventions:** MVVM; one public type per file; extensions in separate files (e.g. Game+Colors.swift); ViewModels are @MainActor ObservableObject; models use @Transient for non-persistent computed properties; guard for optionals, precondition for invariants; no comments unless behaviour is non-obvious; all business logic is stateless (Rules enum, ScoringEngine, RoundValidator — no singletons)
- **Do not modify:** Rules.swift scoring constants (50 + 10×tricks for correct bid, 10 for correct zero bid, −10×diff for incorrect) — these encode the agreed house rules
- **CI/CD:** None configured — local Xcode builds only

---

## THE CORE LOOP
Claude MUST follow this loop at all times and MUST NOT skip steps.

### 1. Plan
- Clarify intent before doing anything
- Propose the smallest useful next step
- Prefer vertical slices over phases
- Produce a concise, numbered plan with a concrete verification step
- **Do NOT implement unless explicitly told to**
- **HARD STOP after presenting a plan** — end the message after the plan. Do not implement in the same message. Wait for the user to reply before proceeding. A "Shall I proceed?" question does not substitute for stopping.
- Bash commands that do not create, update, or delete are always allowed in plan phase
- If a plan exceeds ~5 steps, pause and re-scope

### 2. Review
- Wait for explicit approval before implementing
- **The user's reply approving the plan is the ONLY trigger to move to Execute. Do not bundle plan + execution in a single message under any circumstances.**
- Accept scope corrections without resistance
- Bash commands that do not create, update, or delete are always allowed in review phase

### 3. Execute
- Run real commands, write real files
- Prefer deterministic behaviour over cleverness
- Bash commands that do not create, update, or delete are always allowed in execute phase

### 4. Verify
- Prove the change worked (commands, outputs, tests)
- Surface failures explicitly
- Create document: `TEST-RESULTS-[step]-[description]`
- Bash commands that do not create, update, or delete are always allowed in verify phase

> Plans are disposable. Working code is not.

---

## WORKFLOW ORCHESTRATION

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep the main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for the relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behaviour between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

---

## TASK MANAGEMENT

1. **Plan First** — Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan** — Check in before starting implementation
3. **Track Progress** — Mark items complete as you go
4. **Explain Changes** — High-level summary at each step
5. **Document Results** — Add review section to `tasks/todo.md`
6. **Capture Lessons** — Update `tasks/lessons.md` after any corrections

---

## SCOPE DISCIPLINE (Critical)

Claude MUST:
- Default to the smallest possible working change
- Avoid speculative features
- Avoid multi-phase execution without earning it
- Ask before expanding scope

If a plan exceeds ~5 steps, Claude should **pause and re-scope**.

---

## CODE DISCIPLINE (Critical)

- Never hardcode values — always use variables
- Change only what's necessary; don't touch unrelated code or comments
- Don't "improve" things that aren't broken
- Minimise side effects and churn
- Prefer 100 lines over 1000
- Clean up dead code and cruft
- Ask: "Is there a simpler way?"

---

## CORE PRINCIPLES

- **Simplicity First** — Make every change as simple as possible. Impact minimal code. Nothing speculative.
- **No Laziness** — Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact** — Changes should only touch what's necessary. Avoid introducing bugs.
- **Surgical Edits Only** — Don't touch unrelated code, comments, or structure.
- **Goal-Driven** — Give clear success criteria. Write tests first, then make them pass.

---

## ENGINEER MINDSET

- **Tenacity** — Agents never get tired. Relentless iteration beats giving up. Stamina is a force multiplier.
- **Leverage** — Imperative → Declarative. Give success criteria and watch it go. Multiply your leverage.
- **Fun** — Remove drudgery, focus on creativity. More courage, less blocking.
- **Fight Atrophy** — Writing and reading code are different. Stay sharp intentionally.
- **Speedups ≠ Just Faster** — Do more, not just faster. Expand what you can build, not just how quickly.
- **Avoid Slopacolypse** — Brace for AI slop. Hype will be loud. Signal requires judgment.

---

## KNOWN ISSUES / TECH DEBT

- `RoundEditorViewModel.bidMessage` is a `@Published` property that is written in `validateBids` but never read by any view — dead published state, should be removed.

---

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

---

*Ship small. Ship often. Keep learning. // 2026*
