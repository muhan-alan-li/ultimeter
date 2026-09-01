Ulti Stats - Ultimate frisbee stat-taking iOS app.

## Structure

- `ultimeter/App/` — app entry point and setup
- `ultimeter/Models/` — SwiftData models. No UI code.
- `ultimeter/Views/` — SwiftUI screens, in a subfolder per model.
- `ultimeter/Components/` — Reusable UI components. Not tied to a specific screen.
- One type per file, named after the type.
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
