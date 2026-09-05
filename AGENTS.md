Ulti Stats - Ultimate frisbee stat-taking iOS app.

## Structure

- `ultimeter/App/` — app entry point and setup
- `ultimeter/Features/` — one folder per feature (`Games/`, `Teams/`, `Players/`). Each folder holds its models, views, and view models together.
- `ultimeter/Features/<Name>/<Name>.swift` — SwiftData model. No UI code. One model per file.
- `ultimeter/Features/<Name>/<Name>*View.swift` — SwiftUI screens for that feature only.
- `ultimeter/Features/<Name>/<Name>*ViewModel.swift` — one view model per screen. Each file defines its own error enum. No shared error file.
- `ultimeter/Components/` — Reusable UI components. Not tied to a specific screen.
- Xcode uses synchronized groups. Move files with `git mv`; never edit `project.pbxproj`.

## Build

Verify with a compile-only build from the repo root. No simulator, no tests.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ultimeter.xcodeproj -scheme ultimeter \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData build
```

`DEVELOPER_DIR` is required; the default may point at Command Line Tools.

## Documentation

Write all .md files, including plans, in ASD-STE100 (Simplified Technical English):
approved words only, sentences under 20 words, active voice, imperative mood, short paragraphs.

Keep .md files and documentation concise.
