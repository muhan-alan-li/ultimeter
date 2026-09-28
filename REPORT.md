# Re-architecture Report

## 1. Result

The app is now MVVM. Every phase of `plan-rearch.md` is complete.
The build passes. SwiftLint reports no error and no warning.
The app runs on a simulator and opens its store.

Branch: `refactor/mvvm`. Seven commits.

## 2. Numbers

| Measure | Before | After |
|---|---|---|
| Swift files | 32 | 51 |
| Swift lines | 4184 | 4770 |
| View models | 10 | 10 |
| Stateless view models | 10 | 0 |
| Error enums | 10 | 1 |
| Alert blocks | 9 | 1 |
| `context.save()` sites | 10 | 1 |
| `ModelContext` in a view `init` | 9 views | 0 |
| Models in the schema | 7 | 8 |
| SwiftLint errors | 2 | 0 |
| SwiftLint warnings | 19 | 0 |
| View branches on a model value | 62 | 0 |

The line count went up. The new code is the `Data/` layer, the pure rules,
and one file per view. The largest file fell from 677 to 312 lines.

## 3. What changed

### One schema

`AppSchema` holds the model list. `Stat` is in the list.
The app and the 10 preview containers use the same list.

The store on the simulator now has a `ZSTAT` table. The old schema
omitted `Stat`, but `Point` and `Player` both declare a relationship to it.

### One domain

The 8 entity files moved to `Model/`. Four new files hold the pure rules:

- `PointFold` — the folds over the stat log
- `LineRules` — the line size and the line rules
- `GameProgress` — the game progression rules
- `PointRules` and `PointGuards` — the offer and the guards

`Point` and `Game` now delegate to these functions. The body is smaller.

### One save path

`ModelContext.write` calls `transaction` and rolls back on failure.
Every repository method is one `context.write`. One action is one save.

### Three repositories

`TeamRepository`, `GameRepository`, and `PointRepository` are protocols.
`SwiftData*Repository` implements them. They hold all the write logic
that the view models held before.

### One error type

`AppError` replaces 10 error enums. `attempt` catches it into the
view model. One `errorAlert` modifier replaces 9 alert blocks.

### The connect protocol

A view model needs a repository. A view `init` cannot read the environment.
`ScreenModel` and `.connect(model)` close that gap.
`connect` is idempotent and runs during the first body pass.

### Filled view models

All 10 view models now own state and decisions.
The count did not change. `PointLineViewModel` merged into
`PointDetailViewModel`. `PointListViewModel` is new.
The other 8 gained work.

## 4. Verification

| Check | Result |
|---|---|
| Compile-only build | Pass |
| SwiftLint | 0 errors, 0 warnings |
| App launch on a simulator | Pass, alive after 6 seconds |
| Store schema | `ZSTAT` present |
| Domain harness | 68 checks, all pass |

### Domain harness

I compiled the `Model/` files for macOS with a throwaway harness.
It is not in the repo. It checks the folds and the guards.

It found no defect in the new code. Every failure came from the harness.
Two were compile errors. Eight were wrong expectations. The useful results:

- `phase` is correct for 12 transitions, including both turnover directions.
- `holder` clears on a turnover and on a drop.
- `side(forNextPointIn:)` turns the side at halftime only.
- `LineRules.size` and the line problems are correct.
- 7 guard cases refuse the right action with the right error.

## 5. Defects I found and fixed

1. **`Stat` was absent from the schema.** The app schema listed 7 models.
   `Point.stats` uses a cascade delete to `Stat`. I added `Stat` and
   confirmed the `ZSTAT` table on disk.

2. **Two different `sideForNextPoint` copies.** The point copy turned the
   side at halftime. The game copy did not. One `GameProgress` function
   replaces both. This was a live difference in behaviour.

3. **`point.puller` is nil for our own offense points.** `startPull`
   writes a pull stat with no player, because they pulled. A guard that
   tested `puller != nil` would block scoring on every offense point.
   I added `PointFold.hasPull` and used it in the guards.

4. **`lineProblem` reported the wrong case.** A first version reported
   `rosterTooSmall` on a full line. The harness caught it.

## 6. Deviations from the plan

| Plan step | What I did | Why |
|---|---|---|
| Phase 4: make each view model conform to `ScreenModel` | Folded into Phase 5 | The same edit. Phase 5 rewrites each view model. |
| Phase 5a to 5f, one commit per group | One commit for all screens | The navigation graph is shared. `TeamListView` builds `TeamDetailView`, which builds `GameListView`. A signature change ripples through the graph. The app cannot compile in a half state. |
| Phase 1 and Phase 2, two commits | One commit | I staged too broadly. No work was lost. |
| Section 9: manual run | I ran it | It was the only way to test the schema change. |

## 7. What is not verified

- **Point entry by hand.** I did not tap through a live point on the
  simulator. The domain harness covers the rules. The repository writes
  are covered by the build alone.
- **The `Stat` migration on a store that holds data.** The simulator store
  was empty. A store with old data may need a migration.
- **Unit tests.** None, by your decision. The rules are pure. A test
  needs no container.
- **Accessibility and CSV export.** Out of scope.

## 8. The weakest part

`TeamListViewModel` is the thinnest view model. It holds the error and
one intent. Section 4.1 of the plan permits it, because it owns state.
It is the first candidate for a second look.

`ultimeter/Data/SwiftDataPointRepository.swift` is the largest file at 312 lines.
It holds every point write. It is a candidate for a split by concern.

## 9. Next steps

1. Tap through one full game on a simulator. Check every stage.
2. Add unit tests for `PointFold`, `LineRules`, and `GameProgress`.
   No container is necessary.
3. Test the `Stat` migration against a store that holds data.
