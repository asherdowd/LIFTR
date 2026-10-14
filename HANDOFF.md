LIFTR Handoff — updated 2026-10-13

Read this at the start of every session, together with CLAUDE.md. Update it after every milestone: propose the change and wait for OK before writing. Before ending a session, confirm this file is current. The repo is the source of truth. Verify every statement here with git status, git log and the code before relying on it.

Branches (as of 2026-10-13)
Branch    Notes
main    91ad216, Build 38, tag v1.2.1-build38. Shipped baseline. Still has the old Program code.
feature/program-progression-merge    Active merge branch. Should be fast-forwarded to the cleaned wip/xcode-agent-changes snapshot (see "Git state").
wip/xcode-agent-changes    Snapshot 796de0a of everything from the Xcode-agent sessions, on GitHub as a backup. Contains 5 dead duplicate files under LIFTR.xcodeproj/ that are being removed.
archive/healthkit-and-schema-attempt    Abandoned attempt. Preserved, do not merge.
feature/settings-redesign (local only)    Stale at e6e7e17.
Design decisions (confirmed by owner)
Single Workout = quick start. A casual user starts working out fast. Strength and Cardio each log ONE session. No plan or progression.
Programs live under Programs. Starting Strength, Madcow 5x5, Custom, and the 12-session single-lift progression (CreateSingleWorkoutView) are reached from Start Workout -> Program -> ProgramTemplatePickerView.
Cardio stays on the old CardioProgression model for now. It is a separate path from the unified Workout model.
PR Totals count only exercises with non-nil Exercise.coreType.
Navigation as built (verified in code on the snapshot)

Start Workout button (WorkoutsView) -> StartWorkoutView sheet

Single Workout -> SingleWorkoutCategoryView
Strength -> LogSingleStrengthView -> creates a Workout (1 day, 1 exercise, 1 session) -> LiveSingleWorkoutView
Cardio -> LogSingleCardioView -> creates a CardioProgression + one CardioSession -> onComplete()
Program -> ProgramTemplatePickerView -> Starting Strength / Madcow 5x5 / single-lift progression (CreateSingleWorkoutView) / Custom Program onComplete closures are passed down so the whole sheet closes (dismiss() pops only one level).
Merge steps (Issue #4)
DONE: universal Start Workout entry.
DONE: Single-lift progression creation (CreateSingleWorkoutView).
DONE: ExerciseSessionView, ExercisePerformanceSummaryView, DeloadAdjustmentService.
DONE then SUPERSEDED: cardio entry (commit 8551b4a wired CreateCardioProgressionView(onComplete:)). Single Workout now goes through LogSingleStrengthView / LogSingleCardioView instead. CreateCardioProgressionView keeps its onComplete parameter; confirm where it is still reached.
DONE (commit f9a61ae): Starting Strength (A/B alternation, 3x/week) and Madcow 5x5 (Mon/Wed/Fri, ramping sets, weekly % progression) setup views. Owner tested both create and close the sheet.
CODE PRESENT, UNTESTED: CustomProgramSetupView (day picker, per-day exercises, weeks, start/goal weights, increment). Build succeeded. No test result recorded.
NOT STARTED: A/B/A auto-plot.
NOT STARTED: repoint MainView and WorkoutsView (PR totals via coreType != nil, upcoming workouts, continue/paused logic) to Workout. Until then, Workout objects (strength quick workouts and all programs) do NOT appear in WorkoutsView or MainView. Cardio quick workouts do, because they use the old model.
NOT STARTED: delete old Progression, WorkoutSession, WorkoutSessionView, old views, and WorkoutSet.session. Testers' old Progression data will be wiped: put a note in the TestFlight comments for that build.
Schema
V3 (build 38): Exercise identity, Exercise.coreType optional.
V4 (this branch): WorkoutSet.exerciseSession: ExerciseSession? added, legacy session kept. Docs updated: DATABASE_SCHEMA.md, CRITICAL_REMINDERS.md.
UNVERIFIED: ExerciseSession.sets declares @Relationship(deleteRule: .cascade) with no explicit inverse:, and WorkoutSet now has two optional parents. A clean build does not prove SwiftData pairs them correctly. Test: create a workout, log sets, relaunch, confirm the sets persist; delete the workout, confirm its sets are removed.
NOT DONE: migration test from the build 38 store to this branch (install 38, add data, install new, verify data preserved), per DATA_MIGRATION_POLICY.md.
Git state / pending housekeeping
5 local commits (step 4, two HANDOFF moves, V4, step 5) exist on the wip/xcode-agent-changes snapshot on GitHub.
Dead files deleted locally, not yet committed: LIFTR.xcodeproj/{CustomProgramSetupView,LogSingleCardioView,LogSingleStrengthView,ProgramTemplatePickerView}.swift, LIFTR.xcodeproj/HANDOFF.md, LIFTR/Models/HANDOFF.md (it had also been added to the app's Resources). The project file already has the references removed.
Plan: commit the cleanup, fast-forward feature/program-progression-merge to it, push, keep the wip branch as backup.
project.pbxproj has five absolute-path references to /Users/sethdowd/Documents/GitHub/LIFTRSwift/*.md. Harmless but not portable.
Open items
The finished-quick-strength-workout visibility problem (see step 8).
CreateCardioProgressionView has its own NavigationView, so it can show a doubled nav bar when pushed.
MainView empty-state button still pushes a duplicate WorkoutsView instead of switching tabs (issue #31). Text changed to "Start a Workout".
Docs stale: CHANGELOG, README, RELEASE_CHECKLIST, PLACEHOLDER_FEATURES.
Verify RestTimerWidget still works after the merge.
Next build number: verify in App Store Connect (38 is the last known used; at least 39). Must match on the app and RestTimerWidgetExtension.
Issues (last verified 2026-10-11, recheck before relying)

Open: #3 PR totals, #4 merge, #5/#6 deload on Program/Cardio, #7 plate calculator de-dup, #8 settings redesign, #9 schema versioning, #10 HealthKit (blocked), #11 orphan files, #12 exercise seed/picker, #15 Strava, #16 progression recalculation, #17 profile, #18 support backend, #19 templates, #20 metric, #21 analytics, #22 social, #23 sheet dismissal bug, #24/#25 tests, #26 docs, #27 App Store prep, #28 Upcoming Workouts empty, #29 possible data loss (unconfirmed), #30 reconciliation (resolved by retirement, close it), #31 MainView nav bug. Closed: #1, #2. Not filed: ad-hoc sets during a workout (#32, script file_adhoc_sets.sh never run). Strava cardio-type expansion note belongs as a comment on #15.

Release status

Build 38 archived/uploaded; TestFlight processing and export compliance for builds 35-37 unconfirmed. Xcode Cloud auto-upload is disabled. Archive and upload manually.

Rules summary (full rules in CLAUDE.md)

Prompt before any change not explicitly discussed. No refactoring unless discussed. Before writing code list every place it must go and wait for confirmation. Verify against the repo. No flattery. Exact commands, one step at a time. Single-line git commit messages.
