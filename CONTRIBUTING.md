# Contributing to Dev Action Dashboard

Thank you for contributing.

## Ground rules

- Prefer small, focused pull requests.
- Follow the layering in [Documentation/Architecture.md](Documentation/Architecture.md): Features → Services → Core; Infrastructure implements Core protocols.
- Features must not import other features.
- Keep files small and single-responsibility.
- Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- Run SwiftLint and unit tests before opening a PR.

## Development setup

1. Install Xcode 16+.
2. Clone the repository and open `DevActionDashboard.xcodeproj`.
3. Select the **DevActionDashboard** scheme and run (⌘R).
4. Optional: `brew install swiftlint` then `swiftlint lint`.

After adding or moving source files, regenerate the Xcode project:

```bash
./Scripts/generate-xcodeproj.sh
```

To build a drag-install DMG:

```bash
./Scripts/package-dmg.sh
```

The disk image lands in `dist/`. Ad-hoc signing is the default. Developer ID signing and notarization are documented in the script header.

To refresh the README demo GIF and screenshots from a live window:

```bash
./Scripts/capture-readme-media.sh
```

## Pull request checklist

- [ ] Change is covered by tests when logic is non-trivial
- [ ] Accessibility labels added for interactive controls
- [ ] No new force-unwraps / force-casts without justification
- [ ] Changelog updated under `[Unreleased]` when user-facing

## Code of conduct

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
