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
   - DECIDED 2026-10-14: program days allow ANY ORDER of exercises. Quick workouts skip the day screen entirely.
   - DECIDED 2026-10-14: a day can be finished with exercises skipped (Finish Day button works at any time; unfinished exercises are marked skipped).
   - DECIDED 2026-10-14: exercise SUBSTITUTION (e.g. Leg Press swapped for Hack Squat) is a LATER step, not step 8. Rules agreed: one session only, never persists to future sessions or the program; should not count toward PRs or the original lift's progression. It will need a model change (V5: record what was actually done on `ExerciseSession`); avoid hard-coding muscle-group data objects. Not yet filed as an issue.
   - DECIDED 2026-10-14 (Q4 = A): a skipped session counts as done for WEEK ADVANCE only; it stays recorded as skipped, not completed, so it never counts toward PRs or history. `ExerciseSession` has NO skipped field today (verified: no `skipped`/`isSkipped` anywhere in the code), so this needs `var skipped: Bool = false` (inline default) = a schema change in step 8 (V4 -> V5 or fold into V4 if unreleased). Touch list if confirmed: UnifiedWorkoutModels.swift, MigrationService, LIFTRApp registration, Docs/DATABASE_SCHEMA.md, DATA_MIGRATION_POLICY.md, `DeloadAdjustmentService.checkAndAdvanceWeek` (count completed OR skipped), day screen Skip action, Detail/Edit, RestTimerWidget check. CONFIRMED by owner 2026-10-14 (11:30): add `skipped` and fold it into V4 (V4 not yet released to testers).
   - DECIDED 2026-10-14 (Q6 = A): Continue on a program card opens the day screen for the next unfinished day (resumes a day in progress); the day screen has a "Choose a different day" link. Owner approved the 3-screen sketch (Workouts card -> day screen -> existing ExerciseSessionView), "can tweak later". Day screen: rows tappable in any order, per-row Skip, Finish Day always available. Upcoming/Recent rows on Home open the same day screen. Quick workouts have no Continue card and no day screen; they appear in Recent history only.
   - FINDING (code, 2026-10-14): `DeloadAdjustmentService.checkAndAdvanceWeek` advances `Workout.currentWeek` only when EVERY session of the week has `completed == true`, and it is called from `ExerciseSessionView` on session completion. A skipped session is not completed, so skipping blocks week advance. Needs a decision (skipped counts as done for week advance?). Also progression/deload weight changes fire per exercise on completion.
5. DECIDED 2026-10-14: build Detail + Edit for Workout IN step 8 (option B), scope = level 2: Workout level (name, notes, status, current week, delete) plus per-session planned weight/sets/reps and the completed toggle. Structure editing (add/remove/rename days and exercises) is a later issue. Old `EditProgressionView` (Details + Schedule tabs) and `ProgressionDetailView` are the reference but are tied to `Progression` fields; the new model has no single current/target max.
6. Agreed in principle: PR Totals read BOTH old Progression data (current substring match in `MainView.getMaxWeight(for:)`) and new `WorkoutSet`s matched by non-nil `Exercise.coreType`; count only completed sets with reps > 0 and a logged weight (so #36 zero-rep sets never become PRs); take the max of both; remove the old half at step 9. Related: #3.
7. YES: Analytics (`AnalyticsView` queries only old Progression/CardioProgression) is its OWN later step, before step 9.

STEP 8 SCOPE CONFIRMED by owner 2026-10-14 (12:06). Proposed sub-order: 8a model + services, 8b WorkoutsView cards, 8c day screen, 8d MainView, 8e Detail/Edit.
- NEW files (must be added to the Xcode project; check pbxproj): day screen view, `WorkoutDetailView`, `EditWorkoutView` (level 2).
- Model/services (8a): `UnifiedWorkoutModels.swift` (`ExerciseSession.skipped: Bool = false`, folded into V4), `MigrationService`, `LIFTRApp.swift` registration check, `DeloadAdjustmentService` (week advance counts completed OR skipped; mark `Workout.status = .completed` when the last session is completed or skipped), `Docs/DATABASE_SCHEMA.md`, `DATA_MIGRATION_POLICY.md`, `CRITICAL_REMINDERS.md`.
- Views: `WorkoutsView` (add `@Query Workout`, card with Continue + menu for Details/Edit/Delete, keep old Progression cards until step 9); `MainView` (Upcoming and Recent for Workout, combined PR totals, fix `date >= now` same-day filter, #31 empty-state nav); `ExerciseSessionView` (return to day screen, Skip, `onComplete` chain); `LogSingleStrengthView` / `LiveSingleWorkoutView` (Cancel with no sets logged deletes the empty Workout, decision 3).
- Verify only: `RestTimerWidget`, V4 relationship pairing / cascade (unit test), migration from build 38.
- Docs: CHANGELOG, README (stale), HANDOFF.
- Out of scope for step 8: exercise substitution, structure editing (days/exercises), Analytics repoint, A/B/A (step 7), deleting old models (step 9), cardio.

## Cardio parity (owner direction, 2026-10-14)
Strength design changes (skip, any-order days, substitution, edit levels, week-advance rules) should be slated for cardio too, at least as planning input for the cardio rework (#33). Owner goal for cardio: mirror Strava and Garmin at a base level for tracking TRAIL RUNS. Cardio stays a separate path from the Workout model until that rework; nothing for cardio is built in step 8. Related: #33, #15 (Strava), #10 (HealthKit, blocked). When #33 is scoped, start by listing which strength decisions carry over (skipped sessions, one-off activity substitution, editable planned values, completion/week-advance).

## Clean-code plan (owner approved direction, 2026-10-14)
Screening of the app source (line counts and greps, NOT a full audit): about 12,700 lines in 50 Swift files (Models 930, Services 517, Views 11,194). Structure is sound; problems are mostly temporary or dead code.
- Temporary: old model stack (`WorkoutSessionView` 329, `EditProgressionView` 454, `ProgressionDetailView` 430, `PerformanceSummaryView`, old models) goes at step 9; cardio views (~1,700 lines) go in the #33 rework.
- Dead code (not yet removed, owner has not decided): `Item.swift` (Xcode template leftover, unused, not in the model container) and `Views/Tests/` (`TestView`, `Test1_MinimalView`, ~800 lines, referenced only by each other).
- Real design smell: five views each build the Workout/Day/Exercise/Session hierarchy inline with their own `ExerciseSession(` loop: `CreateSingleWorkoutView`, `CustomProgramSetupView`, `StartingStrengthSetupView`, `MadcowSetupView`, `LogSingleStrengthView`. A new field default or rule must be changed in five places; A/B/A (step 7) would add a sixth.
- DEPENDENCY (owner, 2026-10-14): cardio design planning (#33; Strava/Garmin trail-run baseline) BLOCKS the program-building service design, so the service's requirements include cardio before it is designed. Planning/mapping only, not the cardio build itself.
- APPROVED DIRECTION: extract ONE program-building service that the setup views call. It must be designed carefully to handle dynamic scenarios (all templates, custom programs, quick workouts, future A/B/A, substitution, cardio parity). Needs its own planning discussion and owner OK before any code; it is a refactor and not part of step 8.
- Other notes: data writes are spread across 16 view files and there are 17 private logic helpers inside views (acceptable for simple saves). Large files (`AnalyticsView` 754, `WorkoutsView` 569, `MainView` 549) hold several subviews; step 8 grows the last two. Splitting card/row subviews into their own files is optional and needs owner OK.
- Proposed timing: (1) DONE 2026-10-14 (fe3958f, build passed): `Item.swift` and `Views/Tests/` removed, pbxproj clean; (2) step 8; (3) step 9 deletes the old models; (4) program-building service BEFORE step 7; (5) before production build: split oversized views and a full dead-code pass.

## Step 8a findings (code, 2026-10-14, before any 8a code)
- `LIFTRTests/LIFTRTests.swift` (44 lines, XCTest) tests `PlateInventoryItem`, a type that does not exist in the app (grep found no definition; the container uses `PlateItem`). The existing test target is stale and probably does not compile. The V4 persistence/cascade test needs a working test target first; replacing or fixing that stale file needs owner OK.
- `MigrationService.swift` names a commented-out `repairV3toV4_UserProfileExpansion`: that "V4" is a different, unreleased profile-expansion idea. The Workout `WorkoutSet.exerciseSession` change is called V4 only in the Docs. Naming collision to keep in mind when documenting the `skipped` field.
- `ExerciseSession` already registered in `LIFTRApp.swift`; adding `var skipped: Bool = false` needs no registration change and no MigrationService repair (inline default covers existing rows).
- `Workout.status` is `ProgressionStatus` (`.active`, `.paused`, `.completed`) from `SharedModels.swift`.

## Step 8a status (2026-10-14)
WRITTEN, NOT YET BUILT OR RUN (the cloud environment cannot compile Swift; nothing here is verified until the owner builds and runs tests in Xcode):
- `ExerciseSession.skipped: Bool = false` added (declaration + init), folded into V4.
- `DeloadAdjustmentService.checkAndAdvanceWeek`: week advance counts completed OR skipped; sets `Workout.status = .completed` when every session in the workout is completed or skipped.
- `LIFTRTests/LIFTRTests.swift` replaced (old file tested non-existent `PlateInventoryItem`). New XCTest cases: PlateItem add/delete, skipped default + persistence, WorkoutSet/ExerciseSession pairing (both directions), cascade delete (Workout and ExerciseSession), week-advance and completion logic. Uses an in-memory container with the same model list as `LIFTRApp.swift`; keep the two lists in sync.
- Docs updated: DATABASE_SCHEMA.md, CRITICAL_REMINDERS.md, DATA_MIGRATION_POLICY.md (its older "planned" version numbers are stale).
- KNOWN GAP for 8c: `LiveSingleWorkoutView` (quick workouts) sets `session.completed` itself and does not call `checkAndAdvanceWeek`, so quick workouts will not be marked `.completed` until that view is updated in 8c.
- RESULT 2026-10-14 12:23: owner built and ran tests in Xcode: build succeeded, 13 of 13 tests passed, 0 failures. This verifies, in an in-memory store: ExerciseSession.sets pairs with WorkoutSet.exerciseSession (and not the legacy session), cascade delete from Workout and from ExerciseSession, `skipped` default/persistence, skip-aware week advance and Workout completion. NOT covered: on-disk persistence across app relaunch, migration from a build 38 store (still owed), the unit tests have not run on device.

## Step 8b+8c status (2026-10-14, merged because the card's Continue needs the day screen)
WRITTEN, NOT YET BUILT OR RUN (cloud cannot compile Swift). Owner must add the two NEW files to the Xcode app target (classic groups, not synchronized): `Views/Workouts/WorkoutCardView.swift` and `Views/Workouts/WorkoutDayView.swift`.
- `WorkoutCardView`: card for active `Workout`s (name, template, status, week progress when totalWeeks > 1, Next/Paused workout + Start/Resume link to the day screen, Delete with confirmation, same delayed-save delete pattern as ProgressionCard). No Detail/Edit yet (8e).
- `WorkoutDayView`: day screen for a fixed week. Rows in any order; swipe-left Skip; "Choose a different day" menu when the workout has more than one day; Finish Day (confirms, marks unfinished sessions skipped, one `checkAndAdvanceWeek`). Freeform (quick) exercises open `LiveSingleWorkoutView`, planned ones open `ExerciseSessionView`. Completed rows are not tappable; skipped rows can be tapped to do them anyway.
- `UnifiedWorkoutModels.swift`: computed-only helpers (`isDone`, `hasLoggedSets`, `isFreeform` = targetSets == 0, `session(forWeek:)`, `sortedExercises`, `sessions(forWeek:)`, `isFinished(forWeek:)`, `sortedDays`, `nextDay`, `hasPausedSession(forWeek:)`). No schema change.
- `DeloadAdjustmentService.checkAndAdvanceWeek`: (a) completing a skipped session clears `skipped`; (b) only the CURRENT week can advance the workout (bug guard so a repeated check on an earlier week cannot advance twice). These two were not in the original 8a list; flagged to owner.
- `WorkoutsView`: `@Query Workout`; Strength section shows active Workout cards above the legacy Progression cards; empty state only when both are empty.
- `LiveSingleWorkoutView`: Complete now calls `checkAndAdvanceWeek` so quick workouts become `.completed`.
- `LogSingleStrengthView`: when the live screen is left (Cancel or Back) with nothing logged and not completed, the empty Workout is deleted after 0.4 s (delay avoids reading deleted objects during the pop). Workouts with logged sets stay active and resumable from the card.
- Tests added (5): skip cleared on completion, earlier-week check does not re-advance, nextDay selection, session(forWeek:) with several sessions per week, freeform flag.
- Known limits: an app killed before any set is logged leaves an empty active quick Workout on the card (delete it from the card). In a single-lift progression with several sessions per week all sessions sit under one day, so Finish Day / Skip act on the next pending session only.
- Not touched yet: `MainView` (8d), Detail/Edit (8e), `ExerciseSessionView` (not changed).

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
- **PARTLY VERIFIED 2026-10-14 (13/13 in-memory unit tests, see Step 8a status):** `ExerciseSession.sets` declares `@Relationship(deleteRule: .cascade)` with no explicit `inverse:`, and `WorkoutSet` now has two optional parents. A clean build does not prove SwiftData pairs them correctly. Test: create a workout, log sets, relaunch, confirm the sets persist; delete the workout, confirm its sets are removed.
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
