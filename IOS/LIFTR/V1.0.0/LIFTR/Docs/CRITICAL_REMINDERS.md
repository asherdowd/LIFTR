# CRITICAL REMINDERS FOR LIFTR DEVELOPMENT

**⚠️ READ THIS FIRST IN EVERY SESSION ⚠️**

This document contains critical rules that must ALWAYS be followed when making changes to the LIFTR codebase.

---

## 🚨 RULE #1: DATA MIGRATION IS MANDATORY

### **NEVER modify @Model classes without migration planning**

**Why:** SwiftData schema changes break existing user data. Users will lose ALL their workouts, progressions, and settings if migration is not handled properly.

### **Before Making ANY Changes to Models:**

**1. Check if change affects existing properties:**
   - Adding NEW properties → Requires migration consideration
   - Modifying EXISTING properties → Requires migration
   - Removing properties → Requires migration
   - Changing property types → Requires migration
   - Renaming properties → Requires migration

**2. Document the change in DATABASE_SCHEMA.md:**
   - Update the schema version (V2 → V3, etc.)
   - Document what changed
   - List migration steps needed

**3. Add repair function to MigrationService.swift:**
   ```swift
   private static func repairV2toV3Migration(context: ModelContext) {
       // Add default values for new properties
       // Migrate existing data if needed
       // Log the migration
   }
   ```

**4. Test migration path:**
   - Test with OLD data (previous build)
   - Install NEW build
   - Verify data is preserved
   - Verify new properties have correct defaults

---

## 📋 MODEL FILES TO WATCH

**These files contain @Model classes - NEVER modify without migration plan:**

- ✅ `Models/SettingsModels.swift` - GlobalProgressionSettings, ExerciseProgressionSettings
- ✅ `Models/StrengthModels.swift` - Progression, WorkoutSession
- ✅ `Models/SharedModels.swift` - WorkoutSet
- ✅ `Models/ProgramModels.swift` - Program, TrainingDay, ProgramExercise, ExerciseSession
- ✅ `Models/CardioModels.swift` - CardioProgression, CardioSession
- ✅ `Models/InventoryModels.swift` - PlateItem, BarItem, CollarItem
- ✅ `Models/UserModels.swift` - User

---

## ✅ SAFE CHANGES (No Migration Needed)

**You CAN make these changes without migration:**

1. **Adding computed properties** (not stored)
   ```swift
   var totalWeight: Double {
       return sets.reduce(0) { $0 + ($1.actualWeight ?? 0) }
   }
   ```

2. **Adding methods to models**
   ```swift
   func calculatePerformance() -> Double { ... }
   ```

3. **Adding new, independent models** (no relationships to existing)
   ```swift
   @Model
   class NewFeature { ... }  // Completely new, no foreign keys
   ```

4. **Modifying views** (UI changes don't affect data)

5. **Adding services** (business logic doesn't affect schema)

---

## ⚠️ CHANGES REQUIRING MIGRATION

**You MUST add migration for:**

1. **Adding stored properties to @Model classes**
   ```swift
   // REQUIRES MIGRATION
   var newProperty: String  // ← New stored property
   ```

2. **Changing property types**
   ```swift
   // REQUIRES MIGRATION
   var count: Int  // was String before
   ```

3. **Renaming properties**
   ```swift
   // REQUIRES MIGRATION
   var userName: String  // was 'name' before
   ```

4. **Removing properties**
   ```swift
   // REQUIRES MIGRATION
   // Removed: var oldProperty: String
   ```

5. **Adding/removing relationships**
   ```swift
   // REQUIRES MIGRATION
   @Relationship var newRelation: [OtherModel]
   ```

---

## 🔧 MIGRATION PROCESS

### **Step 1: Update DATABASE_SCHEMA.md**

Add to the "Schema Versions" section:

```markdown
### VX (Description)
**Date:** [Date]
**Changes:**
- Added `propertyName: Type` to ModelName
- Changed `propertyName` from OldType to NewType

**Migration VX-1→VX:**
- Set `propertyName = defaultValue` for existing records
```

### **Step 2: Add Repair Function to MigrationService.swift**

```swift
private static func repairVXtoVYMigration(context: ModelContext) {
    do {
        let descriptor = FetchDescriptor<ModelName>()
        let records = try context.fetch(descriptor)
        
        for record in records {
            // Check if migration needed
            if record.newProperty == defaultUnsetValue {
                print("🔧 Repairing VX→VY: Setting defaults for ModelName")
                record.newProperty = propertyDefault
                // ... set other new properties
            }
        }
        
        try context.save()
        print("✅ VX→VY migration complete")
    } catch {
        print("❌ Migration failed: \(error)")
    }
}
```

### **Step 3: Call from performStartupChecks()**

```swift
static func performStartupChecks(context: ModelContext) {
    repairRestTimerDefaults(context: context)  // V1→V2
    repairV2toV3Migration(context: context)     // V2→V3 ← ADD NEW
    // Add future migrations here
}
```

### **Step 4: Test Migration**

1. Get device with old version
2. Create test data
3. Install new version
4. Verify:
   - ✅ App launches
   - ✅ Existing data preserved
   - ✅ New properties have correct defaults
   - ✅ No crashes or errors

---

## 📝 CURRENT SCHEMA VERSION

**As of January 27, 2026:**
- **Version:** V2
- **Changes from V1:** Added rest timer properties to GlobalProgressionSettings
  - `defaultRestTime: Int`
  - `autoStartRestTimer: Bool`
  - `restTimerSound: Bool`
  - `restTimerHaptic: Bool`
- **Migration:** Handled by `repairRestTimerDefaults()` in MigrationService.swift

**Next Version Will Be:** V3

---

## 🎯 QUICK CHECKLIST

Before committing ANY model changes:

- [ ] Did I modify any @Model class?
- [ ] Did I update DATABASE_SCHEMA.md?
- [ ] Did I add a repair function to MigrationService.swift?
- [ ] Did I test the migration path?
- [ ] Did I update CRITICAL_REMINDERS.md with new version?

**If you answered YES to question 1 and NO to any other question: STOP AND FIX IT.**

---

## 🚫 NEVER DO THIS

**DO NOT:**
- ❌ Modify model files without reading this document first
- ❌ Tell users to "just delete and reinstall the app"
- ❌ Assume SwiftData will "figure it out"
- ❌ Skip testing migration paths
- ❌ Forget to document schema changes
- ❌ Add properties without setting defaults in migration
- ❌ Make breaking changes without a migration plan

---

## 📚 RELATED DOCUMENTATION

- `Docs/DATABASE_SCHEMA.md` - Complete schema documentation
- `Services/MigrationService.swift` - Migration repair functions
- `Docs/PLACEHOLDER_FEATURES.md` - Planned future changes (check for model impacts)

---

## 💡 WHEN IN DOUBT

**Ask these questions:**

1. "Does this change affect stored data?"
   - If YES → Need migration
   - If NO → Safe to proceed

2. "Could a user with the old version have this data?"
   - If YES → Need migration for existing users
   - If NO → New users only, no migration needed

3. "What happens if I install this on a device with old data?"
   - If "data is lost" or "app crashes" → Need migration
   - If "works fine" → Safe

---

## 🆘 EMERGENCY: User Data Lost

**If migration was missed and users lost data:**

1. **Immediate action:**
   - Revert the model changes
   - Restore previous version
   - Issue emergency TestFlight build

2. **Fix:**
   - Implement proper migration
   - Test thoroughly
   - Release new build with migration

3. **Communication:**
   - Apologize to affected users
   - Explain what happened
   - Provide timeline for fix

**Prevention is MUCH better than recovery.**

---

## ✅ CURRENT MIGRATION STATUS

**Implemented:**
- ✅ V1→V2: Rest timer properties (handled by `repairRestTimerDefaults()`)

**Planned:**
- ⏳ V2→V3: Strava integration (startTime, endTime, totalDuration, stravaActivityId)
- ⏳ V3→V4: User profile expansion (age, weight, height, etc.)
- ⏳ V4→V5: Apple Health sync properties

**Testing Status:**
- ⚠️ V1→V2 migration tested: PENDING (lightweight migration + repair function)

---

**END OF CRITICAL REMINDERS**

*This document is mandatory reading for all development sessions.*
*Failure to follow these rules will result in user data loss.*
