# LIFTR — Session Handoff Document

**Branch:** feature/program-progression-merge  
**Last updated:** 2026-10-11  
**Current HEAD:** f68aeee + uncommitted step-4 work (see Step 4 below)

---

## Purpose

This file is read at the start of every session to restore context without relying on the AI having memory of previous sessions. Update it at the end of every milestone (commit, finished step, or key decision). Propose updates and wait for user OK before writing.

---

## Big Picture: The Merge

We are merging the old Progression/WorkoutSession model system into a unified Workout model. The work is broken into 9 steps on branch `feature/program-progression-merge`.

---

## Step 1–3: Completed (pre-session)

Steps 1–3 were completed before this handoff document was created. Details not recorded here — repo state at those commits is the source of truth.

---

## Step 4: Cardio entry in Start Workout flow — COMPLETE ✅

**Commits:** f68aeee + uncommitted changes (to be committed as step 4)

**Changes applied:**
- `CreateCardioProgressionView.swift`: added `var onComplete: () -> Void = {}`; calls `onComplete()` after successful `context.save()`; Cancel still calls `dismiss()` only.
- `SingleWorkoutCategoryView.swift`: Cardio `NavigationLink` now passes `onComplete` to `CreateCardioProgressionView(onComplete: onComplete)`.
- `CardioTypeView.swift`: deleted, `project.pbxproj` reference removed.

**Test results (manual):**
- Start Workout → Single Workout → Cardio → create progression: entire sheet dismissed, progression appeared as active cardio card in Workouts tab. ✅
- Cancel from `CreateCardioProgressionView`: returned one screen to `SingleWorkoutCategoryView`, sheet remained open. ✅

**Known issue (out of scope for step 4):** `CreateCardioProgressionView` wraps itself in its own `NavigationView`, causing a doubled nav bar when pushed from `StartWorkoutView`'s `NavigationView`. Deferred to a later cleanup step.

**Suggested commit message:** `step 4: cardio entry in start workout flow - onComplete wired, CardioTypeView deleted`

---

## Step 5: Starting Strength / Madcow templates — UP NEXT

**Goal:** Wire the "Program" button in `StartWorkoutView` to a real program-selection flow that includes Starting Strength and Madcow 5×5 templates.

**Status:** Not started. `StartWorkoutView` currently shows `Text("Program flow - coming in step 5")` as the Program destination.

**Files likely involved:** (to be confirmed before any changes)
- `StartWorkoutView.swift` — replace placeholder destination
- `CreateProgramView.swift` — existing template logic lives here (Starting Strength, Madcow already implemented per PLACEHOLDER_FEATURES.md)
- Possibly a new routing view between StartWorkoutView and CreateProgramView

---

## Step 6: Custom program

Not started. Details TBD.

---

## Step 7: A/B/A

Not started. Details TBD.

---

## Step 8: Repoint MainView / WorkoutsView to Workout model

Not started. Details TBD.

---

## Step 9: Delete old Progression / WorkoutSession code

Not started. Do this last, after Steps 8 passes all tests.

---

## How to get the AI up to speed at session start

1. Open this file (HANDOFF.md) in Xcode and paste it into the chat, or tell the AI "read HANDOFF.md and CLAUDE.md from the repo root."
2. The AI cannot browse your filesystem directly — it can only see files that Xcode surfaces to it. To make a file visible, **open it in Xcode** before or during the session, or paste its contents into the chat.
3. Run `git status`, `git log --oneline -3`, and `git diff --stat` and paste the output so the AI knows the exact repo state.

---

## Rules summary (full rules in CLAUDE.md)

- Prompt before any change not explicitly discussed.
- No refactoring unless discussed.
- Before writing code for a feature, list everywhere it needs to go and wait for confirmation.
- Verify against the repo, not memory.
- No flattery.
- Single-line git commit messages.
- After each milestone, propose a HANDOFF.md update and wait for OK before writing.
