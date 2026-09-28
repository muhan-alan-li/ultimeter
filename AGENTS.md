Ulti Stats - Ultimate frisbee stat-taking iOS app.

## Architecture

MVVM. Four layers. Each layer has one job.

| Layer | Owns | Must not |
|---|---|---|
| View | Layout, navigation, sheet flags, and the map from a value to an icon or color | Hold a rule. Touch `ModelContext`. Save. Query, except with `@Query`. |
| ViewModel | Screen state, derived display values, every decision, every intent, the error | Import SwiftUI. Touch `ModelContext`. Only forward a call. |
| Model | SwiftData entities and the pure rules | Import SwiftUI. Touch persistence. |
| Repository | All persistence. One write for one action. | Hold a UI decision. |

A view model must own state or a decision. Delete a view model that only
forwards a call.

## Structure

- `ultimeter/App/` — app entry point, one schema, the dependency container
- `ultimeter/Model/` — SwiftData entities and the pure rules. No SwiftUI.
- `ultimeter/Data/` — repository protocols, their SwiftData implementations,
  and the one atomic write
- `ultimeter/Features/` — one folder per area (`Teams/`, `Players/`, `Games/`,
  `Points/`). Each folder holds the views and view models of that area.
- `ultimeter/Features/<Area>/<Screen>View.swift` — one SwiftUI screen per file
- `ultimeter/Features/<Area>/<Screen>ViewModel.swift` — one view model per screen
- `ultimeter/Components/` — reusable UI and the shared screen plumbing
- Xcode uses synchronized groups. Move files with `git mv`; never edit `project.pbxproj`.

## Rules

1. Keep one view model for each screen. Put the file next to the view.
2. Give the view model the state and the decisions. Do not forward a call.
3. Do not let a view model import SwiftUI. Use Foundation and Observation.
4. Do not let a view hold a rule. A view branches on a view model value.
5. Read a live list with `@Query`. Pass the result to a view model method.
6. Write only through a repository. One repository method is one write.
7. Do not touch `ModelContext` in a view or in a view model.
8. Pass data with `init`. Pass a repository with `.connect(model)`.
9. Throw `AppError`. Show it with the `errorAlert` modifier.
10. Keep a pure rule in `Model/`. Keep it free of a container.
11. Expose derived state as a computed property. A cached value goes stale.
12. List every model in `AppSchema.models`.
13. A domain enum may keep a `displayName`. No other display text lives in `Model/`.
14. A view imports SwiftData only for `@Query` and a preview container.

## Build

Verify with a compile-only build from the repo root. No simulator, no tests.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ultimeter.xcodeproj -scheme ultimeter \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData build
```

`DEVELOPER_DIR` is required; the default may point at Command Line Tools.

Run SwiftLint from the repo root. Fix every violation.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftlint lint --quiet ultimeter
```

## Documentation

Write all .md files, including plans, in ASD-STE100 (Simplified Technical English):
approved words only, sentences under 20 words, active voice, imperative mood, short paragraphs.

Keep .md files and documentation concise.
