# Plan: Re-architecture to MVVM

## 1. Purpose

This plan re-architects Ulti Stats as a correct MVVM app.
This plan replaces `plan-rearch.md` version 1, which removed the view models.

The app stays MVVM. The current code is MVVM in name only.
The view models hold no state and forward calls.
The views hold the business rules.
This plan moves the rules down into the view models.
This plan moves the persistence up into repositories.

The app compiles after each phase.

## 2. Departure from `ARCH-REVIEW.md`

`ARCH-REVIEW.md` recommends the opposite direction.
It recommends direct model-view. It recommends deleting the view models.
This plan keeps the view models and gives them the work.

Four findings stay valid. Three change meaning.

| Finding | Status |
|---|---|
| `Stat` is not in the schema | Valid. Fix first. |
| `ModelContext` in view init | Valid. Fix with `AppDependencies`. |
| Many save paths | Valid. Fix with one repository write. |
| Duplicate errors and alerts | Valid. Fix with one `AppError` and one modifier. |
| Stateless view models | Changed. Fill them. Do not delete them. |
| Point state in three layers | Changed. The view model owns the derived state. |
| Features depend on each other | Changed. One `Model/` folder. Keep the feature folders. |

The review also says "Test folds without a container".
Keep the rules pure. That goal does not change.

## 3. Decisions

| Topic | Decision |
|---|---|
| Live data | Views keep `@Query` as the live data source. |
| View input | View models expose `@Model` entities. Views render them read-only. |
| Persistence | Three repository protocols: `TeamRepository`, `GameRepository`, `PointRepository`. |
| Tests | Write no tests now. Keep the rules pure for later tests. |

## 4. The layer contract

This section is the definition of MVVM for this repo.
It is the part that makes the architecture real.

| Layer | Owns | Must not |
|---|---|---|
| View | Layout, navigation, sheet flags, disclosure state, and the map from a semantic value to an icon or color | Hold a business rule. Touch `ModelContext`. Save. Query, except with `@Query`. |
| ViewModel | Screen state, derived display state, every decision, every intent, every write, the error | Import SwiftUI. Touch `ModelContext`. Only forward a call. |
| Model | SwiftData entities and the pure rules | Import SwiftUI. Touch persistence. |
| Repository | All persistence. One write for one action. | Hold a UI decision. |

### 4.1 The anti-pass-through rule

A view model must own state or a decision.
A view model that only forwards a call is not a view model.
Delete it, or give it the work.

This rule is the reason the current code is not MVVM.
`TeamListViewModel` only forwards `context.delete`. It owns nothing.

### 4.2 The view rule

A view may branch only on a value the view model produced.
A view must not compare two scores, count a list, or test a state.

Find a rule in a view with this check:

```sh
grep -rn "if .*game\.\|if .*point\.\|if .*team\." ultimeter/Features
```

Only a `@Query` binding and a plain optional check may remain.

### 4.3 The reactivity rule

A view model exposes derived state as a **computed property**.
A computed property reads the SwiftData models and folds them.
Observation tracks that read through the view model.
The view redraws when the models change.

Do not cache derived state in a stored property.
A cached value does not update.

### 4.4 The dependency rule

Data goes in through `init`. Dependencies go in through the environment.

- The model being shown or edited is data. Pass it with `init`.
  Example: `TeamFormViewModel(team: team)`.
- A repository is a dependency. Pass it with `connect`.
  Example: `.connect(model)`.

This rule removes `ModelContext` from every view `init`.

## 5. Target structure

```
ultimeter/
  App/          UltimeterApp.swift, AppSchema.swift, AppDependencies.swift
  Model/        Team, Player, Game, Point, Stat, Halftime, Opponent,
                Tournament            SwiftData entities
                PointFold.swift       pure folds over the stat log
                LineRules.swift       pure line rules
                GameProgress.swift    pure game progression rules
                PointRules.swift      pure guards, pure point offer
                AppError.swift        the one error type
  Data/         TeamRepository, GameRepository, PointRepository   protocols
                SwiftData{Team,Game,Point}Repository.swift        implementations
                ModelContext+Write.swift                          the one write
  Features/     Teams/    TeamListView, TeamListViewModel, TeamRowView,
                          TeamDetailView, TeamDetailViewModel,
                          TeamFormView, TeamFormViewModel
                Players/  PlayerFormView, PlayerFormViewModel,
                          AddExistingPlayerView, AddExistingPlayerViewModel
                Games/    GameListView, GameListViewModel, GameRowView,
                          GameDetailView, GameDetailViewModel,
                          GameFormView, GameFormViewModel
                Points/   PointListView, PointListViewModel,
                          PointDetailView, PointDetailViewModel
  Components/   SuggestingPicker.swift, ErrorAlert.swift, ScreenModel.swift
```

A view and its view model share a folder. `.swift` is implied.
`Features/<Area>/<Screen>View.swift` and `<Screen>ViewModel.swift` pair up.

Ten view models exist before the change. Ten exist after.
`PointLineViewModel` merges into `PointDetailViewModel`.
`PointListViewModel` is new, because `PointListView` has no view model today.
The rest keep their names and gain work.

## 6. Rules for AGENTS.md

1. Keep one view model for each screen. Put the file next to the view.
2. Give the view model the state and the decisions. Do not forward a call.
3. Do not let a view model import SwiftUI.
4. Do not let a view hold a business rule. It branches on view model values.
5. Read a live list with `@Query`. Pass the result to a view model method.
6. Write only through a repository. One repository method is one write.
7. Do not touch `ModelContext` in a view or in a view model.
8. Pass data with `init`. Pass a repository with `connect`.
9. Throw `AppError`. Show it with the `errorAlert` modifier.
10. Keep a pure rule in `Model/`. Keep it free of a container.
11. Expose derived state as a computed property.
12. List every model in `AppSchema.models`.
13. A domain enum may keep a `displayName`. No other display text lives in `Model/`.

## 7. Design of the new parts

### 7.1 One schema

`App/AppSchema.swift` holds the model list. Add `Stat` to the list.

```swift
/// The SwiftData models of the app.
enum AppSchema {
    /// Every model in the store. Keep this list complete.
    static let models: [any PersistentModel.Type] = [
        Team.self, Player.self, Game.self, Opponent.self,
        Tournament.self, Point.self, Stat.self, Halftime.self
    ]

    static var schema: Schema { Schema(models) }

    /// Builds an in-memory container for previews.
    static func previewContainer() -> ModelContainer { ... }
}
```

`UltimeterApp` and the 10 preview containers use this list.

### 7.2 One error type

`Model/AppError.swift` replaces the 10 error enums.
The type is `Equatable`, so a later test can compare values.

```swift
/// One failure of a screen action.
enum AppError: Error, LocalizedError, Equatable {
    case notLive, notScheduled, alreadyStarted, invalidAction
    case noActivePoint, multipleActivePoints, detachedPoint
    case lineIncomplete(current: Int, required: Int)
    case lineFull(required: Int), lineLocked, notOnLine, notOnTeam
    case missingPull, missingPickup, missingScorer, notHolder
    case invalidTarget(Int), invalidScore, finalScoreBelowCurrent
    case emptyName(field: String), duplicateName(String)
    case saveFailed(String), unexpected(String)

    var errorDescription: String? { ... }

    /// Converts any error to one `AppError`. Passes an `AppError` through.
    static func from(_ error: any Error) -> AppError { ... }
}
```

Each case keeps the message from the old enum.
`saveFailed` carries a message, not an `Error`. This keeps the type `Equatable`.

### 7.3 The dependencies

`App/AppDependencies.swift` builds the three repositories.
The app installs it in the environment one time.

```swift
/// The repositories of the app.
@Observable
final class AppDependencies {
    let team: any TeamRepository
    let game: any GameRepository
    let point: any PointRepository

    /// Builds the repositories for one store container.
    init(container: ModelContainer) {
        let context = container.mainContext
        team = SwiftDataTeamRepository(context: context)
        game = SwiftDataGameRepository(context: context)
        point = SwiftDataPointRepository(context: context)
    }
}
```

```swift
@main
struct UltimeterApp: App {
    var body: some Scene {
        WindowGroup {
            TeamListView()
                .environment(AppDependencies(container: sharedModelContainer))
        }
        .modelContainer(sharedModelContainer)
    }
}
```

A preview does the same over `AppSchema.previewContainer()`.
So a preview reads and writes the same in-memory store.

### 7.4 The connect protocol

A view model needs a repository. A view `init` cannot read the environment.
`Components/ScreenModel.swift` closes that gap.

```swift
/// A screen view model. It needs the app repositories.
@MainActor
protocol ScreenModel: AnyObject {
    var dependencies: AppDependencies? { get set }
    var error: AppError? { get set }
}

extension ScreenModel {
    /// The connected repositories. Traps when the view did not connect.
    var deps: AppDependencies {
        guard let dependencies else {
            preconditionFailure("\(Self.self) is not connected. Add .connect(model).")
        }
        return dependencies
    }

    /// Connects the repositories one time.
    func connect(_ dependencies: AppDependencies) {
        guard self.dependencies == nil else { return }
        self.dependencies = dependencies
    }

    /// Runs one action. Stores the failure. Returns true on success.
    @discardableResult
    func attempt(_ action: () throws -> Void) -> Bool { ... }
}

/// Connects one screen view model to the app dependencies.
private struct DependencyConnector<Model: ScreenModel>: ViewModifier {
    @Environment(AppDependencies.self) private var dependencies
    let model: Model

    func body(content: Content) -> some View {
        model.connect(dependencies)
        return content
    }
}

extension View {
    /// Gives one screen view model its repositories.
    func connect<Model: ScreenModel>(_ model: Model) -> some View {
        modifier(DependencyConnector(model: model))
    }
}
```

`connect` is idempotent. It runs during the first body pass.
A tap cannot arrive before it. The trap is a development guard only.
`attempt` catches `AppError` into `error`, and any other error into
`AppError.unexpected`.

### 7.5 The repositories

`Data/ModelContext+Write.swift` holds the only save path.

```swift
extension ModelContext {
    /// Runs one atomic change. Rolls the context back on failure.
    func write(_ body: () throws -> Void) throws {
        do {
            try transaction { try body() }
        } catch {
            rollback()
            throw AppError.from(error)
        }
    }
}
```

The three protocols. Each is the write side of one aggregate.

```swift
@MainActor protocol TeamRepository {
    func saveTeam(_ draft: TeamDraft, editing team: Team?) throws
    func delete(_ team: Team) throws
    func addPlayer(_ draft: PlayerDraft, to team: Team) throws
    func addExisting(_ player: Player, to team: Team) throws
    func remove(_ player: Player, from team: Team) throws
}

@MainActor protocol GameRepository {
    func saveGame(_ draft: GameDraft, for team: Team, editing game: Game?) throws
    func delete(_ game: Game) throws
    func start(_ game: Game) throws
    func setCap(_ game: Game, to cap: Int) throws
    func end(_ game: Game, ourScore: Int, theirScore: Int) throws
}

/// The write side of the point aggregate.
@MainActor protocol PointRepository {
    func toggleLine(_ player: Player, in point: Point) throws
    func pruneLine(in point: Point) throws
    func unlockLine(in point: Point) throws
    func startPull(in point: Point) throws
    func pull(in point: Point, by player: Player) throws
    func recordPickup(in point: Point, by player: Player) throws
    func recordPass(in point: Point, to receiver: Player) throws
    func recordDrop(in point: Point, to receiver: Player) throws
    func recordBlock(in point: Point, by player: Player) throws
    func recordOurTurnover(in point: Point) throws
    func recordTheirTurnover(in point: Point) throws
    func undoLastPass(in point: Point) throws
    func undoDrop(in point: Point) throws
    func undoBlock(in point: Point) throws
    func undoLastTurnover(in point: Point) throws
    func scoreByPlayer(_ player: Player, in point: Point) throws
    func recordScore(of point: Point, in game: Game, scoredBy: ScoringTeam) throws
}
```

`recordScore` replaces `completeActivePoint` and `updatePointResult`.
It completes a live point. It also edits a finished result.

`TeamDraft`, `PlayerDraft`, and `GameDraft` hold the editable values
of a form. Each draft starts from a model, or stays empty for a new record.
Put each draft next to the protocol that takes it.

```swift
/// The editable values of the game form.
struct GameDraft {
    var date: Date = .now
    var opponentName: String = ""
    var tournamentName: String = ""
    var targetPoints: Int = 15
    var startingPosition: StartingPosition = .offense

    /// Starts a draft from a game, or an empty draft for a new game.
    init(game: Game? = nil) { ... }
}
```

Each repository method keeps one shape. Guard, check, then write.

```swift
func recordPass(in point: Point, to receiver: Player) throws {
    let game = try requireGame(of: point)
    try PointRules.check(.pass(receiver), game: game, point: point)
    let holder = point.holder
    try context.write {
        let stat = point.makeStat(kind: .pass)
        stat.player = holder
        stat.relatedPlayer = receiver
        context.insert(stat)
        point.stats.append(stat)
    }
}
```

`requireGame(of:)` is a private helper. It throws `AppError.detachedPoint`
when the point has no game, or when the game lost the point.

### 7.6 The pure rules

`Model/PointFold.swift` holds the folds. A `PointEvent` value removes SwiftData.

```swift
/// One event of a point log, reduced to the data a fold needs.
struct PointEvent {
    let kind: StatKind
    let player: Player?
    let relatedPlayer: Player?
}

/// Pure folds over a point log.
enum PointFold {
    static func phase(status: PointStatus, start: StartingPosition,
                      events: [PointEvent]) -> PossessionState
    static func holder(_ events: [PointEvent]) -> Player?
    static func puller(_ events: [PointEvent]) -> Player?
    static func blockers(_ events: [PointEvent]) -> [Player]
    static func scorer(_ events: [PointEvent]) -> Player?
    static func passCount(_ events: [PointEvent]) -> Int
    static func dropCount(_ events: [PointEvent]) -> Int
    static func outcome(status: PointStatus, scoredBy: ScoringTeam?,
                        start: StartingPosition) -> PointOutcome?
}
```

`Point` and `Game` keep their computed properties. Only the body changes.

`Model/LineRules.swift` holds the line rules.
`PointLineViewModel.maxLineSize` becomes `LineRules.size`.

```swift
/// The rules of a point line.
enum LineRules {
    /// The number of players on a line.
    static let size = 7

    static func sorted(_ players: [Player]) -> [Player]
    static func roster(of game: Game) -> [Player]
    static func isEditable(_ point: Point) -> Bool
    static func pruned(_ line: [Player], roster: [Player]) -> [Player]
}
```

`Model/GameProgress.swift` holds the game progression rules.
It replaces both copies of `sideForNextPoint`.

```swift
/// The rules of game progression.
enum GameProgress {
    static func nextPointNumber(in game: Game) -> Int
    static func side(forNextPointIn game: Game) -> StartingPosition
    static func reachedTarget(_ game: Game) -> Bool
    static func isHalftimeReached(_ game: Game) -> Bool
    static func halfTarget(of game: Game) -> Int
    static func capLowerBound(of game: Game) -> Int
    static func isSetupEditable(_ game: Game) -> Bool
}
```

This fixes a live difference between the two copies.
`PointDetailViewModel.sideForNextPoint` turns the side at halftime.
`GameDetailViewModel.sideForNextPoint` does not.
The new function turns the side at halftime.

`Model/PointRules.swift` holds the guards and the offer.

```swift
/// The stage of a point on screen.
enum PointStage { case scheduled, defense, looseDisc, possession, complete }

/// A problem with the line of a point.
enum LineProblem: Equatable {
    case incomplete(current: Int, required: Int)
    case rosterTooSmall(have: Int, required: Int)
}

/// The state of one point and the actions it offers.
struct PointOffer {
    let stage: PointStage
    let phase: PossessionState
    let holder, puller: Player?
    let line, roster: [Player]
    let lineIsEditable: Bool
    let lineProblem: LineProblem?
    let canPull, canSub, canScore, opponentCanScore, needsPickup: Bool
    let canUndoLastPass, canUndoTurnover, canUndoDrop, canUndoBlock: Bool
}

/// One action on a point.
enum PointAction: Equatable {
    case startPull, pull(Player), block(Player), pickup(Player)
    case pass(Player), drop(Player), score(Player)
    case ourTurnover, theirTurnover, sub
    case undoBlock, undoDrop, undoLastTurnover, undoLastPass
    case toggleLine(Player), pruneLine
}

/// The rules of point entry. Every function is pure.
enum PointRules {
    /// Reads the point state and the actions it offers.
    static func offer(game: Game, point: Point) -> PointOffer

    /// Guards one action. Throws `AppError` when the action is not allowed.
    static func check(_ action: PointAction, game: Game, point: Point) throws
}
```

The view model exposes the offer. The view renders it. No guard sits in either.

### 7.7 A view model, before and after

`PointDetailView` holds about 15 rules today.
It holds `canPull`, `canScore`, `needsPickup`, `isOngoing`,
`lineIncompleteText`, `holderOnLine`, and three undo flags.

After the change the view holds none of them.

```swift
@Observable
@MainActor
final class PointDetailViewModel: ScreenModel {
    let game: Game
    let point: Point

    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    init(game: Game, point: Point) { ... }

    /// The state of the point and the actions it offers.
    var offer: PointOffer { PointRules.offer(game: game, point: point) }

    /// The result line under the point title.
    var summary: String { ... }

    func score(_ player: Player) {
        attempt { try deps.point.scoreByPlayer(player, in: point) }
    }

    func record(_ team: ScoringTeam) {
        attempt { try deps.point.recordScore(of: point, in: game, scoredBy: team) }
    }
    // One method for each remaining action.
}
```

The view becomes declarative.

```swift
struct PointDetailView: View {
    @State private var model: PointDetailViewModel

    init(game: Game, point: Point) {
        _model = State(initialValue: PointDetailViewModel(game: game, point: point))
    }

    var body: some View {
        let offer = model.offer
        List {
            switch offer.stage {
            case .defense: defenseSection(offer)
            case .looseDisc: pickupSection(offer)
            case .possession: possessionSection(offer)
            case .scheduled: pullSection(offer)
            case .complete: resultSection(offer)
            }
        }
        .connect(model)
        .errorAlert($model.error)
    }
}
```

### 7.8 One alert

`Components/ErrorAlert.swift` replaces 9 alert blocks.

```swift
extension View {
    /// Shows one alert for a failed screen action.
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        alert("Action Failed", isPresented: ...) { ... }
    }
}
```

The view binds `$model.error`. The view model sets it through `attempt`.

## 8. Steps

Use `git mv` for every move. Never edit `project.pbxproj`.

### Phase 0 — Baseline

- [ ] Confirm a clean work tree: `git status`.
- [ ] Run the build command in section 9. Confirm it passes.
- [ ] Run SwiftLint. Confirm the baseline: 2 errors and 19 warnings.
- [ ] Create a branch: `git switch -c refactor/mvvm`.

The baseline lint failures are known. See section 11.

### Phase 1 — Fix the schema first

- [ ] Add `ultimeter/App/AppSchema.swift`. Include `Stat.self`.
- [ ] Change `UltimeterApp` to use `AppSchema.schema`.
- [ ] Change the 10 preview containers to use `AppSchema.previewContainer()`.
- [ ] Build and lint.
- [ ] Manual check, one time: run the app on a simulator.
      Confirm that the store opens with no error.
      If the store fails, delete the app from the simulator and run again.
      `AGENTS.md` asks for a compile-only build, so this check is manual.

### Phase 2 — One model folder and the pure rules

- [ ] `git mv` the 8 entity files to `ultimeter/Model/`.
- [ ] Add `Model/PointFold.swift`.
- [ ] Add `Model/LineRules.swift`.
- [ ] Add `Model/GameProgress.swift`.
- [ ] Add `Model/PointRules.swift`.
- [ ] Add `Model/AppError.swift`.
- [ ] Rewrite the `Point` computed properties to call `PointFold`.
- [ ] Rewrite `Game.halfTarget` and `Game.halfPointNumber` to call `GameProgress`.
- [ ] Change `PointLineViewModel.maxLineSize` to `LineRules.size`.
- [ ] Change `PointDetailViewModel` and `GameDetailViewModel` to call
      `GameProgress.side(forNextPointIn:)`. Remove both private copies.
- [ ] Build and lint. The app must behave the same.
      The 13 warnings in `Point.swift` and `Game.swift` must go.

### Phase 3 — Repositories and dependencies

Nothing uses the repositories yet. The app still builds.

- [ ] Add `Data/ModelContext+Write.swift`.
- [ ] Add `Data/TeamRepository.swift` with the protocol.
- [ ] Add `Data/GameRepository.swift` with the protocol and `GameDraft`.
- [ ] Add `Data/PointRepository.swift` with the protocol.
- [ ] Add `Data/SwiftDataTeamRepository.swift`.
- [ ] Add `Data/SwiftDataGameRepository.swift`.
- [ ] Add `Data/SwiftDataPointRepository.swift`.
- [ ] Copy the write logic from the view models into the repositories.
      Add the `PointRules.check` call to each method.
      Add one `context.write` to each method.
      The old view model code stays until Phase 5.
      The two copies must agree. Phase 5 deletes the old copy.
- [ ] Add `App/AppDependencies.swift`.
- [ ] Change `UltimeterApp` to install it.
- [ ] Build and lint.

### Phase 4 — The screen model protocol and the alert

- [ ] Add `Components/ScreenModel.swift` with `ScreenModel` and `.connect`.
- [ ] Add `Components/ErrorAlert.swift` with `.errorAlert`.
- [ ] Make each view model conform to `ScreenModel`.
- [ ] Build and lint.

### Phase 5 — Fill the view models

Change one screen group in each step. Then build and lint.
For each screen do these four things.

1. Move every rule from the view into the view model.
2. Move every write from the view model into a repository call.
3. Remove `init(context:)`. Pass data with `init`. Connect with `.connect`.
4. Replace the alert block with `.errorAlert($model.error)`.

#### 5a — Teams list and team form

- [ ] `TeamListViewModel`: own the error. Keep the delete intent.
- [ ] `TeamListView`: keep `@Query`. Remove `init(context:)` and the alert.
- [ ] `TeamFormViewModel`: own the draft, `canSave(in:)`, and `duplicateHint(in:)`.
- [ ] `TeamFormView`: bind to `$model.name` and `$model.division`.
      Remove `isDuplicateName`. Pass `allTeams` from `@Query` to the model.
- [ ] Move `TeamRowView` into `Features/Teams/TeamRowView.swift`.
- [ ] Build and lint.

#### 5b — Team detail and roster

- [ ] `TeamDetailViewModel`: own the sorted roster and the remove intent.
- [ ] `AddExistingPlayerViewModel`: own `availablePlayers(in:)` and the add intent.
- [ ] `PlayerFormViewModel`: own the draft and `canSave`.
- [ ] Move `AddExistingPlayerView` into `Features/Players/AddExistingPlayerView.swift`.
- [ ] Build and lint.

#### 5c — Games list and game form

- [ ] `GameListViewModel`: own the sections, the sort, and the delete intent.
- [ ] `GameRowView`: take a `GameRowPresentation`. Remove `style` and
      `accessibilityText`. Map the standing to an icon and a color only.
- [ ] `GameFormViewModel`: own the draft and `isSetupEditable`.
- [ ] Build and lint.

#### 5d — Game detail

- [ ] `GameDetailViewModel`: own `scoreText`, `canStart`, `canEnd`, `canSetCap`,
      `capLowerBound`, and `halfText`.
- [ ] Own the end-game scores and the new cap value.
- [ ] Remove `init(context:)` from `GameDetailView`.
- [ ] Build and lint. The 2 `line_length` warnings must go.

#### 5e — Points list

- [ ] Add `PointListViewModel`. Own the running score fold, the halftime
      split, the collapsed limit, and the expanded flag.
- [ ] `PointListView`: render `model.rows`. Remove `scoredRows`,
      `collapsedSpansHalftime`, and `accessibilityText`.
- [ ] Build and lint.

#### 5f — Point detail

This is the largest step. Do it alone.

- [ ] `PointDetailViewModel`: expose `offer` from `PointRules`.
- [ ] Move every view rule into the offer. Move every write to `PointRepository`.
- [ ] Merge `PointLineViewModel` into `PointDetailViewModel`.
      Delete `PointLineViewModel.swift`.
- [ ] `PointDetailView`: switch on `offer.stage`. Remove every guard.
- [ ] Build and lint. The 2 lint errors must go.

### Phase 6 — Final sweep

- [ ] Confirm no view takes a `ModelContext`.
      Check: `grep -rn "context: ModelContext" ultimeter/Features`.
- [ ] Confirm no view or view model saves.
      Check: `grep -rn "context.save()\|transaction {" ultimeter`.
- [ ] Confirm only `Data/` touches `ModelContext`.
      Check: `grep -rln "ModelContext" ultimeter`.
- [ ] Confirm no view model imports SwiftUI.
      Check: `grep -rn "^import SwiftUI" ultimeter/Features/*/*ViewModel.swift`.
      A view model imports Foundation and Observation only.
- [ ] Confirm one error enum remains.
      Check: `grep -rn ": Error, LocalizedError" ultimeter`.
- [ ] Confirm one alert modifier remains.
      Check: `grep -rn "\.alert(" ultimeter`.
- [ ] Confirm no view model is a pass-through. Read each file.
- [ ] Build with no warnings. Lint with no errors and no warnings.

### Phase 7 — Update the documentation

- [ ] Replace the Structure section of `AGENTS.md` with section 5 of this plan.
- [ ] Replace the view model rule in `AGENTS.md` with section 6 of this plan.
      The old rule says "Each file defines its own error enum. No shared error file."
      That rule is now wrong. One `AppError` replaces it.
- [ ] Add one line: "No tests yet. Verify with a compile-only build and swiftlint."
- [ ] Keep the Build section of `AGENTS.md` unchanged.
- [ ] Add a short Architecture section to `README.md`.
- [ ] Add one line to the top of `ARCH-REVIEW.md`: "Implemented by `plan-rearch.md`."
      Keep the review text unchanged.

## 9. Verification

Run the build from the repo root.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ultimeter.xcodeproj -scheme ultimeter \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData build
```

Run SwiftLint from the repo root.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftlint lint --quiet ultimeter
```

Then check each item by hand.

| Check | Expected result |
|---|---|
| View model files | 10. One for each screen. |
| Pass-through view models | 0 |
| `import SwiftUI` in a `*ViewModel.swift` | 0 |
| `ModelContext` outside `Data/` | 0 |
| `context.save()` and `transaction` sites | 1, in `ModelContext+Write.swift` |
| Error enums | 1, `AppError` |
| Alert blocks | 1, in `ErrorAlert.swift` |
| Models in `AppSchema.models` | 8, including `Stat` |
| Views with `context:` in `init` | 0 |
| Business rules in a view | 0. Section 4.2 gives the check. |
| SwiftLint errors | 0, down from 2 |
| SwiftLint warnings | 0, down from 19 |

Also do one manual run of the app.
Create a team. Add two players. Create a game and start it.
Select a full line of 7 players. Pull. Pass. Score.
Undo the last pass. Score again. End the game.
Each action must change the screen. No alert must appear.

## 10. Risks

| Risk | Response |
|---|---|
| The `Stat` schema change fails to migrate | Delete the app from the simulator. Run again. |
| Phase 5f breaks point entry | Phase 5f is one commit. Revert it alone if the build fails. |
| A cached derived value does not update | Section 4.3. Use a computed property. |
| The `connect` trap fires | The view forgot `.connect(model)`. Phase 6 checks it. |
| A view keeps one rule | Section 4.2 gives the grep command. |
| The diff is large | Each phase is one commit. The build must pass between phases. |

## 11. Baseline lint failures

SwiftLint reports 2 errors and 19 warnings before the change.
The skill says to fix every violation.
This refactor removes all of them.

| Rule | Count | File | Removed by |
|---|---|---|---|
| `type_body_length` | 2 errors | `PointDetailViewModel`, `PointDetailView` | Phase 5f |
| `file_length` | 2 warnings | `PointDetailViewModel`, `PointDetailView` | Phase 5f |
| `cyclomatic_complexity` | 1 warning | `PointDetailViewModel:506` | Phase 3 and 5f |
| `switch_case_alignment` | 8 warnings | `Point.swift` | Phase 2 |
| `trailing_whitespace` | 5 warnings | `Game.swift` | Phase 2 |
| `line_length` | 3 warnings | `GameDetailView` ×2, `GameFormView` ×1 | Phase 5c and 5d |

Do not add a SwiftLint config file to hide a violation. Fix the code instead.

## 12. Out of scope

- Unit tests. The rules stay pure, so tests are cheap later.
- New features. This plan changes the structure only.
- The stat tables of section 2.5 of `REQUIREMENTS.md`.
- CSV export of section 2.6.
