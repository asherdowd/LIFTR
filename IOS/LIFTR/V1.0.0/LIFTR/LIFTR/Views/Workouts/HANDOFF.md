# LIFTR — Session Handoff Document

**Branch:** feature/program-progression-merge
**Last updated:** 2026-10-11
**Current HEAD:** 8551b4a (step 4 committed)
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

## Step 5: Starting Strength / Madcow templates — UP NEXT
**Status:** Not started.

**What exists:**
- StartWorkoutView has a "Program" button with placeholder `Text("Program flow - coming in step 5")`.
- Old ProgramModels.swift, ProgramTemplates.swift, CreateProgramView.swift are DELETED on this branch (exist on main/history only).
- TemplateType enum (Starting Strength, Madcow 5x5, etc.) still lives in StrengthModels.swift, used by Workout.templateType.
- No template logic exists on this branch yet.

**Agreed approach:** Before any code, propose screens, models touched, and navigation, and wait for approval. List every place the feature must be wired in per CLAUDE.md.

---

## Step 6: Custom program
Not started. Details TBD — day picker, per-day exercises, weeks, per-lift start/goal weights, increment.

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

## Rules summary (full rules in CLAUDE.md)
- Prompt before any change not explicitly discussed.
- No refactoring unless discussed.
- Before writing code, list every place it needs to go and wait for confirmation.
- Verify against the repo, not memory.
- No flattery.
- Single-line git commit messages.
- After each milestone, propose HANDOFF.md update and wait for OK before writing.
- At session end: confirm HANDOFF.md is current before signing off.
