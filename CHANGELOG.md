# Changelog

All notable changes to LIFTR will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Known numbering discrepancy:** entries below "Build 6" (2026-01-27, rest timer) do not
> line up cleanly with the actual git tags. The live TestFlight build containing that same
> rest timer work is tagged `v1.2.1-build7` in git, not build 6. This gap is not reconciled
> retroactively here — old entries are left as originally written rather than guessed at.
> Starting with the entry below for the actual `v1.2.1-build7` tag, changelog entries are
> written to match git tags exactly.

---

## [Unreleased]

### In Progress
- Settings redesign: wiring up per-exercise deload overrides, which currently exist in the
  UI/model but are never read by the actual deload logic (tracked as issue #8)

### Planned (see GitHub issue tracker for current, authoritative status)
- Seed Exercise model with common presets + replace free-text entry with a picker (issue #12)
- Merge Program and Progression into one model hierarchy (issue #4)
- Fix Current PR Totals to include Program-based training, not just Progression (issue #3)

---

## [1.2.1] - Build 7 - 2026-02-12

### Added
- (Retroactive entry — this build's actual content, per git tag `v1.2.1-build7`)
- Live Activity pause/resume fix (timer no longer counts down when paused)
- Progress bar fix across all states (running, paused, completed)
- REST COMPLETE state with Complete Rest button
- onComplete callback dismisses LogSetView after rest

### Fixed
- Complete button not visible from MainView Upcoming Workouts
- TimeButton taps in rest timer settings
- Removed debug print statements

### Technical
- Files modified: RestTimer.swift, LogSetView.swift, MainView.swift, WorkoutsView.swift, RestTimerAttributes.swift, RestTimerWidgetLiveActivity.swift
- Tested on device

---

## [Unreleased — repo history note] - Builds 8-9 - Abandoned

Builds 8 and 9 (tags `v1.2.1-build8`, `v1.2.1-build9`) were attempted but the underlying
architecture refactor (schema versioning wrapper + Program/Progression restructure +
HealthKit/Strava integration, all bundled together) was never completed to a working state.
Build 9 in particular was non-working when development on it was paused. This work was
preserved for reference on `archive/healthkit-and-schema-attempt` (not merged into `main`)
during a July 6, 2026 repo cleanup, rather than continued or discarded outright. Build
numbers 8 and 9 are retired and will not be reused. See README.md "Repo History Note" for
more detail.

**Salvageable from this line:** `HealthKitService.swift` (working HealthKit export logic,
not yet wired into `main` — depends on model properties not present there).
**Not salvageable:** the schema-versioning wrapper (`SchemaV1.swift`/`MigrationPlan.swift`)
had zero real migration stages implemented — scaffolding only.

---

## [Unreleased — repo history note] - Builds 10-37 - Consumed by Xcode Cloud misconfiguration

Build numbers 10 through 37 were consumed unintentionally by a misconfigured Xcode Cloud
workflow, not by any intended release. Builds 10-34: the workflow's project path pointed at
the repo root instead of the actual nested `.xcodeproj`, and an unintended `Archive - macOS`
action was present alongside `Archive - iOS`; these were fixed on 2026-07-06. However, the
workflow's `Archive - iOS` action was still configured with Distribution Preparation set to
"TestFlight (Internal Testing Only)" — meaning it auto-uploads on every push to `main`, with
no manual approval step. As a result, pushing the manual `CURRENT_PROJECT_VERSION = 36`
commit for this same Build 38 work triggered an automatic archive+upload on Xcode Cloud's own
internal version counter, which does not read from git at all — landing on build 37 (skipping
past the manually-set 36). App Store Connect confirms builds 35, 36, and 37 all completed
successfully via this auto-upload path, entirely disconnected from the git-tracked build
number. The workflow's Distribution Preparation has been set to "None" and the workflow
disabled entirely as of 2026-07-06 to prevent recurrence. The `v1.2.1-build36` git tag was
deleted, since it no longer reliably corresponds to what TestFlight actually has as build 36.

**Lesson:** when using any CI auto-deploy tool, always verify the true next build number
directly in App Store Connect → TestFlight → Builds before setting `CURRENT_PROJECT_VERSION`
manually — git tags and local build settings cannot be trusted alone if CI has its own
independent versioning path.

---

## [1.2.1] - Build 38 (pending) - 2026-07-06

### Added
- `Exercise` model (`id`, `name`, `coreType: ExerciseCoreType`) — canonical exercise identity,
  independent model, no migration required at time of addition
- `exercise: Exercise?` relationship added to `Progression`, `ProgramExercise`,
  `ExerciseProgressionSettings`, `CardioProgression` (legacy `exerciseName` fields retained,
  not removed)
- New interactive migration flow: `RootView` + `ExerciseReconciliationView` — detects
  unresolved legacy exercise names and requires the user to assign each a `coreType` before
  proceeding, since `coreType` is required with no safe universal default (not handled by a
  MigrationService repair function)

### Fixed
- `CFBundleVersion` mismatch between the app target and `RestTimerWidgetExtension`
  (extension was still at build 6 while the app was at 7)

### Changed
- Repo baseline reset to match actual live TestFlight Build 7 (see README.md "Repo History
  Note"); `main` renamed from a divergent, non-working state to this verified baseline

### Technical
- Schema version: V2 → V3
- Tested on device: fresh install (no reconciliation screen shown, as expected) and upgrade
  over existing real data (screen shown with correct names, resolved correctly, did not
  reappear on relaunch, existing session data unaffected)

### Known Issues (not fixed in this build, tracked separately)
- Current PR Totals still only reads Progression-based data, not Program-based (issue #3)
- Per-exercise settings overrides (`ExerciseProgressionSettings`) remain non-functional —
  configurable in Settings UI but never read by deload/adjustment logic (issue #8)
- Program and Progression remain separate, overlapping model hierarchies (issue #4)

---

## [1.2.1] - Build 6 - 2026-01-27

### Added
- Rest timer system with countdown display
- Haptic feedback at 10, 5, 3, 2, 1 seconds
- Audio notification on timer completion
- Quick adjust buttons (-30s, -15s, +15s, +30s)
- Rest timer settings (duration, auto-start, sound, haptic)
- Migration infrastructure (MigrationService.swift)

### Changed
- Split settings views into separate files (Basic, Advanced, Rest Timer)
- Refactored settings UI for better organization
- GlobalProgressionSettings schema updated (V1 → V2)

### Fixed
- SwiftUI compiler timeout in complex Form views

### Technical
- Schema version: V2
- Added 4 new properties to GlobalProgressionSettings
- Implemented MigrationService for data migration

### Known Issues
- User crash reported on upgrade from Build 5
- Missing schema versioning causing migration failures
- Addressed in the build tagged `v1.2.1-build7` (see entry above)

---

## [1.2.0] - Build 5 - 2026-01-26

### Added
- Program template: 5/3/1 (Wendler) with wave periodization
- Program template: Madcow 5×5 with ramping sets
- Program template: Texas Method with light/heavy days

### Changed
- Improved program template selection UI
- Enhanced program detail views

### Fixed
- Program progression calculation edge cases

---

## [1.1.0] - Build 4 - 2026-01-24

### Added
- Program management views (ProgramDetailView, EditProgramView)
- Program navigation and organization
- Starting Strength template

### Changed
- Improved program system architecture

---

## [1.0.2] - Build 3 - 2026-01-23

### Added
- Multi-exercise workout support
- Program session generation
- Week advancement system

---

## [1.0.1] - Build 2 - 2026-01-18

### Added
- Program system data models
- SwiftData integration for programs
- TrainingDay and ProgramExercise models

---

## [1.0.0] - Build 1 - 2026-01-15

### Added
- Initial release
- Core progression tracking (linear, periodization, RPE-based, percentage-based)
- Workout logging with sets/reps/weight
- Cardio progressions (running, swimming, calisthenics, CrossFit)
- Inventory management (plates, bars, collars)
- Plate calculator
- Analytics dashboard
- Exercise library
- User profile (basic)

### Technical
- SwiftUI interface
- SwiftData persistence
- iOS 17.0+ support

**Note (added July 6, 2026):** "Exercise library" above was listed as shipped in this entry,
but no such feature (model, preset list, or UI) was found anywhere in the codebase during a
2026-07-06 audit. This is flagged here rather than silently removed, since it's not clear
whether this entry was inaccurate at the time or referred to something later removed without
a corresponding changelog entry. The real Exercise model work begins with Build 38 above.

---

## Version History Summary

| Version | Build | Date | Schema | Key Features |
|---------|-------|------|--------|--------------|
| 1.2.1 | 38 (pending) | 2026-07-06 | V3 | Exercise identity model + relationships + reconciliation flow |
| — | 8, 9 | — | — | Abandoned (architecture refactor, non-working) — retired build numbers |
| — | 10-37 | 2026-07-06 | — | Consumed by misconfigured Xcode Cloud (project path, extra action, then still-active auto-upload) — retired build numbers |
| 1.2.1 | 7 | 2026-02-12 | V2 | Live Activity fixes, rest timer completion UX (per git tag `v1.2.1-build7`) |
| 1.2.1 | 6 | 2026-01-27 | V2 | Rest timer, migration infrastructure (see numbering discrepancy note at top) |
| 1.2.0 | 5 | 2026-01-26 | V1 | 5/3/1, Madcow, Texas Method templates |
| 1.1.0 | 4 | 2026-01-24 | V1 | Program management views |
| 1.0.2 | 3 | 2026-01-23 | V1 | Multi-exercise workouts |
| 1.0.1 | 2 | 2026-01-18 | V1 | Program system foundation |
| 1.0.0 | 1 | 2026-01-15 | V1 | Initial release |

---

## Migration History

| From | To | Type | Description |
|------|-----|------|-------------|
| Unversioned | V1 | N/A | Initial schema (Build 1-5) |
| V1 | V2 | Lightweight | Added rest timer properties (Build 6/7) |
| V2 | V3 | Interactive resolution | Added Exercise identity relationships (Build 38) — not a repair function, since `coreType` has no safe universal default |

---

## Deprecated Features

None yet.

---

## Security Updates

None yet.

---

[Unreleased]: https://github.com/asherdowd/LIFTR/compare/v1.2.1-build7...HEAD
[1.2.1]: https://github.com/asherdowd/LIFTR/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/asherdowd/LIFTR/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/asherdowd/LIFTR/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/asherdowd/LIFTR/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/asherdowd/LIFTR/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/asherdowd/LIFTR/releases/tag/v1.0.0
