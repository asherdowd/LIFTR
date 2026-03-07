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
- Note current version (e.g., V2)
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

### Step 3: Update Documentation FIRST

**Before writing code, update:**

1. **`Docs/DATABASE_SCHEMA.md`**
   - Document the change
   - Increment version number (V2 → V3)
   - Add migration notes section

2. **`CHANGELOG.md`**
   - Document breaking change
   - Note migration required

---

## 🔧 IMPLEMENTING MIGRATION

### For Simple Property Additions (Recommended):

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

### For Complex Changes:

**Use full SchemaVersions.swift approach:**
- Only if property type changes or renames
- Requires full schema duplication
- See Apple's SwiftData migration docs

---

## 🧪 TESTING MIGRATION

**MANDATORY TESTING STEPS:**

1. **Before committing:**
   - Install current build on test device
   - Create test data (progressions, workouts, programs)
   - Install new build
   - Verify all data preserved
   - Verify new properties have correct defaults

2. **TestFlight testing:**
   - Upload new build
   - Test upgrade from previous build
   - Check user reports for data loss

3. **Never skip testing:**
   - Even "simple" changes can cause data loss
   - Test on actual device, not just simulator
   - Test with substantial data, not empty database

---

## 📋 CHECKLIST FOR MODEL CHANGES

**Before committing ANY `@Model` changes:**

- [ ] Read this document
- [ ] Updated `DATABASE_SCHEMA.md` with version bump
- [ ] Added migration notes to schema doc
- [ ] Implemented migration code (MigrationService or SchemaVersions)
- [ ] Tested migration on device with existing data
- [ ] Updated `CHANGELOG.md`
- [ ] Verified all relationships still work
- [ ] Ran app with test data successfully
- [ ] No crashes on launch after upgrade

**If you can't check ALL boxes, DO NOT commit the change.**

---

## 🎯 CURRENT SCHEMA STATUS

**Version:** V3 (as of March 6, 2026)

**Last Change:** Added Strava and Apple Health integration properties
- 5 Strava properties: startTime, endTime, totalDuration, stravaActivityId, syncedToStrava
- 5 Health properties: healthKitWorkoutId, syncedToHealthKit, caloriesBurned, heartRateAverage, heartRateMax
- Added to: WorkoutSession, ExerciseSession, CardioSession

**Migration Status:** ✅ Lightweight migration (automatic)

**Next Version Will Be:** V4



---

## 📚 KEY FILES

| File | Purpose |
|------|---------|
| `Docs/DATABASE_SCHEMA.md` | Complete schema documentation |
| `Services/MigrationService.swift` | Migration repair functions |
| `Models/SchemaVersions.swift` | Full migration plan (if needed) |
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

### ✅ DO:
- Always add properties as optional first
- Test migration with real data
- Use repair functions for simple changes
- Document every change
- Version your schema
- Err on the side of caution

---

## 🔮 PLANNED FUTURE MIGRATIONS

### V3 → V4 (Planned: User Profile Expansion)
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

**When in doubt: Add optional properties and use repair functions.**

---

## 🏆 SUCCESS METRICS

**Good migration:**
- ✅ Zero data loss
- ✅ Zero crashes
- ✅ Smooth upgrade experience
- ✅ Proper defaults for new properties

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
