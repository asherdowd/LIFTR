# LIFTR Handoff — updated 2026-10-14

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

## START HERE
1. `git fetch`, `git status`, `git log --oneline -3` on `feature/program-progression-merge`. Confirm the tree is clean and HEAD matches GitHub.
2. Current task: **step 8 planning** (repoint WorkoutsView and MainView to the new Workout model). Decisions below are agreed. The day-level screen design (decision 4) is still being discussed. NO CODE until the owner confirms the design and the full list of places (CLAUDE.md rule).
3. Step 8 goes BEFORE step 7 (A/B/A), because everything created by the new flow is invisible until step 8.

## Step 8 decisions (owner answers, 2026-10-14)
1. YES: show both old Progression cards and new Workout cards in WorkoutsView until step 9 deletes the old model.
2. YES: auto-mark a Workout `.completed` when its last session completes. Nothing in the code does this today (verify: grep for `.completed` assignments on `Workout.status`, `DeloadAdjustmentService.checkAndAdvanceWeek`). This is a small change to the completion logic.
3. YES: in the quick strength flow, Cancel with no set logged deletes the Workout (today Cancel only dismisses and leaves an empty saved Workout).
4. YES, design still under discussion: add a day-level screen listing a program day's exercises; each row opens the existing `ExerciseSessionView` (reuse, do not duplicate). Quick workouts skip it and go straight to `LiveSingleWorkoutView`. Open design questions: exercise order (free vs guided), whether a skipped exercise can still let the day finish, where deload prompt / week advance fires, whether a read-only past-day view is needed.
5. DECIDED 2026-10-14: build Detail + Edit for Workout IN step 8 (option B), scope = level 2: Workout level (name, notes, status, current week, delete) plus per-session planned weight/sets/reps and the completed toggle. Structure editing (add/remove/rename days and exercises) is a later issue. Old `EditProgressionView` (Details + Schedule tabs) and `ProgressionDetailView` are the reference but are tied to `Progression` fields; the new model has no single current/target max.
6. Agreed in principle: PR Totals read BOTH old Progression data (current substring match in `MainView.getMaxWeight(for:)`) and new `WorkoutSet`s matched by non-nil `Exercise.coreType`; count only completed sets with reps > 0 and a logged weight (so #36 zero-rep sets never become PRs); take the max of both; remove the old half at step 9. Related: #3.
7. YES: Analytics (`AnalyticsView` queries only old Progression/CardioProgression) is its OWN later step, before step 9.

Places step 8 touches (candidate list, owner must confirm): `WorkoutsView` (add `@Query Workout`, new card, continue/paused logic, delete), `MainView` (upcoming/recent/PR for Workout; fix the Upcoming filter `date >= now` that can hide a same-day session dated at start of day; empty-state nav #31), new day-level view, `ExerciseSessionView` / `LiveSingleWorkoutView` completion + `onComplete` chain, `DeloadAdjustmentService` (completion/status), `LogSingleStrengthView` (cancel cleanup), `MigrationService` / `LIFTRApp` (only if the model changes), `RestTimerWidget` (verify), docs (CHANGELOG, README, DATABASE_SCHEMA if the model changes).

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

## Working context for a new agent
- **Where work happens:** this chat (Claude Code session with the repo clone) is the primary place. The Xcode agent cannot see git/GitHub, creates duplicate files and left dead files in the project before. Use it only to validate an open file. Do not move planning into it.
- **Owner:** Seth Dowd. Not comfortable in the terminal: give exact commands one at a time and wait for confirmation; do git/file work yourself when you have access. Direct answers, no flattery.
- **Git:** do not commit or push unless asked. Never touch `main`. Single-line `-m` commit messages (multi-line heredocs hung his shell). His Mac clone: `/Users/sethdowd/Documents/GitHub/LIFTRSwift`; `git pull` there needs upstream set (`git branch --set-upstream-to=origin/feature/program-progression-merge`). A shallow cloud clone needs a fetch refspec plus `--set-upstream-to` or the stop hook gives false "unpushed commits" warnings.
- **GitHub CLI:** `gh issue list/create` uses GraphQL, which is blocked. Use REST: `gh api repos/asherdowd/LIFTR/issues ...` (always `--repo asherdowd/LIFTR` for other gh calls). Milestone Backlog = number 1. Tracker uses `initiative:*` labels.
- **Xcode:** deleting a file in Finder leaves it red in Xcode; quit Xcode normally (Cmd+Q) to clear stale entries. Check `project.pbxproj` for stray references after the Xcode agent works.
- **Test results:** the private test-run artifact (link above, `capabilities: {db: {}}`) holds 25 tests (A1-A8, B1-B8, C1-C4, D1-D5) in collection `tests`; read them with ArtifactData `list`. A draft `TEST_FLOW.md` exists only in the cloud session scratchpad, not in the repo; decide whether to commit it as `Docs/TEST_FLOW.md`.
- **Model chain:** Workout -> WorkoutDay -> WorkoutExercise -> ExerciseSession -> WorkoutSet (`Models/UnifiedWorkoutModels.swift`). Old models (`Progression`, `WorkoutSession`, `CardioProgression`) live until step 9. Old-model references: WorkoutsView, MainView, AnalyticsView, EditProgressionView, ProgressionDetailView, WorkoutSessionView, PerformanceSummaryView, SettingsView (text), StrengthModels.swift, MigrationService, LIFTRApp, Test1_MinimalView.
- **Reuse** `SetRowView`, `LogSetView`, `CalculatorViewWrapper`. `LogSetView` allows 0 reps (#36).
- **Still owed (not done):** file ad-hoc sets issue; comment on #15 (Strava) and #24 (unit-test production gate); close #30; V4 persistence/cascade test; build-38 migration test; tests C2/C3/D1; verify next build number in App Store Connect; tester note about data wipe for the step 9 build; delete `wip/xcode-agent-changes` once trusted; stale docs.
- **Open decisions:** #36 zero-rep set storage; step 5 Detail/Edit scope; step 8 day-screen design; steps 7 and 9 timing.

## Local environment and terminal commands (Seth's Mac)
- Git root: `/Users/sethdowd/Documents/GitHub/LIFTRSwift`. It holds CLAUDE.md, HANDOFF.md, README.md, CHANGELOG.md, RELEASE_CHECKLIST.md and `IOS/`. These root .md files do NOT show in Xcode unless added manually.
- Xcode project folder: `<root>/IOS/LIFTR/V1.0.0/LIFTR` containing `LIFTR.xcodeproj` (open this), `Docs/`, `LIFTR/` (app source: Models, Views, Services, LIFTRApp.swift, Assets.xcassets), `RestTimerWidget/`, `LIFTRTests/`, `LIFTRUITests/`.
- GitHub: `asherdowd/LIFTR` (the cloud clone's remote URL is lowercase `liftr`; GitHub treats them as the same repo).
- Git commands for Seth (changed 2026-10-14): always give the FULL sequence as one copy-paste block, starting with `cd /Users/sethdowd/Documents/GitHub/LIFTRSwift`, with the branch checked or checked out in the block so it works from any starting state. Example for pulling this branch: `cd /Users/sethdowd/Documents/GitHub/LIFTRSwift && git checkout feature/program-progression-merge && git pull`. Then wait for his output. Say which branch the command runs on. Never run anything on `main` without asking.
- Single-line commit messages only (`git commit -m "..."`). No heredocs, no interactive editors, no `rebase -i` / `add -i`. Pager is disabled (`core.pager cat`).
- Pull a new branch: `git fetch origin`, `git checkout <branch>`, `git branch --set-upstream-to=origin/<branch>`. Update: `git pull`. Check: `git status`, `git log --oneline -3`.
- If Xcode shows red files after on-disk changes, quit with Cmd+Q and reopen.
- **Commit/push policy (changed 2026-10-14):** Seth trusts Claude's judgment. Claude may commit and push to the feature branch (never `main`) and must tell Seth what was committed and give the pull command for his Mac.

## Rules summary (full rules in CLAUDE.md)
Prompt before any change not explicitly discussed. No refactoring unless discussed. Before writing code list every place it must go and wait for confirmation. Verify against the repo. No flattery. Exact commands, one step at a time. Single-line git commit messages.
