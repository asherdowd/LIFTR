# CRITICAL REMINDERS FOR LIFTR DEVELOPMENT

**⚠️ READ THIS FIRST IN EVERY SESSION ⚠️**

---

## 🚨 RULE #1: NEVER MODIFY FROZEN SCHEMA FILES

**FROZEN FILES (Never Modify):**
- `Models/SchemaVersions/V1/` (all files)
- `Models/SchemaVersions/SchemaV1.swift`

**When SchemaV2 ships, add:**
- `Models/SchemaVersions/V2/` (all files)
- `Models/SchemaVersions/SchemaV2.swift`

**To make schema changes:**
1. Create new `SchemaVX.swift` and `VX/` folder
2. Update `CurrentSchema.swift` to point to new version
3. Update `MigrationPlan.swift` with migration stage
4. Test migration thoroughly

---

## 📋 CURRENT SCHEMA STATUS

**Version:** V1 (as of March 8, 2026)

**Location:** `Models/SchemaVersions/V1/`

**Models:** 15 total (User, GlobalProgressionSettings, ExerciseProgressionSettings, Progression, WorkoutSession, WorkoutSet, Program, TrainingDay, ProgramExercise, ExerciseSession, CardioProgression, CardioSession, PlateItem, BarItem, CollarItem)

**Next Version:** V2 (TBD)

---

## ✅ SAFE CHANGES (No Migration Needed)

- Add computed properties (not stored)
- Add methods to models
- Modify views (UI changes)
- Add services (business logic)
- Modify enums (in `Models/Enums.swift`)

---

## ⚠️ CHANGES REQUIRING MIGRATION

- Add/remove stored properties to @Model classes
- Change property types
- Rename properties
- Change relationships
- Add new @Model classes with relationships to existing models

**When making these changes:**
1. Create SchemaVX
2. Update MigrationPlan.swift
3. Update CurrentSchema.swift
4. Test on device with existing data
5. Update docs (or let pre-commit hook do it)

---

## 📋 PRE-COMMIT CHECKLIST

**Before every commit with model changes:**

- [ ] Created new SchemaVX (if needed)?
- [ ] Updated MigrationPlan.swift?
- [ ] Updated CurrentSchema.swift?
- [ ] Tested migration on device?
- [ ] Let pre-commit hook update docs

---

## 🔥 NEVER DO THIS

- ❌ Modify files in `SchemaVersions/V1/` or any frozen schema
- ❌ Skip migration testing
- ❌ Add required (non-optional) properties without migration
- ❌ Tell users to delete and reinstall
- ❌ Commit schema changes without testing on device

---

## 📚 KEY FILES

| File | Purpose |
|------|---------|
| `Models/SchemaVersions/CurrentSchema.swift` | Points to active schema (UPDATE THIS) |
| `Models/SchemaVersions/MigrationPlan.swift` | Defines migrations (UPDATE THIS) |
| `Models/SchemaVersions/VX/` | Frozen schema versions (NEVER MODIFY) |
| `Models/ModelTypealiases.swift` | Maps model names to current schema |
| `Models/Enums.swift` | Shared enums (safe to modify) |
| `Docs/DATABASE_SCHEMA.md` | Schema documentation |
| `Services/MigrationService.swift` | Migration repair functions |

---

## 💡 WHEN IN DOUBT

**Ask:**
1. "Does this change affect stored data?" → If YES, need migration
2. "Could a user with the old version have this data?" → If YES, need migration
3. "What happens if I install this on a device with old data?" → Test it!

**Default: Add optional properties and use repair functions.**

---

**Last Updated:** March 8, 2026  
**Schema:** V1
