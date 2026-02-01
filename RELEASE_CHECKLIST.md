# LIFTR Release Checklist

**Use this checklist before EVERY commit, archive, and TestFlight upload.**

> **GitHub Link:** https://github.com/asherdowd/LIFTR/blob/main/RELEASE_CHECKLIST.md

---

## 📋 PRE-COMMIT CHECKLIST

**Run before `git commit`:**

### Code Changes

- [ ] **Schema Changes?** Did you modify any `@Model` classes?
  - [ ] If YES: Did you create new SchemaVX.swift file?
  - [ ] If YES: Did you update MigrationPlan.swift?
  - [ ] If YES: Did you update CurrentSchema.swift?
  - [ ] If YES: Did you add repair function to MigrationService.swift?
  - [ ] If YES: Did you update [DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)?
  - [ ] If NO: Continue

- [ ] **Frozen Files?** Did you modify any files in `Models/SchemaVersions/SchemaV*.swift`?
  - [ ] If YES: STOP! These files are frozen. Create new version instead.
  - [ ] If NO: Continue

- [ ] **New Files Created?** Did you create any new Swift files?
  - [ ] Added to Xcode project?
  - [ ] In correct folder (Views/, Models/, Services/, etc.)?
  - [ ] File targets set correctly (LIFTR target checked)?

- [ ] **Settings Changes?** Did you add properties to GlobalProgressionSettings?
  - [ ] Added UI in settings views?
  - [ ] Added to appropriate settings section?
  - [ ] Defaults set in init()?
  - [ ] Migration handles existing users?

- [ ] **Build Succeeds?**
  - [ ] Clean build (⌘⇧K, then ⌘B)
  - [ ] No warnings?
  - [ ] No errors?

### Testing

- [ ] **Ran on Simulator?**
  - [ ] App launches without crash?
  - [ ] New features work?
  - [ ] Existing features still work?

- [ ] **Ran on Physical Device?**
  - [ ] App launches?
  - [ ] Tested new features?
  - [ ] Checked console for errors?

- [ ] **Migration Tested?** (if schema changed)
  - [ ] Installed previous build on test device
  - [ ] Created test data
  - [ ] Installed new build
  - [ ] Verified data preserved
  - [ ] Verified new properties have correct defaults

### Documentation

- [ ] **Updated [DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)?** (if models changed)
  - [ ] Incremented version number (V2 → V3)?
  - [ ] Documented changes?
  - [ ] Added migration notes?

- [ ] **Updated [CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)?** (if schema changed)
  - [ ] Updated current schema version?
  - [ ] Updated frozen files list?

- [ ] **Updated [PLACEHOLDER_FEATURES.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/PLACEHOLDER_FEATURES.md)?** (if implemented placeholder)
  - [ ] Removed from placeholder list?
  - [ ] Moved to completed features?

- [ ] **Code Comments?**
  - [ ] Complex logic explained?
  - [ ] TODOs marked if incomplete?

### Git

- [ ] **Staged All Files?**
  ```bash
  git status
  # Should show files you intend to commit
  ```

- [ ] **Pre-commit Hook Passes?**
  - [ ] Hook doesn't block commit?
  - [ ] If blocked, did you complete required steps?

- [ ] **Commit Message Follows Format?**
  ```
  feat: Brief description (under 72 chars)
  
  Detailed explanation:
  - What changed
  - Why it changed
  - Any breaking changes
  
  Files modified: X
  Files created: Y
  Testing: Completed on device
  ```

---

## 🏗️ PRE-ARCHIVE CHECKLIST

**Run before Product → Archive:**

### Version Management

- [ ] **Incremented Build Number?**
  - [ ] Xcode → Target → General → Identity
  - [ ] Build: X → X+1
  - [ ] Example: Build 6 → Build 7

- [ ] **Version Number Correct?**
  - [ ] Major release? Increment major (1.0.0 → 2.0.0)
  - [ ] Minor release? Increment minor (1.2.0 → 1.3.0)
  - [ ] Patch release? Increment patch (1.2.1 → 1.2.2)

### Code State

- [ ] **All Changes Committed?**
  ```bash
  git status
  # Should say: "nothing to commit, working tree clean"
  ```

- [ ] **On Correct Branch?**
  ```bash
  git branch
  # Should show: * main (or release branch)
  ```

- [ ] **Pushed to Remote?**
  ```bash
  git push origin main
  git push origin --tags
  ```

- [ ] **Tagged Release?**
  ```bash
  git tag -a v1.2.1 -m "Release v1.2.1 - Feature description"
  git push origin --tags
  ```

### Build Configuration

- [ ] **Build Configuration = Release?**
  - [ ] Product → Scheme → Edit Scheme
  - [ ] Archive → Build Configuration = Release
  - [ ] NOT Debug

- [ ] **Signing Certificate Valid?**
  - [ ] Xcode → Signing & Capabilities
  - [ ] Team selected
  - [ ] Certificate not expired
  - [ ] Provisioning profile valid

- [ ] **Target Device = Any iOS Device?**
  - [ ] Not simulator
  - [ ] Not specific device

### Testing

- [ ] **Clean Build Succeeds?**
  ```
  Product → Clean Build Folder (⌘⇧K)
  Product → Build (⌘B)
  ```

- [ ] **No Debug Code Left?**
  - [ ] No `print()` statements (or only intentional logging)
  - [ ] No commented-out code blocks
  - [ ] No test data hardcoded

- [ ] **Run on Device One More Time?**
  - [ ] Verify app works
  - [ ] Check console for warnings
  - [ ] Test critical user flows

### Migration Prep (if schema changed)

- [ ] **Migration Service Working?**
  - [ ] Check console logs show migration running
  - [ ] Verify repair functions execute
  - [ ] Confirm defaults set correctly

- [ ] **Migration Path Tested?**
  - [ ] Previous build → current build tested
  - [ ] No crashes
  - [ ] No data loss

---

## 🚀 PRE-TESTFLIGHT UPLOAD CHECKLIST

**Run after Archive succeeds, before uploading:**

### Archive Validation

- [ ] **Archive Succeeded?**
  - [ ] Organizer window opened
  - [ ] New archive appears in list
  - [ ] Archive size reasonable (not 10x larger than previous)

- [ ] **Archive Validated?**
  - [ ] Organizer → Validate App
  - [ ] No errors
  - [ ] No critical warnings

### Release Notes Prepared

- [ ] **Created Release Notes?**
  ```
  Build X (vX.X.X) - Date
  
  NEW FEATURES
  - Feature 1
  - Feature 2
  
  IMPROVEMENTS
  - Improvement 1
  
  TECHNICAL
  - Technical change 1
  
  PLEASE TEST
  1. Test item 1
  2. Test item 2
  
  KNOWN ISSUES
  - Known issue 1
  
  FEEDBACK
  Report issues via Settings → Report an Issue
  ```

- [ ] **Release Notes in Plain Text?**
  - [ ] No emojis (unless requested)
  - [ ] Clear formatting
  - [ ] Under 4000 characters

### App Store Connect Prep

- [ ] **Logged into App Store Connect?**
  - [ ] https://appstoreconnect.apple.com
  - [ ] Correct Apple ID
  - [ ] Correct team selected

- [ ] **App Record Exists?**
  - [ ] App listed in App Store Connect
  - [ ] TestFlight section accessible

### Upload

- [ ] **Upload Started?**
  - [ ] Organizer → Distribute App
  - [ ] TestFlight & App Store selected
  - [ ] Upload in progress

- [ ] **Upload Succeeded?**
  - [ ] No errors during upload
  - [ ] Confirmation message received
  - [ ] Archive marked as uploaded in Organizer

---

## 📱 POST-UPLOAD CHECKLIST

**Run after upload completes:**

### App Store Connect Verification

- [ ] **Build Appears in App Store Connect?**
  - [ ] TestFlight → Builds
  - [ ] New build listed
  - [ ] Status: "Processing" or "Ready to Test"

- [ ] **Wait for Processing?**
  - [ ] Usually 10-30 minutes
  - [ ] Check email for processing completion
  - [ ] Status changes to "Ready to Test"

- [ ] **Add Release Notes?**
  - [ ] TestFlight → Build X → Test Details
  - [ ] Paste release notes
  - [ ] Save

- [ ] **Enable for Testing?**
  - [ ] Add to Internal Testing group
  - [ ] Add to External Testing group (if ready)
  - [ ] Notify testers

### Testing

- [ ] **Install from TestFlight?**
  - [ ] On your device
  - [ ] On tester devices
  - [ ] Clean install (delete previous version first)

- [ ] **Verify Build Works?**
  - [ ] App launches
  - [ ] New features present
  - [ ] No crashes

- [ ] **Check Crash Reports?**
  - [ ] Xcode → Organizer → Crashes
  - [ ] App Store Connect → TestFlight → Crashes
  - [ ] Monitor for first 24 hours

### Documentation

- [ ] **Updated CHANGELOG.md?**
  ```markdown
  ## [1.2.1] - 2026-01-27
  
  ### Added
  - Rest timer system
  - Schema versioning
  
  ### Changed
  - Split settings views
  
  ### Fixed
  - Migration crash on upgrade
  ```

- [ ] **Updated [README.md](README.md)?**
  - [ ] Current version number updated
  - [ ] Current build number updated
  - [ ] Schema version updated (if changed)

- [ ] **Tagged in Git?**
  ```bash
  git tag -a v1.2.1 -m "Build 7 - Rest Timer & Migration"
  git push origin --tags
  ```

---

## 🔥 EMERGENCY ROLLBACK CHECKLIST

**If build has critical bug after upload:**

### Immediate Actions

- [ ] **Document the Issue**
  - [ ] What's broken?
  - [ ] Steps to reproduce
  - [ ] How many users affected?
  - [ ] Screenshots/crash logs

- [ ] **Disable Build in TestFlight**
  - [ ] App Store Connect → TestFlight
  - [ ] Select broken build
  - [ ] Expire for testing

- [ ] **Notify Testers**
  - [ ] Email/message testers
  - [ ] Explain issue
  - [ ] ETA for fix

### Fix & Re-release

- [ ] **Revert or Fix Code**
  ```bash
  git revert <commit-hash>
  # or fix the bug
  ```

- [ ] **Increment Build Number**
  - [ ] Build X+1 (never reuse build numbers)

- [ ] **Test Thoroughly**
  - [ ] Test on device
  - [ ] Test migration if relevant
  - [ ] Verify fix works

- [ ] **Upload New Build**
  - [ ] Follow Pre-Archive checklist again
  - [ ] Upload to TestFlight
  - [ ] Test thoroughly before enabling

---

## 📚 DOCUMENTATION UPDATES CHECKLIST

**These files MUST be updated for certain types of changes:**

### Always Update (Every Release)

- [ ] **CHANGELOG.md** (Repository root)
  ```markdown
  ## [Version] - YYYY-MM-DD
  
  ### Added
  - New feature 1
  
  ### Changed
  - Changed behavior 1
  
  ### Fixed
  - Bug fix 1
  
  ### Schema
  - Schema V2 → V3 (if applicable)
  ```

- [ ] **[README.md](README.md)** (Repository root)
  - [ ] Version number in header
  - [ ] Build number in status section
  - [ ] Schema version in technical section
  - [ ] Release date
  - [ ] Any new setup instructions

### When Models Change

- [ ] **[DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)**
  - [ ] Increment version number (V2 → V3)
  - [ ] Document new/changed/removed properties
  - [ ] Add migration notes section
  - [ ] Update "Current Schema Version" section
  - [ ] Update relationship diagram if needed

- [ ] **[CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)**
  - [ ] Update "Current Schema Version" section
  - [ ] Add new frozen file to list (e.g., SchemaV2.swift)
  - [ ] Update migration status section

- [ ] **[DATA_MIGRATION_POLICY.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATA_MIGRATION_POLICY.md)**
  - [ ] Update "Current Schema Status" section
  - [ ] Add new version to "Planned Future Migrations"
  - [ ] Document migration approach used

### When Implementing Placeholder Features

- [ ] **[PLACEHOLDER_FEATURES.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/PLACEHOLDER_FEATURES.md)**
  - [ ] Move feature from "Unimplemented" to "Completed"
  - [ ] Add implementation date
  - [ ] Add files created/modified
  - [ ] Remove from placeholder list if fully complete

### Documentation File Locations

```
Repository Root:
├── README.md                              ← Project overview
├── CHANGELOG.md                           ← Version history
├── RELEASE_CHECKLIST.md                   ← This file
└── IOS/LIFTR/V1.0.0/LIFTR/
    └── Docs/
        ├── DATABASE_SCHEMA.md             ← Model documentation
        ├── CRITICAL_REMINDERS.md          ← Development rules
        ├── DATA_MIGRATION_POLICY.md       ← Migration procedures
        └── PLACEHOLDER_FEATURES.md        ← Feature tracking
```

---

## ⚠️ CRITICAL REMINDERS

### Schema Versioning Rules

**FROZEN FILES (Never Modify):**
- `Models/SchemaVersions/SchemaV1.swift` (Build 7, shipped)
- `Models/SchemaVersions/SchemaV2.swift` (Build 8, when shipped)
- Add to list as new versions ship

**ALWAYS UPDATE:**
- `Models/SchemaVersions/CurrentSchema.swift` (points to latest)
- `Models/SchemaVersions/MigrationPlan.swift` (add new stages)
- `Services/MigrationService.swift` (add repair functions)

### Git Workflow

**Before Every Commit:**
```bash
# 1. Check status
git status

# 2. Stage files
git add .

# 3. Commit (pre-commit hook will run)
git commit -m "feat: Description"

# 4. Push to remote
git push origin main
```

**Before Every Release:**
```bash
# 1. Tag the release
git tag -a v1.2.1 -m "Release v1.2.1 - Feature description"

# 2. Push tags
git push origin --tags
```

### Migration Testing Requirements

**MUST test migration if ANY of these changed:**
- Added property to @Model class
- Removed property from @Model class
- Changed property type
- Renamed property
- Changed relationship

**Test procedure:**
1. Install previous build on device
2. Create substantial test data
3. Install new build over old build (don't delete)
4. Launch app
5. Verify: no crash, data preserved, new features work

---

## 📋 QUICK REFERENCE: WHAT TO UPDATE WHEN

| Change Type | README | CHANGELOG | SCHEMA | CRITICAL | POLICY | PLACEHOLDER |
|-------------|--------|-----------|--------|----------|--------|-------------|
| **New Feature** | ✓ | ✓ | - | - | - | Maybe |
| **Bug Fix** | - | ✓ | - | - | - | - |
| **Model Change** | ✓ | ✓ | ✓ | ✓ | ✓ | - |
| **Version Bump** | ✓ | ✓ | - | - | - | - |
| **Build Upload** | ✓ | ✓ | - | - | - | - |
| **Implement Placeholder** | ✓ | ✓ | Maybe | - | - | ✓ |

---

## 🎯 BUILD-SPECIFIC CHECKLISTS

### Build 7 Checklist (Current - Schema V1 Wrapper)

- [ ] Created SchemaV1.swift with all 15 models
- [ ] No functional changes from Build 6
- [ ] Testing: Upgrade from Build 6 works
- [ ] Release notes: "Infrastructure update - no visible changes"

### Build 8 Checklist (Future - Schema V2 with Rest Timer)

- [ ] Created SchemaV2.swift
- [ ] Updated MigrationPlan.swift
- [ ] Updated CurrentSchema.swift
- [ ] Added MigrationService repair function
- [ ] Testing: Upgrade from Build 7 works
- [ ] Release notes: Document rest timer feature

### Future Builds

- [ ] Always increment schema version if models change
- [ ] Always test migration from previous build
- [ ] Always update all relevant documentation

---

## 🔍 VERIFICATION COMMANDS

### Check Git State
```bash
# Am I on the right branch?
git branch

# Are all changes committed?
git status

# What's the latest commit?
git log -1

# Are there uncommitted changes?
git diff

# Are tags pushed?
git tag
```

### Check Schema Version
```bash
# Search for current schema version
grep -r "versionIdentifier" Models/SchemaVersions/

# Check which schema is current
grep "typealias CurrentSchema" Models/SchemaVersions/CurrentSchema.swift
```

### Check Build Number
```bash
# In Xcode, or:
grep -A 2 "CURRENT_PROJECT_VERSION" *.xcodeproj/project.pbxproj
```

---

## 📞 WHEN SOMETHING GOES WRONG

### Build Won't Archive
1. Clean build folder (⌘⇧K)
2. Close and reopen Xcode
3. Check signing certificates
4. Check for errors in Issue Navigator

### Migration Crashes
1. Check console logs for error
2. Verify SchemaVersions are correct
3. Verify MigrationPlan includes all versions
4. Test migration manually

### TestFlight Upload Fails
1. Check Apple Developer account status
2. Verify certificates not expired
3. Check app record in App Store Connect
4. Try archive validation first

### Users Report Data Loss
1. EMERGENCY: Stop recommending update
2. Document issue
3. Check migration code
4. Test on fresh device
5. Prepare hotfix build

---

## 📝 NOTES SECTION

**Use this space to track build-specific notes:**

### Build 6 Notes (Jan 27, 2026)
- First attempt at rest timer
- User crash reported (no schema versioning)
- Learned: Always version schemas from the start

### Build 7 Notes (TBD)
- Wrapping existing models in SchemaV1
- No functional changes
- Foundation for future migrations

---

## ✅ FINAL PRE-UPLOAD CHECKLIST

**Before clicking "Upload to App Store":**

- [ ] All checklists above completed
- [ ] Git committed and pushed
- [ ] Git tagged
- [ ] README.md updated
- [ ] CHANGELOG.md updated
- [ ] Schema docs updated (if applicable)
- [ ] Release notes written
- [ ] Migration tested (if applicable)
- [ ] Build tested on device
- [ ] Ready for beta testers

**Upload with confidence!**

---

**Last Updated:** January 31, 2026  
**Current Schema:** V2  
**Current Build:** 6  
**Next Build:** 7

---

## 🔗 Quick Links

- [README.md](README.md)
- [CHANGELOG.md](CHANGELOG.md)
- [DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)
- [CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)
- [DATA_MIGRATION_POLICY.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATA_MIGRATION_POLICY.md)
- [PLACEHOLDER_FEATURES.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/PLACEHOLDER_FEATURES.md)
- [GitHub Repository](https://github.com/asherdowd/LIFTR)
