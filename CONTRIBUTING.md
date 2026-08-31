# Contributing to Ulti Stats

## Overview

**Ulti Stats** is an ultimate frisbee stat tracker for iOS. This document outlines how to contribute to the project.

## How to Run the Project

### Building & Running

The project is an Xcode iOS application built with Swift (target iOS 26.5).

```bash
# Clone the repository
git clone https://github.com/muhan-alan-li/ultimeter.git
cd ultimeter

# Build the app (requires Xcode 13+)
xcodebuild -project ultimeter.xcodeproj -scheme ultimeter -configuration Debug

# Run on a simulator or device
xcrun simctl launch simulator -n "Ulti Stats" --reset
# Or open in Xcode and press cmd-R
```

### Development Setup

- **Xcode**: 13.0 or later
- **Swift**: 5.0+
- **iOS Target**: 26.5 (iPhone 14+/iPad Pro 12th gen and later)
- **Signing**: Configure your Apple Developer account in Xcode (Team -> Signing & Capabilities)

## Pull Request Workflow

### Branch Strategy

- Create a new branch for each feature or bug-fix: `feature/<short-description>` or `bugfix/<short-description>`
- Keep branches short-lived (typically < 1 day)
- Base every PR on the latest `main` branch

### Rebase & Merge

1. **Rebase** your feature branch onto the latest `main` before submitting a PR.
2. **Squash-merge** all commits into `main` to maintain a linear commit history.
3. Ensure the PR title follows [Conventional Commits](https://www.conventionalcommits.org/).

### Example PR Title Format

```
feat: add shot tracking for players

Fixes #123
```

Or simply:

```
fix: resolve nil pointer in team aggregation
```

## Commit Message Format

We use **Conventional Commits** to keep history organized and generate automated changelogs.

### Structure

```
<type>(<scope>): <subject>

<optional body>

<footer> (optional – e.g., “breaking” or “hotfix”) </footer>
```

### Allowed Types

| Type | Description |
|------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code refactoring (no functional change) |
| `docs:` | Documentation changes |
| `test:` | Test additions/updates |
| `style:` | Formatting/linting only |
| `chore:` | Maintenance task (build, script, etc.) |
| `ci:` | CI/CD pipeline changes |
| `revert:` | Reverting a previous commit |

### Scope (optional)

A short, hyphen-separated identifier describing the area affected (e.g., `team-aggregation`, `shot-tracking`, `simulator-launch`).

### Breaking Changes

Mark breaking changes with `[breaking]` in the subject line.

## Getting Help

- Check the [README](README.md) for high-level usage
- Open an issue on GitHub for bugs or feature requests
- Fork the repo, clone locally, and follow the workflow above

## License

This project is licensed under the MIT License (see LICENSE file for details).
