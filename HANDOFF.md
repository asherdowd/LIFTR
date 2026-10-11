# LIFTR Handoff — as of 2026-10-11

Verified against GitHub on this date (origin/main and origin/feature/program-progression-merge). Local uncommitted work on the owner's Mac is NOT visible to GitHub; check `git status` first.

## Branches
| Branch | HEAD | Notes |
|---|---|---|
| `main` | `91ad216` | Build 38, tag `v1.2.1-build38`. Last shipped/TestFlight baseline. Still contains old Program + Progression code and `ExerciseReconciliationView`/`RootView`. |
| `feature/program-progression-merge` | `e978d29` | Active merge work (steps 1-3). |
| `archive/healthkit-and-schema-attempt` | `e0fca6f` | Abandoned unified-architecture/HealthKit attempt. Preserved, do not merge. |

Tags: v1.2.1, v1.2.1-build7, -build8, -build9, -build38.

## Local-only (uncommitted) work on the Mac at last report
- `SingleWorkoutCategoryView.swift` (renamed from `SingleWorkoutTypeView`), `CardioTypeView.swift` (to be DELETED), `StartWorkoutView` and `MainView` edits.
- Confirm with `git status`, then commit to the feature branch.

## The merge (Issue #4): Program + Progression -> one Workout hierarchy
Hierarchy (`Models/UnifiedWorkoutModels.swift`): `Workout` -> `WorkoutDay` -> `WorkoutExercise` -> `ExerciseSession` -> `WorkoutSet`. `Exercise` (SharedModels) has optional `coreType`.
Deload logic: `Services/DeloadAdjustmentService.swift` (static funcs; not yet wired into reachable UI beyond ExerciseSessionView).

Steps:
1. DONE: universal "Start Workout" button -> `StartWorkoutView` (Single Workout / Program).
2. DONE: Single Workout creation (`CreateSingleWorkoutView`, calls `onComplete()` not `dismiss()`).
3. DONE: `ExerciseSessionView`, `ExercisePerformanceSummaryView`, `DeloadAdjustmentService` (not reachable yet).
4. IN PROGRESS: Cardio entry. Change Cardio link in `SingleWorkoutCategoryView` to `CreateCardioProgressionView()` (existing flow); delete `CardioTypeView.swift`; check whether `CreateCardioProgressionView` uses plain `dismiss()` and needs an `onComplete` (open question). Build, test, commit.
5. Program -> Starting Strength and Madcow templates.
6. Program -> Custom (day picker, per-day exercises, weeks, per-lift start/goal weight, increment).
7. A/B/A auto-plot.
8. Repoint `MainView` and `WorkoutsView` (PR totals via `coreType != nil`, upcoming workouts, continue/paused logic) to `Workout`.
9. Delete old `Progression`, `WorkoutSession`, `WorkoutSessionView`, old views, and `WorkoutSet.session` (legacy write-only back-pointer). Data wipe for testers: add a note in the TestFlight build comments.
Then: update docs, bump build (verify in ASC; >= 39) on both targets.

Notes: `Workout` tab "Start Workout" button is universal; active `Progression`/`CardioProgression` cards and continue behavior are still the OLD model until step 8. Quick-start cardio timer was dropped (no live timer view exists). Per owner: also verify RestTimerWidget is implemented correctly during the merge. MigrationService will likely flag the model change.

## Open issues (GitHub, verified)
Bugs: #3 PR totals (largely superseded by step 8), #5/#6 deload on Program/Cardio paths, #16 progression recalculation, #23 sheet dismissal bug, #28 Upcoming Workouts empty, #29 possible data loss (unconfirmed), #30 reconciliation reappears (effectively resolved: reconciliation retired), #31 MainView empty-state button pushes duplicate WorkoutsView (filed).
Features/other: #4 merge, #7 plate calc de-dup, #8 settings redesign (per-exercise overrides are dead code), #9 schema versioning, #10 HealthKit (blocked), #11 orphan files, #12 exercise seed/picker (overlaps new flow), #15 Strava, #17 profile, #18 support backend, #19 templates, #20 metric, #21 analytics, #22 social, #24/#25 tests, #26 docs, #27 App Store prep.
Closed: #1, #2.
NOT YET FILED: ad-hoc sets during a workout (script `file_adhoc_sets.sh` written, #32 expected, not on GitHub). Strava cardio-type expansion note belongs as a comment on #15 (not yet added). Also the stale MainView empty-state text "Create a Progression" (owner said they'd fix).
Deferred until after merge: #28, #29.

## Known stale docs (update at merge landing)
`Docs/DATABASE_SCHEMA.md`, `CRITICAL_REMINDERS.md`, `DATA_MIGRATION_POLICY.md`, `CHANGELOG.md`, `README.md`, `RELEASE_CHECKLIST.md` describe Build 38 / Schema V3 and still mention the reconciliation flow, forced coreType, and Programs. Check `PLACEHOLDER_FEATURES.md` too.

## Release status
Build 38 archived/uploaded; TestFlight processing and export compliance for builds 35-37 unconfirmed. Release notes for 38 may still be unpasted.

## Other
Gh helper scripts (setup_tracker.sh, file_*.sh etc.) live in `/Users/sethdowd/Scripts`, outside the repo.
