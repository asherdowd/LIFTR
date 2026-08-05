# LIFTR Release Checklist

**Use this checklist before EVERY commit, archive, and TestFlight upload.**

> **GitHub Link:** https://github.com/asherdowd/LIFTR/blob/main/RELEASE_CHECKLIST.md

---

## 📋 PRE-COMMIT CHECKLIST

**Run before `git commit`:**

### Code Changes

- [ ] **Schema Changes?** Did you modify any `@Model` classes?
  - [ ] If YES and a safe default exists for existing data: Did you add a repair function to MigrationService.swift?
  - [ ] If YES and NO safe default exists (e.g., a new required field/relationship): Did you build an interactive resolution flow instead? (See `Views/RootView.swift`/`Views/ExerciseReconciliationView.swift` for a worked example.)
  - [ ] If YES: Did you update [DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)?
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
  - [ ] Verified new properties have correct defaults (or, for interactive resolution changes, that the flow appears and resolves correctly)
  - [ ] Also tested a fresh install (no existing data) path separately

### Documentation

- [ ] **Updated [DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)?** (if models changed)
  - [ ] Incremented version number (e.g. V2 → V3)?
  - [ ] Documented changes?
  - [ ] Added migration notes?

- [ ] **Updated [CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)?** (if schema changed)
  - [ ] Updated current schema version?

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
  - [ ] **Known limitation:** the hook only detects changes under `Models/SchemaVersions/`, which does not exist on `main` (abandoned approach — see README.md "Repo History Note"). It will NOT flag real model changes in `StrengthModels.swift`, `ProgramModels.swift`, `SettingsModels.swift`, `CardioModels.swift`, or `SharedModels.swift`. Do the documentation checklist above manually regardless of what the hook reports.

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
  **Tip:** for multi-line messages, write to a temp file first and commit with `git commit -F /tmp/commit_msg.txt` rather than pasting a multi-line string directly into an interactive `-m` prompt — avoids shell quoting/hang issues with special characters.

---

## 🏗️ PRE-ARCHIVE CHECKLIST

**Run before Product → Archive:**

### Version Management

- [ ] **Incremented Build Number?**
  - [ ] Xcode → Target → General → Identity — for **both** the app target AND every extension target (e.g. `RestTimerWidgetExtension`). A mismatch between them produces an App Store Connect `CFBundleVersion` validation warning/error — this happened at Build 7 and was fixed there; don't reintroduce it.
  - [ ] Build: X → next unused number. **Never reuse a build number**, even one from an archive that failed or was never actually uploaded — if there's any doubt whether a number was already used, skip it. (Builds 8-9 are retired from the abandoned architecture refactor, and builds 10-35 were consumed by a misconfigured Xcode Cloud auto-deploy attempt — both permanently retired for this repo regardless of upload status. See README.md "Repo History Note." **Always verify the true next number directly in App Store Connect → TestFlight → Builds before assuming based on git tags alone** — git tags reflect manual archives only and will not show numbers consumed by CI auto-deploy.)

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
  # Should show: * main
  ```

- [ ] **Pushed to Remote?**
  ```bash
  git push origin main
  git push origin --tags
  ```

- [ ] **Tagged Release?**
  ```bash
  git tag -a v1.2.1-buildX -m "Release description"
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

- [ ] **Xcode Cloud workflow correct (if using it)?**
  - [ ] Project path points to the actual nested project (`IOS/LIFTR/V1.0.0/LIFTR/LIFTR.xcodeproj`), not the repo root
  - [ ] Only the intended platform archive action(s) are present (an accidental extra `Archive - macOS` action alongside `Archive - iOS` caused failed builds previously — verify only what's intended remains)

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

- [ ] **Migration Working?**
  - [ ] If a repair function: check console logs show it running, confirm defaults set correctly
  - [ ] If interactive resolution: confirm the resolution screen appears correctly on upgrade-with-existing-data, and does NOT appear on fresh install

- [ ] **Migration Path Tested?**
  - [ ] Previous build → current build tested
  - [ ] Fresh install tested separately
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
  - [ ] Organizer → Distribute App (or Xcode Cloud, if used)
  - [ ] TestFlight & App Store selected
  - [ ] Upload in progress

- [ ] **Upload Succeeded?**
  - [ ] No errors during upload
  - [ ] Confirmation message received
  - [ ] Archive marked as uploaded in Organizer
  - [ ] Check App Store Connect → TestFlight → Builds to confirm the build actually appears (don't assume from a "success" message alone — confirm the artifact actually landed)

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
  ## [Version] - Build X - YYYY-MM-DD
  
  ### Added
  - New feature 1
  
  ### Changed
  - Changed behavior 1
  
  ### Fixed
  - Bug fix 1
  
  ### Schema
  - Schema V2 → V3 (if applicable)
  ```

- [ ] **Updated [README.md](README.md)?**
  - [ ] Version number in header
  - [ ] Build number in status section
  - [ ] Schema version in technical section
  - [ ] Release date
  - [ ] Any new setup instructions

- [ ] **Tagged in Git?**
  ```bash
  git tag -a v1.2.1-buildX -m "Build X - Description"
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
  - [ ] Next unused number (never reuse, regardless of whether the broken build was actually uploaded successfully)

- [ ] **Test Thoroughly**
  - [ ] Test on device
  - [ ] Test migration if relevant
  - [ ] Test fresh install separately
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
  ## [Version] - Build X - YYYY-MM-DD
  
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
  - [ ] Increment version number (e.g. V2 → V3)
  - [ ] Document new/changed/removed properties
  - [ ] Add migration notes section
  - [ ] Update "Current Schema Version" section
  - [ ] Update relationship diagram if needed

- [ ] **[CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)**
  - [ ] Update "Current Schema Version" section
  - [ ] Update migration status section

- [ ] **[DATA_MIGRATION_POLICY.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATA_MIGRATION_POLICY.md)**
  - [ ] Update "Current Schema Status" section
  - [ ] Add new version to "Planned Future Migrations" (renumbering later planned versions if this insertion shifts them)
  - [ ] Document migration approach used (repair function vs. interactive resolution)

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

### Schema Change Rules

**For every model change:**
- Determine whether a safe universal default exists for existing data.
  - If YES → use a `MigrationService.swift` repair function.
  - If NO (e.g., a new required field/relationship with no single correct value) → build an interactive resolution flow instead (see `Views/RootView.swift`/`Views/ExerciseReconciliationView.swift`).
- Always update `Docs/DATABASE_SCHEMA.md` with the version bump and change description.
- Always test both the upgrade-with-existing-data path AND the fresh-install path.

**Note:** this repo does not use a `Models/SchemaVersions/` versioned-schema wrapper system — an earlier attempt at that approach exists only on `archive/healthkit-and-schema-attempt` and was never completed (no real migration stages implemented). Do not reference it as a working pattern.

### Git Workflow

**Before Every Commit:**
```bash
# 1. Check status
git status

# 2. Stage files
git add <specific files>   # prefer explicit paths over `git add .`

# 3. Commit (pre-commit hook will run, though see its known limitation above)
git commit -F /tmp/commit_msg.txt   # for multi-line messages; -m "..." is fine for single-line

# 4. Push to remote
git push origin <branch>
```

**Before Every Release:**
```bash
# 1. Tag the release
git tag -a v1.2.1-buildX -m "Release description"

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
5. Verify: no crash, data preserved, new features work (or, for interactive resolution changes, that the resolution flow works correctly)
6. Separately: fresh install (no existing data), verify no unnecessary resolution screens appear

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

# Does main actually contain a given commit? (verify a merge landed)
git merge-base --is-ancestor <commit-hash> main && echo "YES" || echo "NO"
```

### Check Build Number
```bash
# In Xcode, or:
grep -A 2 "CURRENT_PROJECT_VERSION" IOS/LIFTR/V1.0.0/LIFTR/LIFTR.xcodeproj/project.pbxproj
# Check EVERY match, not just the first — app target and extension targets must match
```

---

## 📞 WHEN SOMETHING GOES WRONG

### Build Won't Archive
1. Clean build folder (⌘⇧K)
2. Close and reopen Xcode
3. Check signing certificates
4. Check for errors in Issue Navigator
5. If using Xcode Cloud: verify the workflow's project path and action list are correct (see Pre-Archive checklist above)

### Migration Crashes
1. Check console logs for error
2. If using a repair function: verify it's registered in `performStartupChecks()`
3. If using interactive resolution: verify the detection query and the resolution view's linking logic
4. Test migration manually with real device data

### TestFlight Upload Fails
1. Check Apple Developer account status
2. Verify certificates not expired
3. Check app record in App Store Connect
4. Try archive validation first
5. If using Xcode Cloud, check the actual per-action build log (each archive action has its own status) rather than only the overall workflow status

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

### Build 7 Notes (Feb 12, 2026)
- Live Activity fixes, rest timer completion UX, MainView navigation fix
- This is the build actually live in TestFlight as of this writing

### Builds 8-9 Notes — Abandoned
- Attempted architecture refactor (schema versioning wrapper + Program/Progression
  restructure + HealthKit/Strava), bundled together, never reached a working state
- Learned: don't bundle a foundational model restructure with multiple new features in one
  long-running branch with no buildable checkpoints in between
- Preserved on `archive/healthkit-and-schema-attempt`, not continued

### Build 36 Notes (Jul 6, 2026, pending upload)
- Repo reset to Build 7 baseline (verified matching live TestFlight)
- Exercise identity model + relationships + interactive reconciliation flow added
- Fixed CFBundleVersion mismatch (app vs. widget extension)
- Tested: fresh install + upgrade over real existing data, both confirmed on device

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
- [ ] Migration tested (if applicable) — both upgrade and fresh-install paths
- [ ] Build tested on device
- [ ] Xcode Cloud workflow verified correct (if using it)
- [ ] Ready for beta testers

**Upload with confidence!**

---

**Last Updated:** July 6, 2026  
**Current Schema:** V3  
**Current Live Build:** 7  
**Next Build:** 36 (pending — see "Repo History Note" in README.md: builds 8-9 abandoned, builds 10-35 consumed by a misconfigured Xcode Cloud auto-deploy attempt)

---

## 🔗 Quick Links

- [README.md](README.md)
- [CHANGELOG.md](CHANGELOG.md)
- [DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)
- [CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)
- [DATA_MIGRATION_POLICY.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATA_MIGRATION_POLICY.md)
- [PLACEHOLDER_FEATURES.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/PLACEHOLDER_FEATURES.md)
- [GitHub Repository](https://github.com/asherdowd/LIFTR)
