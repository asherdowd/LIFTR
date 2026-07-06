# LIFTR - Data Migration Policy

**CRITICAL: READ BEFORE MODIFYING ANY @Model CLASS**

---

## 🚨 MANDATORY RULE

**EVERY change to a `@Model` class REQUIRES data migration consideration.**

Breaking this rule = **USER DATA LOSS** = **CRITICAL BUG**

---

## ✅ BEFORE CHANGING ANY MODEL

### Step 1: Check Current Schema Version
- Open `Docs/DATABASE_SCHEMA.md`
- Note current version (e.g., V3)
- Review the model you're changing

### Step 2: Determine Migration Impact

**Changes that REQUIRE migration:**
- ❌ Adding a new required (non-optional) property
- ❌ Removing a property
- ❌ Renaming a property
- ❌ Changing a property type
- ❌ Adding/removing relationships
- ❌ Changing relationship cardinality

**Changes that MAY work with lightweight migration:**
- ✅ Adding optional properties with sensible defaults
- ✅ Adding properties with default values in init
- ⚠️ Still test thoroughly!

**Changes with NO safe default (require interactive resolution, not a repair function):**
- ⚠️ Adding a required property/relationship where no single value is correct for all existing records (e.g., V3's `Exercise.coreType` — see "Implementing Migration" below)

### Step 3: Update Documentation FIRST

**Before writing code, update:**

1. **`Docs/DATABASE_SCHEMA.md`**
   - Document the change
   - Increment version number (e.g., V2 → V3)
   - Add migration notes section

2. **`CHANGELOG.md`**
   - Document breaking change
   - Note migration required

---

## 🔧 IMPLEMENTING MIGRATION

### For Simple Property Additions (Recommended, when a safe default exists):

**Use MigrationService repair pattern:**

1. Add property to model with default value
2. Add repair function to `Services/MigrationService.swift`

**Example:**
```swift
private static func repairV2toV3Defaults(context: ModelContext) {
    do {
        let descriptor = FetchDescriptor<ModelName>()
        let items = try context.fetch(descriptor)
        
        for item in items {
            // Check if migration needed
            if item.newProperty == someDefaultValue {
                item.newProperty = properValue
            }
        }
        
        try context.save()
        print("✅ V2→V3 migration repaired")
    } catch {
        print("❌ Migration repair failed: \(error)")
    }
}
```

3. Add to `performStartupChecks()`:
```swift
static func performStartupChecks(context: ModelContext) {
    repairRestTimerDefaults(context: context)      // V1→V2
    repairV2toV3Defaults(context: context)         // V2→V3 (NEW)
    // Add future migrations here
}
```

### For Changes With No Safe Default (Interactive Resolution):

When a new required property/relationship has no single correct value for existing data (e.g., a user-specific categorization choice), do NOT invent a placeholder default — build a blocking resolution screen instead:

1. Add the new property/relationship as **optional** on the model (e.g., `var exercise: Exercise?`), keeping the legacy field it's replacing in place rather than removing it in the same change — the legacy field is what the resolution screen reads from.
2. Create a detection view (e.g. `RootView`) that queries for any record where the new relationship is still `nil` and the legacy field is still present.
3. If any such records exist, show a dedicated resolution view instead of the normal app entry point (e.g. instead of `ContentView`), requiring the user to make the necessary choice(s) per distinct legacy value before proceeding.
4. On confirmation, create/link the new records and set the relationship on every matching legacy record.
5. This does NOT get called from `performStartupChecks()` — it lives in the View layer (needs `@Query` and user interaction), not as a silent context-only repair function.
6. Removing the legacy field entirely is a separate, later, more cautious change — only once you're confident all existing data has been reconciled.

**Real example:** V2→V3 added `exercise: Exercise?` to Progression/ProgramExercise/ExerciseProgressionSettings/CardioProgression. `Exercise.coreType` is required with no safe universal default, so a repair function would have to guess — instead, `RootView` detects unresolved legacy exercise names and routes to `ExerciseReconciliationView`, which requires the user to assign each a `coreType` before the app proceeds normally. `exerciseName` legacy fields were kept, not removed, so the resolution screen has something to read from.

### For Complex Changes (property type changes/renames):

**Use full SchemaVersions.swift approach:**
- Only if property type changes or renames
- Requires full schema duplication
- **Note:** `Models/SchemaVersions.swift` does not currently exist on `main`. A prior attempt exists on the `archive/healthkit-and-schema-attempt` branch but is incomplete scaffolding only (no real migration stages implemented) — do not treat it as a working reference. See Apple's SwiftData migration docs if this approach is ever actually needed.

---

## 🧪 TESTING MIGRATION

**MANDATORY TESTING STEPS:**

1. **Before committing:**
   - Install current build on test device
   - Create test data (progressions, workouts, programs)
   - Install new build
   - Verify all data preserved
   - Verify new properties have correct defaults (or, for interactive resolution changes, verify the resolution screen appears correctly and resolves as expected)

2. **Also test the "no existing data" path:**
   - Fresh install (no prior data)
   - Confirm no resolution screen appears unnecessarily (nothing to resolve)

3. **TestFlight testing:**
   - Upload new build
   - Test upgrade from previous build
   - Check user reports for data loss

4. **Never skip testing:**
   - Even "simple" changes can cause data loss
   - Test on actual device, not just simulator
   - Test with substantial data, not empty database

---

## 📋 CHECKLIST FOR MODEL CHANGES

**Before committing ANY `@Model` changes:**

- [ ] Read this document
- [ ] Updated `DATABASE_SCHEMA.md` with version bump
- [ ] Added migration notes to schema doc
- [ ] Implemented migration code (MigrationService repair function, OR interactive resolution view if no safe default exists)
- [ ] Tested migration on device with existing data
- [ ] Tested fresh install (no existing data) path
- [ ] Updated `CHANGELOG.md`
- [ ] Verified all relationships still work
- [ ] Ran app with test data successfully
- [ ] No crashes on launch after upgrade

**If you can't check ALL boxes, DO NOT commit the change.**

---

## 🎯 CURRENT SCHEMA STATUS

**Version:** V3 (as of July 6, 2026)

**Last Change:** Added `exercise: Exercise?` relationship to Progression, ProgramExercise, ExerciseProgressionSettings, CardioProgression

**Migration Status:** ✅ Interactive resolution implemented (`RootView` + `ExerciseReconciliationView`) — NOT a MigrationService repair function, since `Exercise.coreType` has no safe universal default. Tested on device: fresh install (no screen shown) and upgrade over existing real data (screen appeared with correct names, resolved correctly, did not reappear on relaunch).

**Previous Version:** V2 (as of January 27, 2026) — Added rest timer properties to GlobalProgressionSettings (`defaultRestTime`, `autoStartRestTimer`, `restTimerSound`, `restTimerHaptic`), plus the independent `Exercise` model itself (no relationships yet, no migration required at that point).

**Next Version Will Be:** V4

---

## 📚 KEY FILES

| File | Purpose |
|------|---------|
| `Docs/DATABASE_SCHEMA.md` | Complete schema documentation |
| `Services/MigrationService.swift` | Migration repair functions (default-value migrations only) |
| `Views/RootView.swift`, `Views/ExerciseReconciliationView.swift` | Interactive resolution migrations (no safe default case) |
| `Models/SchemaVersions.swift` | Does NOT exist on `main`. A prior attempt exists on `archive/healthkit-and-schema-attempt` (incomplete, scaffolding only). Do not reference as a working pattern. |
| `CHANGELOG.md` | Version history |
| This file | Migration policy |

---

## ⚠️ COMMON MISTAKES TO AVOID

### ❌ DON'T:
- Add required properties without migration
- Rename properties without SchemaVersions
- Change property types casually
- Delete properties without considering existing data
- Skip testing on real devices
- Assume SwiftData will "just work"
- Invent a placeholder/guessed default for a required field when no safe universal value exists — build interactive resolution instead

### ✅ DO:
- Always add properties as optional first
- Test migration with real data
- Use repair functions for simple changes with a safe default
- Use interactive resolution when no safe default exists
- Keep legacy fields in place until resolution/migration is proven working — don't remove them in the same change
- Document every change
- Version your schema
- Err on the side of caution

---

## 🔮 PLANNED FUTURE MIGRATIONS

### V3 → V4 (Planned: Strava Integration)
**Changes:**
- Add `startTime: Date?` to WorkoutSession/ExerciseSession/CardioSession
- Add `endTime: Date?` to WorkoutSession/ExerciseSession/CardioSession
- Add `totalDuration: TimeInterval?` to sessions
- Add `stravaActivityId: String?` to sessions
- Add `syncedToStrava: Bool` to sessions

**Migration:** MigrationService repair function (all optional/defaultable, no interactive resolution needed)

### V4 → V5 (Planned: User Profile Expansion)
**Changes:**
- Expand User model with body measurements
- Add profile photo support
- Add training preferences

**Migration:** TBD

---

## 📞 QUESTIONS?

**If unsure about a model change:**
1. Check `DATABASE_SCHEMA.md`
2. Review this policy
3. Test on device first
4. Ask in project discussion before committing

**When in doubt: Add optional properties and use repair functions if a safe default exists — otherwise build interactive resolution.**

---

## 🏆 SUCCESS METRICS

**Good migration:**
- ✅ Zero data loss
- ✅ Zero crashes
- ✅ Smooth upgrade experience
- ✅ Proper defaults for new properties (or correct interactive resolution when no default applies)

**Failed migration:**
- ❌ Users lose workout data
- ❌ App crashes on launch
- ❌ Settings reset to defaults
- ❌ Relationships broken

**We aim for 100% good migrations.**

---

**END OF POLICY**

*This policy is mandatory for all contributors and all future development.*
*Violations may result in emergency patches and user data recovery efforts.*
