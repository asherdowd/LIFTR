# LIFTR Database Schema Documentation

**Last Updated:** March 8, 2026  
**Version:** 1.2.1 (Build 9)  
**Schema Version:** V1

---

## Current Schema: V1 (Baseline)

**Status:** Production baseline with versioned schemas  
**Models:** 15 total  
**Location:** `Models/SchemaVersions/V1/`

---

## Models

### User
- id (UUID, unique)
- firstName (String)
- email (String)

### GlobalProgressionSettings
Core app-wide settings for progression behavior.

**Performance Thresholds:**
- excellentThreshold (Int, default: 90)
- goodThreshold (Int, default: 75)
- adjustmentThreshold (Int, default: 50)
- reductionPercent (Double, default: 5.0)
- deloadPercent (Double, default: 10.0)

**Weight Increments:**
- lowerBodyIncrement (Double, default: 5.0 lbs)
- upperBodyIncrement (Double, default: 2.5 lbs)
- useMetric (Bool, default: false)

**Auto Features:**
- autoDeloadEnabled (Bool, default: false)
- autoDeloadFrequency (Int, default: 8 weeks)
- allowMidWorkoutAdjustments (Bool, default: true)

**Rest Timer:**
- defaultRestTime (Int, default: 180s)
- autoStartRestTimer (Bool, default: true)
- restTimerSound (Bool, default: true)
- restTimerHaptic (Bool, default: true)

**Other:**
- adjustmentMode (AdjustmentMode, default: .prompt)
- trackRPE (Bool, default: false)
- upcomingWorkoutsDays (Int, default: 7)

### ExerciseProgressionSettings
Per-exercise overrides for GlobalProgressionSettings.

- id (UUID)
- exerciseName (String)
- useCustomRules (Bool)
- Optional overrides for all threshold/increment values

### Progression
Single-exercise progression tracking.

- id (UUID)
- exerciseName (String)
- templateType (TemplateType)
- progressionStyle (ProgressionStyle)
- status (ProgressionStatus)
- currentMax, targetMax, startingWeight (Double)
- totalWeeks, currentWeek (Int)
- startDate (Date)
- sessions: [WorkoutSession] (cascade delete)

### WorkoutSession
Individual workout within a Progression.

**Core:**
- date (Date)
- weekNumber, dayNumber (Int)
- plannedWeight, plannedSets, plannedReps (Double/Int)
- completed, paused (Bool)
- completedDate (Date?)

**Strava Integration:**
- startTime, endTime (Date?)
- totalDuration (TimeInterval?)
- stravaActivityId (String?)
- syncedToStrava (Bool)

**Apple Health Integration:**
- healthKitWorkoutId (String?)
- syncedToHealthKit (Bool?)
- caloriesBurned (Double?)
- heartRateAverage, heartRateMax (Int?)

**Relationships:**
- sets: [WorkoutSet] (cascade delete)
- progression: Progression?

### WorkoutSet
Individual set within a session.

- setNumber (Int)
- targetReps, targetWeight (Int/Double)
- actualReps, actualWeight (Int?/Double?)
- rpe (Int?, 1-10 scale)
- completed (Bool)

### Program
Multi-exercise training program.

- id (UUID)
- name (String)
- templateType (TemplateType)
- status (ProgressionStatus)
- totalWeeks, currentWeek (Int)
- startDate (Date)
- trainingDays: [TrainingDay] (cascade delete)

### TrainingDay
Single day within a program (e.g., "Day A").

- name (String)
- dayNumber (Int)
- exercises: [ProgramExercise] (cascade delete)
- sessions: [ExerciseSession] (cascade delete)
- program: Program?

### ProgramExercise
Exercise template within a training day.

- exerciseName (String)
- orderIndex (Int)
- startingWeight, currentWeight (Double)
- targetSets, targetReps (Int)
- increment (Double, default: 5.0)
- trainingDay: TrainingDay?

### ExerciseSession
Completed instance of a ProgramExercise.

Same structure as WorkoutSession (includes Strava/Health properties).

### CardioProgression
Cardio-focused progression.

- name (String)
- cardioType (CardioType: running, swimming, calisthenics, crossfit, freeCardio)
- status (ProgressionStatus)
- totalWeeks, currentWeek (Int)
- startDate (Date)
- targetDistance, startingWeeklyDistance (Double?)
- exerciseName, targetReps, startingReps (for calisthenics)
- workoutType, workoutDescription (for CrossFit)
- useMetric (Bool)
- sessions: [CardioSession] (cascade delete)

### CardioSession
Individual cardio workout.

Similar to WorkoutSession with cardio-specific fields:
- plannedDistance, actualDistance, pace (Double?)
- plannedSets/Reps, actualSets/Reps (Int?, for calisthenics)
- rounds, movements (for CrossFit)
- duration (TimeInterval?)
- Includes same Strava/Health integration properties

### PlateItem
- weight (Double)
- quantity (Int)

### BarItem
- weight (Double)
- barType (String)
- quantity (Int)

### CollarItem
- weight (Double)
- quantity (Int)

---

## Enums

**ProgressionStatus:** active, paused, completed  
**AdjustmentMode:** prompt, autoAdjust, never  
**TemplateType:** startingStrength, smolov, fiveThreeOne, texasMethod, madcow, custom  
**ProgressionStyle:** linear, periodization, rpe, percentage  
**CardioType:** running, swimming, calisthenics, crossfit, freeCardio  
**CrossFitWorkoutType:** forTime, amrap, emom, tabata, custom

---

## Relationships

```
Progression → WorkoutSession → WorkoutSet
Program → TrainingDay → ProgramExercise
                      → ExerciseSession → WorkoutSet
CardioProgression → CardioSession
```

**Rules:**
- Cascade deletes: deleting parent deletes children
- GlobalProgressionSettings: singleton
- User: singleton
- WorkoutSet: shared by both progression types

---

## Schema History

**V1 (March 2026):** Production baseline
- All 15 models with Strava and Apple Health properties
- Rest timer properties in GlobalProgressionSettings
- Versioned schema system established

**V2 (Future):** TBD

---

**For migration procedures, see:** `Docs/DATA_MIGRATION_POLICY.md`  
**For critical development rules, see:** `Docs/CRITICAL_REMINDERS.md`
