# LIFTR — Standing Project Instructions

iOS strength and cardio tracker (SwiftUI + SwiftData) with a barbell visualizer / plate calculator and strength equipment inventory.
Repo: `asherdowd/LIFTR` (always pass `--repo asherdowd/LIFTR` to `gh`). Xcode project: `IOS/LIFTR/V1.0.0/LIFTR/LIFTR.xcodeproj`.
For current state, branches, open work and next steps read **`HANDOFF.md`** (repo root) before doing anything.

## How to work with me (non-negotiable)
- **Source of truth:** the git repo first (verify with `git fetch` / `git log` / `git status`, not memory), then `HANDOFF.md` and `Docs/`. Re-verify claims against the repo; do not trust a "success" message alone (an earlier push said "up-to-date" while docs were never committed; Xcode Cloud silently consumed build numbers).
- **Prompt before adding any feature or change that has not been explicitly discussed.**
- **Do not refactor unless we have discussed it.**
- **Before writing code for a feature, prompt me to confirm everywhere in the project it needs to be implemented** (and list the places you found: models, views, MainView/WorkoutsView, MigrationService, RestTimerWidget, docs).
- When discussing implementation of phases, verify the git repo first and ask me to confirm we are covering all necessary places.
- Answer questions directly. No flattery or enthusiastic padding.
- When troubleshooting, stay objective until the solution is confirmed. State hypotheses as hypotheses.
- I am not comfortable in the terminal: give exact commands, one step at a time, and wait for confirmation. Prefer doing file/git work yourself when you have direct access.
- Commit messages: single-line `-m` (multi-line heredocs have hung my shell twice). `git config --global core.pager cat` is set to avoid the `less` trap.
- Don't commit or push unless I ask. Never touch `main` directly without asking.

## Architecture rules
- **SwiftData lightweight migration** only reads defaults from the property declaration (`var x: Bool = false`), NOT init defaults. Every new non-optional stored property needs an inline default, or existing stores crash on load ("missing attribute values on mandatory destination attribute"). Enum defaults must be fully qualified (`ProgressionStatus.active`).
- Any model change: check `Services/MigrationService.swift`, `LIFTRApp.swift` ModelContainer registration, and `Docs/DATABASE_SCHEMA.md` / `Docs/DATA_MIGRATION_POLICY.md`. Use a MigrationService repair when a safe default exists. The pre-commit hook only checks `Models/SchemaVersions/`, which does not exist, so it is inert.
- **Build numbers:** `CURRENT_PROJECT_VERSION` must match on the app target AND `RestTimerWidgetExtension` (mismatch = CFBundleVersion error). Apple never lets a number be reused and Xcode Cloud may have consumed some: verify the next number in App Store Connect → TestFlight → Builds. Build 38 is the last known used.
- **PR Totals** count only exercises with non-nil `Exercise.coreType` (Squat, Bench, Deadlift, plus OHP). Custom exercises have `coreType == nil` and are excluded.
- **SwiftUI navigation:** `dismiss()` pops only its own context. Deep NavigationLink stacks inside a sheet must pass an `onComplete` closure down from the sheet owner (`StartWorkoutView` calls `dismiss()`).
- Reuse existing views (`SetRowView`, `LogSetView`, `CalculatorViewWrapper`); do not duplicate implementations.
- Keep `RestTimerWidget` working whenever shared models change.
- Cardio stays a separate path from the unified Workout model for now.

## Release / docs
- Docs live in `IOS/LIFTR/V1.0.0/LIFTR/Docs/` plus root `README.md`, `CHANGELOG.md`, `RELEASE_CHECKLIST.md`. Update them when models or build numbers change.
- Xcode Cloud: distribution is set to None / workflow disabled to stop auto-uploads. Archive and upload manually.
- Tracker: GitHub Issues with `initiative:*` labels and the Backlog milestone.
