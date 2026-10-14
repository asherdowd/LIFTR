# LIFTR — Session Handoff Document

**Branch:** feature/program-progression-merge
**Last updated:** 2026-10-11
**Current HEAD:** f9a61ae (step 5 committed)
**Uncommitted changes:** none

---

## Purpose

Read this at the start of every session. Update after every milestone. Propose changes and wait for OK before writing.

To make this file visible to the AI: open it in Xcode Project Navigator before starting the chat, or paste its contents into the chat. Also open CLAUDE.md the same way.

---

## Big Picture: The Merge

Merging the old Progression/WorkoutSession model system into the new unified Workout model. Nine steps on branch `feature/program-progression-merge`. Two model systems coexist until step 9: old (Progression, WorkoutSession, CardioProgression) and new (Workout, WorkoutDay, WorkoutExercise, ExerciseSession).

TemplateType enum lives in StrengthModels.swift and is currently shared by both systems (Workout.templateType uses it).

---

## Step 1–3: Complete ✅
Completed before this document was created. Repo history is source of truth.

---

## Step 4: Cardio entry in Start Workout flow — COMPLETE ✅
**Commit:** 8551b4a

Changes:
- CreateCardioProgressionView.swift: added `var onComplete: () -> Void = {}`; calls onComplete() after context.save(); Cancel calls dismiss() only.
- SingleWorkoutCategoryView.swift: Cardio NavigationLink passes onComplete to CreateCardioProgressionView(onComplete: onComplete).
- CardioTypeView.swift: deleted, pbxproj reference removed.

Tests passed (manual):
- Full flow: sheet dismissed, cardio progression appeared in Workouts tab. ✅
- Cancel: returned one screen only, sheet stayed open. ✅

Known issue (deferred): CreateCardioProgressionView has its own NavigationView causing doubled nav bar when pushed from StartWorkoutView. Out of scope until cleanup step.

---

## Between Step 4 and 5: WorkoutSet inverse relationship fix — COMPLETE ✅
**Commit:** 99b0a94

Problem: WorkoutSet had `session: WorkoutSession?` (old system inverse) but no inverse for the new system. ExerciseSession.sets had no declared inverse, making the relationship fragile (orphan risk, unreliable cascade delete).

Fix: Added `exerciseSession: ExerciseSession?` to WorkoutSet in SharedModels.swift. Schema bumped to V4. No repair function needed — nil default is correct for all existing records. Lightweight migration handles automatically. Build confirmed clean.

Docs updated: DATABASE_SCHEMA.md, CRITICAL_REMINDERS.md.

---

## Step 5: Starting Strength / Madcow templates — COMPLETE ✅
**Commit:** f9a61ae

New files:
- ProgramTemplatePickerView.swift — template picker with two options
- StartingStrengthSetupView.swift — true A/B alternating structure, Squat/Bench/OHP/Deadlift, 3×/week, weight increments per session
- MadcowSetupView.swift — 3-day Mon/Wed/Fri, ramping sets (55%→100% top weight), weekly % progression, Squat/Bench/Row/OHP/Deadlift

Modified:
- StartWorkoutView.swift — Program button now routes to ProgramTemplatePickerView

Tests passed (manual):
- Start Workout → Program → Starting Strength → fill in → Create: sheet closed, no errors. ✅
- Start Workout → Program → Madcow → fill in → Create: sheet closed, no errors. ✅
- Cancel from setup screen: returned to template picker, sheet stayed open. ✅
- Back from template picker: returned to StartWorkoutView. ✅

Note: new Workout objects do not appear in WorkoutsView yet — deferred to step 8.

---

## Step 6: Custom program — UP NEXT
**Status:** Not started.

**Agreed scope:** Day picker, per-day exercises, weeks, per-lift start and goal weights, increment. Before any code: propose screens, models touched, and navigation, and wait for approval.

---

## Step 7: A/B/A auto-plot
Not started. Details TBD.

---

## Step 8: Repoint MainView / WorkoutsView to Workout model
Not started.

Current state confirmed: both MainView and WorkoutsView query old Progression and CardioProgression only. New Workout objects created via Start Workout do not appear there yet.

---

## Step 9: Delete old Progression / WorkoutSession code
Not started. Do last, after step 8 passes all tests.

---

## Pre-release refactor phase (after step 9)
Agreed intent: before first live release, do a dedicated cleanup pass covering:
- Structural fixes (like the WorkoutSet inverse, done above)
- Dead code removal (significant — two model systems coexisted, old Program code was deleted)
- Split large mono files (WorkoutsView.swift 569 lines, MainView.swift 549 lines, etc.)
- General professionalism pass

AI to flag refactor candidates as they appear during the merge, but not act on them without explicit discussion.

---

## Rules summary (full rules in CLAUDE.md)
- Prompt before any change not explicitly discussed.
- No refactoring unless discussed.
- Before writing code, list every place it needs to go and wait for confirmation.
- Verify against the repo, not memory.
- No flattery.
- Single-line git commit messages.
- After each milestone, propose HANDOFF.md update and wait for OK before writing.
- At session end: confirm HANDOFF.md is current before signing off.
