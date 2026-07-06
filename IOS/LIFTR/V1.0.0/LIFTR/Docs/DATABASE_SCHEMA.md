# LIFTR Database Schema Documentation

**Last Updated:** July 6, 2026  
**Version:** 1.2.1 (Build 7)  
**Schema Version:** V3 (Exercise identity + relationships)

This document describes the complete SwiftData model structure for LIFTR.

---

## 📊 MODEL OVERVIEW

### Core Model Files:
1. `Models/SettingsModels.swift` - Settings & preferences
2. `Models/StrengthModels.swift` - Progressions & workout sessions
3. `Models/SharedModels.swift` - Shared models (WorkoutSet, Exercise, enums)
4. `Models/ProgramModels.swift` - Program system models
5. `Models/CardioModels.swift` - Cardio progressions
6. `Models/InventoryModels.swift` - Equipment inventory
7. `Models/UserModels.swift` - User profile

---

## 🔧 SETTINGS MODELS

### GlobalProgressionSettings
**Purpose:** App-wide progression and workout settings  
**File:** `Models/SettingsModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `adjustmentMode` | AdjustmentMode | .prompt | How to handle workout adjustments |
| `excellentThreshold` | Int | 90 | Performance % for "excellent" |
| `goodThreshold` | Int | 75 | Performance % for "good" |
| `adjustmentThreshold` | Int | 50 | Performance % for "needs adjustment" |
| `reductionPercent` | Double | 5.0 | Weight reduction % |
| `deloadPercent` | Double | 10.0 | Deload reduction % |
| `lowerBodyIncrement` | Double | 5.0 | Lower body weight increment (lbs) |
| `upperBodyIncrement` | Double | 2.5 | Upper body weight increment (lbs) |
| `useMetric` | Bool | false | Use metric units (kg) vs imperial (lbs) |
| `autoDeloadEnabled` | Bool | false | Enable auto-deload suggestions |
| `autoDeloadFrequency` | Int | 8 | Deload frequency (weeks) |
| `trackRPE` | Bool | false | Track Rate of Perceived Exertion |
| `allowMidWorkoutAdjustments` | Bool | true | Allow mid-workout weight adjustments |
| `upcomingWorkoutsDays` | Int | 7 | Days to show in upcoming workouts |
| **`defaultRestTime`** | **Int** | **180** | **Default rest time (seconds)** ⚠️ V2 |
| **`autoStartRestTimer`** | **Bool** | **true** | **Auto-start timer after set** ⚠️ V2 |
| **`restTimerSound`** | **Bool** | **true** | **Play sound on timer complete** ⚠️ V2 |
| **`restTimerHaptic`** | **Bool** | **true** | **Haptic feedback during countdown** ⚠️ V2 |

**Relationships:** None  
**Singleton:** Only one instance should exist

**⚠️ Schema Changes:**
- **V1 → V2:** Added 4 rest timer properties (defaultRestTime, autoStartRestTimer, restTimerSound, restTimerHaptic)

---

### ExerciseProgressionSettings
**Purpose:** Per-exercise progression overrides  
**File:** `Models/SettingsModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `exerciseName` | String | - | Exercise name (legacy free-text, retained) |
| `exercise` | Exercise? | nil | Relationship to canonical Exercise (nil until reconciled) ⚠️ V3 |
| `useCustomRules` | Bool | false | Use custom rules vs global |
| `excellentThreshold` | Int? | nil | Override: excellent threshold |
| `goodThreshold` | Int? | nil | Override: good threshold |
| `adjustmentThreshold` | Int? | nil | Override: adjustment threshold |
| `reductionPercent` | Double? | nil | Override: reduction percent |
| `deloadPercent` | Double? | nil | Override: deload percent |
| `weightIncrement` | Double? | nil | Override: weight increment |
| `autoDeloadFrequency` | Int? | nil | Override: deload frequency |

**Relationships:**
- `exercise`: Exercise? (nil until reconciled via ExerciseReconciliationView)

**Cardinality:** 0 or more instances

---

## 💪 STRENGTH/PROGRESSION MODELS

### Progression
**Purpose:** Linear progression tracking for single exercise  
**File:** `Models/StrengthModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `exerciseName` | String | - | Exercise name (legacy free-text, retained) |
| `exercise` | Exercise? | nil | Relationship to canonical Exercise (nil until reconciled) ⚠️ V3 |
| `templateType` | TemplateType | - | Template used |
| `progressionStyle` | ProgressionStyle | - | Progression style (linear, periodization, etc.) |
| `status` | ProgressionStatus | .active | Active/Paused/Completed |
| `currentMax` | Double | - | Current max weight |
| `targetMax` | Double | - | Target max weight |
| `startingWeight` | Double | - | Starting training weight |
| `totalWeeks` | Int | - | Total program duration |
| `currentWeek` | Int | 1 | Current week number |
| `startDate` | Date | Date() | Start date |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `sessions`: [WorkoutSession] (cascade delete)
- `exercise`: Exercise? (nil until reconciled)

---

### WorkoutSession
**Purpose:** Single workout session for a progression  
**File:** `Models/StrengthModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `date` | Date | Date() | Session date |
| `weekNumber` | Int | - | Week in progression |
| `dayNumber` | Int | 1 | Day of week |
| `plannedWeight` | Double | - | Planned weight |
| `plannedSets` | Int | - | Planned sets |
| `plannedReps` | Int | - | Planned reps |
| `completed` | Bool | false | Completion status |
| `completedDate` | Date? | nil | Actual completion date |
| `paused` | Bool | false | Paused mid-workout |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `progression`: Progression? (parent)
- `sets`: [WorkoutSet] (cascade delete)

**Computed Properties:**
- `totalPlannedReps`: plannedSets × plannedReps
- `totalCompletedReps`: Sum of actualReps from sets
- `performancePercentage`: (completed / planned) × 100

---

### WorkoutSet
**Purpose:** Individual set within a workout  
**File:** `Models/SharedModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `setNumber` | Int | - | Set number (1, 2, 3...) |
| `targetReps` | Int | - | Target reps |
| `targetWeight` | Double | - | Target weight |
| `actualReps` | Int? | nil | Actual reps completed |
| `actualWeight` | Double? | nil | Actual weight used |
| `rpe` | Int? | nil | Rate of Perceived Exertion (1-10) |
| `completed` | Bool | false | Completion status |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `session`: WorkoutSession? (parent - legacy)

**Computed Properties:**
- `wasSuccessful`: actualReps >= targetReps

**Note:** Used by both Progressions AND Programs

---

### Exercise
**Purpose:** Canonical exercise identity, referenced by Progression/ProgramExercise/ExerciseProgressionSettings/CardioProgression  
**File:** `Models/SharedModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `name` | String | - | User-facing alias (e.g., "Straight Leg Deadlift") |
| `coreType` | ExerciseCoreType | - | Required canonical type, developer-controlled list |

**Relationships:**
- Referenced by `Progression.exercise`, `ProgramExercise.exercise`, `ExerciseProgressionSettings.exercise`, `CardioProgression.exercise` (all optional, nil until reconciled)

**Cardinality:** 0 or more instances

**Note:** Added in V2 (Build 7 dev) as an independent model requiring no migration. Relationships from the four models above were added in V3, requiring the interactive reconciliation flow described below (not a MigrationService repair function, since there is no single correct default `coreType` to auto-assign for existing data).

---

## 📚 PROGRAM MODELS

### Program
**Purpose:** Multi-exercise training program  
**File:** `Models/ProgramModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `name` | String | - | Program name |
| `templateType` | TemplateType | - | Template (Starting Strength, etc.) |
| `status` | ProgressionStatus | .active | Active/Paused/Completed |
| `totalWeeks` | Int | - | Total duration |
| `currentWeek` | Int | 1 | Current week |
| `startDate` | Date | Date() | Start date |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `trainingDays`: [TrainingDay] (cascade delete)

**Computed Properties:**
- `progressPercentage`: (currentWeek / totalWeeks) × 100

---

### TrainingDay
**Purpose:** Single training day in a program (e.g., "Day A", "Squat Day")  
**File:** `Models/ProgramModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `name` | String | - | Day name (e.g., "Workout A") |
| `dayNumber` | Int | - | Day number (1, 2, 3...) |

**Relationships:**
- `program`: Program? (parent)
- `exercises`: [ProgramExercise] (cascade delete)
- `sessions`: [ExerciseSession] (cascade delete)

---

### ProgramExercise
**Purpose:** Exercise definition within a training day  
**File:** `Models/ProgramModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `exerciseName` | String | - | Exercise name (legacy free-text, retained) |
| `exercise` | Exercise? | nil | Relationship to canonical Exercise (nil until reconciled) ⚠️ V3 |
| `orderIndex` | Int | - | Order in workout |
| `startingWeight` | Double | - | Starting weight |
| `currentWeight` | Double | - | Current weight (auto-progressed) |
| `targetSets` | Int | - | Sets per session |
| `targetReps` | Int | - | Reps per set |
| `increment` | Double | 5.0 | Weight increment per progression |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `trainingDay`: TrainingDay? (parent)
- `exercise`: Exercise? (nil until reconciled)

---

### ExerciseSession
**Purpose:** Single exercise session within a program workout  
**File:** `Models/ProgramModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `date` | Date | Date() | Session date |
| `weekNumber` | Int | - | Week in program |
| `sessionNumber` | Int | - | Sequential session number (1-36, etc.) |
| `plannedWeight` | Double | - | Planned weight for this session |
| `plannedSets` | Int | - | Planned sets |
| `plannedReps` | Int | - | Planned reps |
| `completed` | Bool | false | Completion status |
| `completedDate` | Date? | nil | Actual completion date |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `exercise`: ProgramExercise? (parent — note: this is the ProgramExercise relationship, unrelated to the new Exercise model)
- `trainingDay`: TrainingDay? (grandparent)
- `sets`: [WorkoutSet] (cascade delete)

**Note:** ExerciseSession is the "instance" of doing a ProgramExercise

---

## 🏃 CARDIO MODELS

### CardioProgression
**Purpose:** Cardio-focused progression tracking  
**File:** `Models/CardioModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `name` | String | - | Progression name |
| `cardioType` | CardioType | - | Type (running, swimming, etc.) |
| `status` | ProgressionStatus | .active | Active/Paused/Completed |
| `startDate` | Date | Date() | Start date |
| `totalWeeks` | Int | - | Total duration |
| `currentWeek` | Int | 1 | Current week |
| `targetDistance` | Double? | nil | Target distance (running/swimming) |
| `startingWeeklyDistance` | Double? | nil | Starting weekly distance |
| `exerciseName` | String? | nil | Legacy free-text name (calisthenics/CrossFit use case), retained |
| `exercise` | Exercise? | nil | Relationship to canonical Exercise (nil until reconciled) ⚠️ V3 |
| `targetReps` | Int? | nil | Target reps (calisthenics) |
| `startingReps` | Int? | nil | Starting reps (calisthenics) |
| `workoutType` | CrossFitWorkoutType? | nil | CrossFit workout type |
| `workoutDescription` | String? | nil | CrossFit workout description |
| `useMetric` | Bool | false | Use km vs miles |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `sessions`: [CardioSession] (cascade delete)
- `exercise`: Exercise? (nil until reconciled)

---

### CardioSession
**Purpose:** Single cardio workout session  
**File:** `Models/CardioModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `date` | Date | Date() | Session date |
| `weekNumber` | Int | - | Week in progression |
| `dayNumber` | Int | 1 | Day of week |
| `plannedDistance` | Double? | nil | Planned distance (running/swimming) |
| `actualDistance` | Double? | nil | Actual distance |
| `duration` | TimeInterval? | nil | Duration in seconds |
| `actualReps` | Int? | nil | Reps (calisthenics) |
| `actualSets` | Int? | nil | Sets (calisthenics) |
| `rounds` | Int? | nil | Rounds (CrossFit) |
| `movements` | String? | nil | Movements description (CrossFit) |
| `rpe` | Int? | nil | Rate of Perceived Exertion |
| `completed` | Bool | false | Completion status |
| `completedDate` | Date? | nil | Actual completion date |
| `notes` | String? | nil | Optional notes |

**Relationships:**
- `progression`: CardioProgression? (parent)

**Computed Properties:**
- `calculatePace(useMetric:)`: Pace per km/mile

---

## 📦 INVENTORY MODELS

### PlateItem
**Purpose:** Weight plate in inventory  
**File:** `Models/InventoryModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier (unique) |
| `name` | String | "" | Plate name/description |
| `weight` | Double | - | Plate weight |
| `quantity` | Int | - | Number owned |

**Relationships:** None

---

### BarItem
**Purpose:** Barbell in inventory  
**File:** `Models/InventoryModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier (unique) |
| `name` | String | "" | Bar name/description |
| `weight` | Double | - | Bar weight |
| `barType` | String | - | Bar type (e.g., "Olympic") |
| `quantity` | Int | - | Number owned |

**Relationships:** None

---

### CollarItem
**Purpose:** Collar/clip in inventory  
**File:** `Models/InventoryModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier (unique) |
| `name` | String | "" | Collar name/description |
| `weight` | Double | - | Collar weight |
| `quantity` | Int | - | Number owned |

**Relationships:** None

---

## 👤 USER MODELS

### User
**Purpose:** User profile information  
**File:** `Models/UserModels.swift`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | UUID | UUID() | Unique identifier |
| `firstName` | String | "" | First name |
| `email` | String | "" | Email address |

**Relationships:** None  
**Note:** Currently minimal - room for expansion (age, weight, height, etc.)

---

## 🔗 ENUMS

### ProgressionStatus
**File:** `Models/SharedModels.swift`

```swift
enum ProgressionStatus: String, Codable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
}
```

---

### TemplateType
**File:** `Models/StrengthModels.swift`

```swift
enum TemplateType: String, Codable, CaseIterable {
    case startingStrength = "Starting Strength"
    case smolov = "Smolov"
    case fiveThreeOne = "5/3/1"
    case texasMethod = "Texas Method"
    case madcow = "Madcow 5×5"
    case custom = "Custom"
}
```

---

### ProgressionStyle
**File:** `Models/StrengthModels.swift`

```swift
enum ProgressionStyle: String, Codable, CaseIterable {
    case linear = "Linear"
    case periodization = "Periodization"
    case rpe = "RPE-Based"
    case percentage = "Percentage-Based"
}
```

---

### AdjustmentMode
**File:** `Models/SettingsModels.swift`

```swift
enum AdjustmentMode: String, Codable, CaseIterable {
    case prompt = "prompt"
    case autoAdjust = "autoAdjust"
    case never = "never"
}
```

---

### CardioType
**File:** `Models/CardioModels.swift`

```swift
enum CardioType: String, Codable, CaseIterable {
    case running = "Running"
    case swimming = "Swimming"
    case calisthenics = "Calisthenics"
    case crossfit = "CrossFit"
    case freeCardio = "Free Cardio"
}
```

---

### ExerciseCoreType
**File:** `Models/SharedModels.swift`

```swift
enum ExerciseCoreType: String, Codable, CaseIterable {
    case deadlift = "Deadlift"
    case squat = "Squat"
    case benchPress = "Bench Press"
    case overheadPress = "Overhead Press"
}
```

---

## 📊 RELATIONSHIP DIAGRAM

```
GlobalProgressionSettings (singleton)

User (singleton)

Progression
  ├── WorkoutSession (1:many)
  │    └── WorkoutSet (1:many)
  └── exercise: Exercise? (nil until reconciled)

Program
  └── TrainingDay (1:many)
       ├── ProgramExercise (1:many)
       │    └── exercise: Exercise? (nil until reconciled)
       └── ExerciseSession (1:many)
            └── WorkoutSet (1:many)

CardioProgression
  ├── CardioSession (1:many)
  └── exercise: Exercise? (nil until reconciled)

Exercise (independent — referenced by the three above plus ExerciseProgressionSettings)

PlateItem (independent)
BarItem (independent)
CollarItem (independent)

ExerciseProgressionSettings (independent, 0:many)
  └── exercise: Exercise? (nil until reconciled)
```

---

## 🔄 SCHEMA VERSIONS

### V1 (Pre-Rest Timer)
**Date:** January 1 - January 26, 2026  
**Models:** All above models WITHOUT rest timer properties in GlobalProgressionSettings

### V2 (With Rest Timer + Exercise model)
**Date:** January 27, 2026 (rest timer); July 6, 2026 (Exercise model added, no relationships yet)  
**Changes:**
- Added `defaultRestTime: Int` to GlobalProgressionSettings
- Added `autoStartRestTimer: Bool` to GlobalProgressionSettings
- Added `restTimerSound: Bool` to GlobalProgressionSettings
- Added `restTimerHaptic: Bool` to GlobalProgressionSettings
- Added `Exercise` model (independent, no relationships — no migration required)

**Migration V1→V2:**
- Set `defaultRestTime = 180` (3 minutes)
- Set `autoStartRestTimer = true`
- Set `restTimerSound = true`
- Set `restTimerHaptic = true`
- (Exercise model addition required no migration steps)

### V3 (Exercise Identity Relationships) ⚠️ CURRENT
**Date:** July 6, 2026  
**Changes:**
- Added `exercise: Exercise?` relationship to Progression, ProgramExercise, ExerciseProgressionSettings, CardioProgression
- `exerciseName`/legacy free-text fields retained on all four (not removed) as fallback until fully reconciled

**Migration V2→V3:**
- No MigrationService repair function — there is no single correct default `coreType` to silently assign.
- Handled via new interactive flow: `RootView` detects any record with a legacy exercise name and `exercise == nil`, and routes to `ExerciseReconciliationView` instead of `ContentView` until the user assigns a `coreType` to every distinct legacy name. Confirmed via device testing (fresh install: screen does not appear; upgrade over existing data: screen appears with correct names, resolves correctly, does not reappear after).

---

## 🚨 CRITICAL NOTES

1. **GlobalProgressionSettings is a singleton** - only one instance should exist
2. **User is effectively a singleton** - only one user per device
3. **WorkoutSet is shared** - used by both Progressions and Programs
4. **Cascade deletes** - deleting parent deletes children
5. **Schema migration required** - V1 data cannot load in V2 without migration
6. **exerciseName fields are NOT removed** - `Exercise` relationships were added alongside legacy free-text fields, not as replacements. Removing the legacy fields is a distinct, future, separately-considered change.

---

## 📝 FUTURE SCHEMA CHANGES

**Potential future changes:**
- Add `startTime`, `endTime`, `totalDuration` to sessions (for Strava)
- Expand User model (age, weight, height, measurements)
- Add social features (following, sharing, etc.)
- Seed Exercise with common presets + picker UI (tracked separately, blocked by this work)
- Consider removing legacy `exerciseName` fields once fully confident all data is reconciled (not yet planned)

---

**END OF SCHEMA DOCUMENTATION**

*This document should be updated whenever models are modified.*
