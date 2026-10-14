# LIFTR Handoff — updated 2026-10-13

Read this at the start of every session, together with CLAUDE.md. Update it after every milestone: propose the change and wait for OK before writing. Before ending a session, confirm this file is current.
The repo is the source of truth. Verify every statement here with `git status`, `git log` and the code before relying on it.

## Branches (as of 2026-10-13)
| Branch | Notes |
|---|---|
| `main` | `91ad216`, Build 38, tag `v1.2.1-build38`. Shipped baseline. Still has the old Program code. |
| `feature/program-progression-merge` | Active merge branch. All work lives here. |
| `wip/xcode-agent-changes` | Backup of the Xcode-agent sessions at `552b0e1`. Can be deleted once the feature branch is trusted. |
| `archive/healthkit-and-schema-attempt` | Abandoned attempt. Preserved, do not merge. |
| `feature/settings-redesign` (local only) | Stale at `e6e7e17`. |

## Design decisions (confirmed by owner)
- **Single Workout = quick start.** A casual user starts working out fast. Strength and Cardio each log ONE session. No plan or progression.
- **Programs live under Programs.** Starting Strength, Madcow 5x5, Custom, and the 12-session single-lift progression (`CreateSingleWorkoutView`) are reached from Start Workout -> Program -> `ProgramTemplatePickerView`.
- Cardio stays on the old `CardioProgression` model for now. It is a separate path from the unified Workout model.
- PR Totals count only exercises with non-nil `Exercise.coreType`.

## Navigation as built (verified in code on the snapshot)
Start Workout button (WorkoutsView) -> `StartWorkoutView` sheet
- Single Workout -> `SingleWorkoutCategoryView`
  - Strength -> `LogSingleStrengthView` -> creates a `Workout` (1 day, 1 exercise, 1 session) -> `LiveSingleWorkoutView`
  - Cardio -> `LogSingleCardioView` -> creates a `CardioProgression` + one `CardioSession` -> `onComplete()`
- Program -> `ProgramTemplatePickerView` -> Starting Strength / Madcow 5x5 / single-lift progression (`CreateSingleWorkoutView`) / Custom Program
`onComplete` closures are passed down so the whole sheet closes (`dismiss()` pops only one level).

## START HERE TOMORROW
1. `git fetch`, `git status`, `git log --oneline -3` on `feature/program-progression-merge`. Confirm the tree is clean and HEAD matches GitHub.
2. Begin **step 8** (repoint WorkoutsView and MainView to the new Workout model). Per CLAUDE.md, FIRST list every place it must change and wait for owner confirmation before any code. Known places to check: the `@Query`s in WorkoutsView and MainView, PR Totals (`getMaxWeight`, substring matching, issue #3), Upcoming workouts, Recent, continue/paused logic, `ExerciseSessionView` / `LiveSingleWorkoutView` entry points, MigrationService, RestTimerWidget, docs.
3. Decision (2026-10-13): step 8 goes BEFORE step 7 (A/B/A), because everything created by the new flow is invisible until step 8.

## Merge steps (Issue #4)
1. DONE: universal Start Workout entry.
2. DONE: Single-lift progression creation (`CreateSingleWorkoutView`).
3. DONE: `ExerciseSessionView`, `ExercisePerformanceSummaryView`, `DeloadAdjustmentService`.
4. DONE then SUPERSEDED: cardio entry (8551b4a). Single Workout now uses `LogSingleStrengthView` / `LogSingleCardioView`. `CreateCardioProgressionView` is not reachable from any screen now (see #33).
5. DONE (f9a61ae): Starting Strength and Madcow 5x5 setup views. Tested 2026-10-13: create, cancel and back work; the result is not visible anywhere (needs step 8).
6. DONE, TESTED 2026-10-13: `CustomProgramSetupView`. Creates and closes with no error; new exercise inside it works; Create is blocked until every exercise has weights. Result not visible anywhere (needs step 8).
7. NEXT AFTER 8: A/B/A auto-plot.
8. NEXT (do first): repoint `MainView` and `WorkoutsView` (PR totals via `coreType != nil`, upcoming, recent, continue/paused) to `Workout`. Tracked in #32 and #4, matches #28. Until then Workout objects do NOT appear in WorkoutsView or MainView. Cardio quick workouts do, because they use the old model.
9. NOT STARTED: delete old `Progression`, `WorkoutSession`, `WorkoutSessionView`, old views, and `WorkoutSet.session`. Testers' old Progression data will be wiped: put a note in the TestFlight comments for that build.

## Schema
- V3 (build 38): Exercise identity, `Exercise.coreType` optional.
- V4 (this branch): `WorkoutSet.exerciseSession: ExerciseSession?` added, legacy `session` kept. Docs updated: DATABASE_SCHEMA.md, CRITICAL_REMINDERS.md.
- **UNVERIFIED:** `ExerciseSession.sets` declares `@Relationship(deleteRule: .cascade)` with no explicit `inverse:`, and `WorkoutSet` now has two optional parents. A clean build does not prove SwiftData pairs them correctly. Test: create a workout, log sets, relaunch, confirm the sets persist; delete the workout, confirm its sets are removed.
- **NOT DONE:** migration test from the build 38 store to this branch (install 38, add data, install new, verify data preserved), per DATA_MIGRATION_POLICY.md.

## Git state
- Done: Xcode-agent changes and the cleanup (dead duplicate files under `LIFTR.xcodeproj/` and the bundled `LIFTR/Models/HANDOFF.md` removed) are on `feature/program-progression-merge`. Only the repo-root `HANDOFF.md` remains.
- `project.pbxproj` has five absolute-path references to `/Users/sethdowd/Documents/GitHub/LIFTRSwift/*.md`. Harmless but not portable.

## Manual test run, 2026-10-13 (commit 552b0e1, iPhone 13 Pro)
Run with the checklist page (private artifact): https://claude.ai/artifact/14Fr2jmcY26d8g7nNjz5vB . Results are stored in that page's database and can be read back with the ArtifactData tool, collection `tests`.
- 20 pass, 1 fail, 3 skipped, 1 not run.
- C1 (sets persist) is recorded as FAIL but is BLOCKED by step 8: no screen shows workouts. Verify with a unit test.
- A5 (stray Workout after Cancel) cannot be judged through the UI until step 8.
- Still owed: C2 (cascade delete), C3 (migration from build 38), D1 (existing progression card regression).
- D4 (cardio double nav bar) deferred into #33, cardio needs a full rework.
- A6: a 0-rep set can be saved and enables Complete. Decision needed, #36.

## Testing plan
- Manual now. For the production build, use unit tests wherever possible: persistence, cascade delete, program and workout creation, PR counting by `coreType`, and V4 relationship pairing. In-memory SwiftData container. Also migration from build 38 must be tested before release. Related issues: #24, #25. (A comment recording this on #24 has not been posted yet.)

## Open items
- `CreateCardioProgressionView` has its own NavigationView; deferred into #33.
- MainView empty-state button still pushes a duplicate WorkoutsView instead of switching tabs (#31). Text changed to "Start a Workout".
- Docs stale: CHANGELOG, README, RELEASE_CHECKLIST, PLACEHOLDER_FEATURES.
- Verify RestTimerWidget still works after the merge.
- Next build number: verify in App Store Connect (38 is the last known used; at least 39). Must match on the app and RestTimerWidgetExtension.

## Issues (last verified 2026-10-13)
Filed 2026-10-13: #32 new-flow workouts invisible (bug, = step 8), #33 cardio rework, #34 explicit close on rest timer and log-set sheets, #35 plate calculator link to Inventory tab, #36 zero-rep set decision. #28 was commented as reproduced.
Open (older): #3 PR totals, #4 merge, #5/#6 deload on Program/Cardio, #7 plate calculator de-dup, #8 settings redesign, #9 schema versioning, #10 HealthKit (blocked), #11 orphan files, #12 exercise seed/picker, #15 Strava, #16 progression recalculation, #17 profile, #18 support backend, #19 templates, #20 metric, #21 analytics, #22 social, #23 sheet dismissal bug, #24/#25 tests, #26 docs, #27 App Store prep, #28 Upcoming Workouts empty, #29 possible data loss (unconfirmed), #30 reconciliation (resolved by retirement, close it), #31 MainView nav bug. Closed: #1, #2.
Not filed: ad-hoc sets during a workout (script `file_adhoc_sets.sh` hard-codes the number and would now be #37 or later). Strava cardio-type expansion note belongs as a comment on #15.

## Release status
Build 38 archived/uploaded; TestFlight processing and export compliance for builds 35-37 unconfirmed. Xcode Cloud auto-upload is disabled. Archive and upload manually.

## Rules summary (full rules in CLAUDE.md)
Prompt before any change not explicitly discussed. No refactoring unless discussed. Before writing code list every place it must go and wait for confirmation. Verify against the repo. No flattery. Exact commands, one step at a time. Single-line git commit messages.
