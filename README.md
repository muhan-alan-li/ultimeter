# Ulti Stats

Ultimate frisbee stat tracker for iOS.

## Architecture

The app uses MVVM with four layers.

- `ultimeter/Model/` — SwiftData entities and the pure rules
- `ultimeter/Data/` — the repositories and the atomic write
- `ultimeter/Features/` — one view and one view model per screen
- `ultimeter/App/` — the schema and the dependency container

A view renders. A view model decides. A repository writes.

Read `AGENTS.md` before you change the code.
