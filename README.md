# LIFTR - Strength Training Tracker

Progressive overload tracking app for iOS with intelligent progression algorithms and automated workout planning.

## ⚠️ CRITICAL: Data Migration

**NEVER modify `@Model` classes without following migration procedures.**

See `Docs/CRITICAL_REMINDERS.md` for mandatory guidelines.

**Current Schema:** V3 (Exercise Identity Relationships - July 6, 2026)

---

## 📱 Overview

LIFTR is an iOS strength training app that helps users track progressive overload through:
- **Intelligent Progressions:** Linear, periodization, RPE-based, and percentage-based
- **Program Templates:** Starting Strength, Texas Method, Madcow 5×5, 5/3/1 (Wendler)
- **Workout Tracking:** Sets, reps, weight, RPE with auto-progression
- **Rest Timer:** Configurable rest periods with haptic feedback
- **Plate Calculator:** Automatic plate loading calculations
- **Analytics:** Progress tracking, volume charts, PR history

---

## 🏗️ Project Structure

```
LIFTRSwift/
├── IOS/
│   └── LIFTR/
│       └── V1.0.0/
│           └── LIFTR/
│               ├── LIFTR/                    # Source code
│               │   ├── Models/               # SwiftData models (⚠️ migration required)
│               │   ├── Views/                # SwiftUI views
│               │   │   ├── Home/
│               │   │   ├── Progression/
│               │   │   ├── Program/
│               │   │   ├── Workouts/
│               │   │   ├── Cardio/
│               │   │   ├── Inventory/
│               │   │   ├── Analytics/
│               │   │   ├── Settings/
│               │   │   └── Shared/
│               │   ├── Services/             # Business logic
│               │   └── Utilities/            # Helper functions
│               ├── Docs/                     # Documentation
│               │   ├── DATABASE_SCHEMA.md
│               │   ├── CRITICAL_REMINDERS.md
│               │   ├── DATA_MIGRATION_POLICY.md
│               │   └── PLACEHOLDER_FEATURES.md
│               └── LIFTR.xcodeproj
├── README.md                                 # This file
└── .gitignore
```

---

## 📚 Documentation

### Core Documentation
- **[DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)** - Complete model documentation
- **[CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)** - Mandatory development rules
- **[DATA_MIGRATION_POLICY.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATA_MIGRATION_POLICY.md)** - Migration procedures
- **[PLACEHOLDER_FEATURES.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/PLACEHOLDER_FEATURES.md)** - Unimplemented features

### Quick Reference
- **Models:** SwiftData models (GlobalProgressionSettings, ExerciseProgressionSettings, Progression, Program, WorkoutSession, Exercise, etc.) — see DATABASE_SCHEMA.md for the full list
- **Schema Version:** V3 (Exercise identity relationships)
- **TestFlight:** Active (Build 7 live; see project tracker for in-progress work toward the next build)
- **Branch:** `main`
- **Project Tracking:** GitHub Issues + Milestones (`Backlog` milestone; labels `initiative:*` group work by theme) — replaces the old Milestone 1-10 numbering below, which is no longer maintained

---

## 🚀 Current Status

**Version:** 1.2.1 (Build 7 — live in TestFlight)
**Repo Baseline:** `main` matches TestFlight Build 7 exactly (verified July 6, 2026 repo cleanup — see "Repo History Note" below)

### ✅ Completed (on top of Build 7 baseline, merged to `main`, not yet uploaded to TestFlight)
- **Exercise identity model** (`Exercise`, `ExerciseCoreType`) — canonical exercise identity, independent model, no migration required
- **Exercise relationships** added to Progression, ProgramExercise, ExerciseProgressionSettings, CardioProgression (legacy `exerciseName` fields retained, not removed)
- **Interactive reconciliation flow** (`RootView` + `ExerciseReconciliationView`) — handles migrating existing free-text exercise names to the new model, since no safe automatic default exists for required categorization. Tested on device: fresh install (no screen shown) and upgrade over real existing data (screen shown, resolved correctly, does not reappear).
- **Fixed** `CFBundleVersion` mismatch between app and widget extension targets

### ⏳ In Progress
See the GitHub issue tracker (`Backlog` milestone) for current work. As of this writing: settings redesign (#8) under discussion, Exercise preset/picker UI (#12) and Program/Progression model merge (#4) queued next.

### 📋 Known Gaps (confirmed by code inspection, not yet fixed)
- **Current PR Totals** on the main view only reads from Progression data, not Program-based training — users who only run Programs see 0 for all PRs (tracked as issue #3, blocked by the Program/Progression merge)
- **Per-exercise settings overrides** (`ExerciseProgressionSettings.useCustomRules`, custom deload %, etc.) are fully editable in Settings but never actually read by the deload/adjustment logic — the feature is currently non-functional (tracked as issue #8)
- **Program and Progression** are separate, overlapping model hierarchies with duplicated deload/adjustment logic (Program path has none at all) — tracked as issue #4

### Repo History Note
On July 6, 2026, the repo was reset to match the actual live TestFlight build (Build 7) as its baseline. A prior architecture refactor attempt (schema versioning + HealthKit integration, targeting what would have been Builds 8-9) was found to be non-working and was preserved for reference on `archive/healthkit-and-schema-attempt` rather than continued. `main` now equals Build 7 plus the Exercise identity work above.

**Build number gap (8-37):** separately, Xcode Cloud automatic-deploy was misconfigured in several ways over time: pointed at the wrong project path, included an unintended macOS archive action, and — critically — remained set to automatically upload to TestFlight on every push to `main`, with no manual approval step. Builds 10-34 were consumed by earlier broken attempts (project path/action issues, never completed). After those were fixed, the auto-upload itself was still active: pushing the manual `CURRENT_PROJECT_VERSION = 36` commit for this same work triggered Xcode Cloud to auto-archive and upload on its own internal version counter, landing on build 37 (ignoring the git-tracked "36" entirely) — App Store Connect confirms builds 35, 36, AND 37 all completed successfully via this auto-upload, unrelated to the manual number in git. The workflow's Distribution Preparation has now been set to "None" and the workflow disabled entirely, so this should not recur. Per Apple's actual constraint, a build number can never be reused once App Store Connect has any record of it, successful or not, regardless of which tool produced it — so the next real, intentional build is **38**. The `v1.2.1-build36` git tag was deleted since it no longer reliably corresponds to what's actually in TestFlight as build 36.

---

## 🎯 Key Features

### Progression Tracking
- **Linear Progression:** Consistent weight increases
- **Periodization:** Wave loading (light/medium/heavy weeks)
- **RPE-Based:** Rate of Perceived Exertion tracking
- **Percentage-Based:** Training at % of 1RM

### Program Templates
- **Starting Strength:** 3x/week linear progression for beginners
- **Texas Method:** Intermediate weekly progression
- **Madcow 5×5:** Ramping sets with weekly progression
- **5/3/1 (Wendler):** Wave periodization with deloads

### Workout Features
- Auto-calculated weights based on progression
- Set-by-set logging with actual weight/reps
- RPE tracking (optional)
- Rest timer with configurable duration
- Haptic feedback and sound notifications
- Mid-workout adjustments
- Performance-based auto-adjustments (Progression path only — see Known Gaps above)

### Equipment Management
- Plate inventory tracking
- Bar inventory (Olympic, specialty bars)
- Collar tracking
- Plate loading calculator with available equipment

### Analytics
- Progress charts
- Volume tracking
- PR history (Progression-based data only — see Known Gaps above)
- Workout frequency
- Performance trends

---

## 🛠️ Development Rules

### Before Modifying Models

**MANDATORY steps when changing any `@Model` class:**

1. **Read** `Docs/CRITICAL_REMINDERS.md`
2. **Update** `Docs/DATABASE_SCHEMA.md` with version bump
3. **Add migration** to `Services/MigrationService.swift` if a safe default exists for existing data, OR build an interactive resolution flow (see `Views/RootView.swift`/`Views/ExerciseReconciliationView.swift` for a worked example) if no safe default exists
4. **Test migration** with existing data on device, AND test a fresh install (no existing data) path
5. **Update** this README with new schema version

**Failure to follow these steps = USER DATA LOSS**

### Schema Versions

| Version | Date | Changes | Migration |
|---------|------|---------|-----------|
| **V1** | Jan 1-26, 2026 | Original schema | N/A |
| **V2** | Jan 27, 2026 (rest timer); July 6, 2026 (Exercise model added, no relationships yet) | Added rest timer properties to GlobalProgressionSettings; added independent Exercise model | ✅ MigrationService (rest timer) / No migration needed (Exercise model) |
| **V3** | July 6, 2026 | Added `exercise: Exercise?` relationship to Progression, ProgramExercise, ExerciseProgressionSettings, CardioProgression | ✅ Interactive resolution (`RootView`/`ExerciseReconciliationView`), not a repair function |
| **V4** | Planned | Strava integration (startTime, endTime, totalDuration) | ⏳ Pending |
| **V5** | Planned | User profile expansion (age, weight, height) | ⏳ Pending |

### Current Schema (V3)

**Changed Models (this session):**
- `Exercise` (new): `id`, `name`, `coreType: ExerciseCoreType` (required, no safe default)
- `Progression`, `ProgramExercise`, `ExerciseProgressionSettings`, `CardioProgression`: added `exercise: Exercise?` (legacy `exerciseName` retained, not removed)

**Migration:** No MigrationService repair function used for the V2→V3 relationship additions — handled by interactive resolution (`RootView` detects unresolved legacy names, routes to `ExerciseReconciliationView` instead of `ContentView` until the user assigns a `coreType` to each). See `Docs/DATA_MIGRATION_POLICY.md` for the full pattern.

---

## 💻 Setup & Installation

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- macOS 14.0+ (for development)
- Swift 5.9+

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/asherdowd/LIFTR.git
   cd LIFTR
   ```

2. **Open in Xcode:**
   ```bash
   open IOS/LIFTR/V1.0.0/LIFTR/LIFTR.xcodeproj
   ```

3. **Select target:**
   - Product → Destination → iPhone (your device or simulator)

4. **Build and run:**
   - Press `⌘R` or Product → Run

### First Launch
- App will create default settings
- Sample inventory items can be added
- Create your first progression or program to start tracking
- If upgrading from a build with existing exercise data, you'll see a one-time "Confirm your exercises" screen (see V3 schema notes above)

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Create progression and log workouts
- [ ] Create program and complete sessions
- [ ] Test rest timer functionality
- [ ] Verify plate calculator with custom inventory
- [ ] Test settings changes persist
- [ ] Test migration path (install old build, upgrade to new)
- [ ] Test fresh install path (no existing data) separately from the upgrade path

### Migration Testing (CRITICAL)
1. Install previous TestFlight build
2. Create substantial test data (progressions, workouts, programs)
3. Install new build with model changes
4. Verify:
   - [ ] App launches without crash
   - [ ] All data is preserved
   - [ ] New properties have correct defaults (or, for interactive-resolution changes, that the resolution screen appears correctly and resolves as expected)
   - [ ] Relationships intact
5. Separately, test a fresh install (no existing data) to confirm no unnecessary resolution screens appear

### Known Issues
- SwiftUI sheet dismissal bug with double presentations (workaround implemented)
- Metric unit toggle exists but conversion not implemented
- Current PR Totals only reflects Progression-based data (see "Known Gaps" above)
- Per-exercise settings overrides are non-functional (see "Known Gaps" above)

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Make changes following migration policy
3. Test thoroughly on device
4. Update documentation
5. Create pull request, merge into `main`

### Code Style
- SwiftUI for all views
- SwiftData for persistence
- MVVM-like architecture
- Descriptive variable names
- Comment complex logic

### Git Hooks
Pre-commit hook checks for schema changes:
```bash
# Install hook (one-time setup)
chmod +x .git/hooks/pre-commit
```

**Known limitation:** the hook currently only detects changes under `Models/SchemaVersions/`, a directory that does not exist on `main` (it was part of an earlier, abandoned schema-versioning approach — see "Repo History Note" above). It will NOT flag changes to the actual model files (`StrengthModels.swift`, `ProgramModels.swift`, `SettingsModels.swift`, `CardioModels.swift`, `SharedModels.swift`). Documentation updates for model changes are currently a manual step — follow `Docs/CRITICAL_REMINDERS.md` and `RELEASE_CHECKLIST.md` directly rather than relying on the hook to catch this.

---

## 📦 Dependencies

### Built-in Frameworks
- SwiftUI (UI framework)
- SwiftData (persistence)
- Charts (analytics visualization)
- PhotosUI (screenshot uploads)
- AVFoundation (rest timer sound)

### No External Dependencies
- All functionality built with native iOS frameworks
- No CocoaPods or SPM packages required

---

## 🚢 Releases

### Version Numbering
- **Major.Minor.Patch** (e.g., 1.2.1)
- **Build Number** (incremental, e.g., Build 7) — never reused, even for abandoned/failed builds (Builds 8 and 9 were assigned to now-abandoned work and are permanently retired; the next real build is 10)

### Release Process
1. Update version in Xcode project (both the app target AND any extension targets — see `CRITICAL_REMINDERS.md` re: the Build 7 `CFBundleVersion` mismatch bug for why this matters)
2. Update `CHANGELOG.md`
3. Test migration path AND fresh-install path
4. Create TestFlight build
5. Submit for external testing
6. Monitor crash reports

### TestFlight
- **Current Live Build:** 7 (v1.2.1)
- **Status:** Active testing
- **Testers:** Internal + external beta
- **CI:** Xcode Cloud, triggered on push to `main`. As of July 2026, the workflow's project path and actions list were corrected after being found misconfigured (pointing at the repo root instead of the actual nested project path, and including an unintended macOS archive action) — see git/App Store Connect history for details.

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history. Note: there is a known numbering discrepancy between CHANGELOG.md's historical entries and the actual git tags (e.g., CHANGELOG's most recent "Build 6" entry corresponds to the work in git tag `v1.2.1-build7`) — this is flagged in CHANGELOG.md directly rather than silently corrected, since reconciling old history with confidence isn't possible from the available records.

---

## 🐛 Known Issues & Limitations

### Current Limitations
- ❌ Metric units toggle exists but conversion not implemented
- ❌ Apple Health integration not implemented — a prior working implementation (`HealthKitService.swift`) exists on `archive/healthkit-and-schema-attempt` but depends on model properties not present on `main`; deliberately deferred until after the Program/Progression merge to avoid redoing the work
- ❌ Strava integration not implemented (placeholder only)
- ❌ User profile basic (no body measurements, photos)
- ❌ Progression recalculation button non-functional (TODO)
- ❌ Support form doesn't submit (no backend)
- ❌ Current PR Totals only reflects Progression-based data, not Program-based (tracked, see Known Gaps above)
- ❌ Per-exercise settings overrides are non-functional (tracked, see Known Gaps above)

### Planned Features
See `Docs/PLACEHOLDER_FEATURES.md` and the GitHub issue tracker for the complete, current list.

---

## 📄 License

[Your License Here]

---

## 👥 Authors

- **Seth Dowd** - Initial work and development

---

## 🙏 Acknowledgments

- SwiftUI and SwiftData frameworks by Apple
- Program templates based on proven strength training methodologies:
  - Starting Strength by Mark Rippetoe
  - Texas Method by Mark Rippetoe and Glenn Pendlay
  - Madcow 5×5 by Bill Starr (adapted by Madcow)
  - 5/3/1 by Jim Wendler

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/asherdowd/LIFTR/issues)
- **Email:** support@liftrapp.com
- **TestFlight:** Join beta testing program

---

## 🔒 Privacy

- All data stored locally on device
- No account required
- No data sent to servers
- Optional iCloud backup (planned)
- Optional third-party integrations (Strava, Apple Health) with explicit user consent

---

**Last Updated:** July 6, 2026  
**Schema Version:** V3  
**Build:** 7 (v1.2.1) — repo `main` also includes unreleased Exercise identity work pending upload as Build 38 (not 10 or 36 — see "Repo History Note" below)
