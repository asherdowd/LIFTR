# LIFTR Data Migration Policy

**Policy:** Never break user data. Always provide migration path.

---

## 🎯 CURRENT STATUS

**Version:** V1 (as of March 8, 2026)

**Last Change:** Established versioned schema system

**Migration Status:** ✅ Baseline established

**Next Version:** V2 (TBD)

---

## 📋 MIGRATION RULES

### When to Create New Schema Version

**Required:**
- Adding/removing stored properties
- Changing property types
- Renaming properties
- Changing relationships

**Not Required:**
- Adding computed properties
- Adding methods
- UI changes
- Enum changes (in Enums.swift)

### How to Create New Version

1. **Create SchemaVX.swift:**
   - Copy previous schema structure
   - Make changes
   - Update version identifier

2. **Create VX/ folder:**
   - Copy previous V folder
   - Update model files with changes
   - Change `extension SchemaVX-1` to `extension SchemaVX`

3. **Update MigrationPlan.swift:**
   - Add SchemaVX to schemas array
   - Add migration stage VX-1→VX

4. **Update CurrentSchema.swift:**
   - Change `typealias CurrentSchema = SchemaVX`

5. **Test Migration:**
   - Install old build on device
   - Create test data
   - Install new build
   - Verify data preserved and defaults set

6. **Commit:**
   - Pre-commit hook will update docs automatically

---

## ✅ TESTING REQUIREMENTS

**Before committing schema changes:**

- [ ] Installed previous build on test device
- [ ] Created substantial test data (progressions, programs, workouts)
- [ ] Installed new build (don't delete app)
- [ ] App launched without crash
- [ ] All data preserved
- [ ] New properties have correct defaults
- [ ] Tested on physical device (not just simulator)

**If ANY test fails:** Fix before committing.

---

## 🔮 PLANNED MIGRATIONS

### V1 → V2 (Planned)
**Changes:** TBD  
**Migration:** TBD

---

## ⚠️ COMMON MISTAKES

**Don't:**
- Skip migration testing
- Add required properties without defaults
- Modify frozen schema files
- Assume SwiftData will "figure it out"

**Do:**
- Add properties as optional first
- Set defaults in migration stage
- Test with real data
- Document changes

---

## 📞 IF MIGRATION FAILS

1. **Check console** for error messages
2. **Verify MigrationPlan** includes all versions
3. **Verify CurrentSchema** points to latest
4. **Test migration manually** step by step
5. **Fix and retest** before shipping

---

**See:** `Docs/DATABASE_SCHEMA.md` for schema details  
**See:** `Docs/CRITICAL_REMINDERS.md` for development rules
