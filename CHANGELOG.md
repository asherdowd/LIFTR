# Changelog

All notable changes to LIFTR will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Build 7: Schema V1 wrapper (migration infrastructure)
- Build 8: Schema V2 with rest timer feature

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
- Will be fixed in Build 7

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

---

## Version History Summary

| Version | Build | Date | Schema | Key Features |
|---------|-------|------|--------|--------------|
| 1.2.1 | 6 | 2026-01-27 | V2 | Rest timer, migration infrastructure |
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
| V1 | V2 | Lightweight | Added rest timer properties (Build 6) |

---

## Deprecated Features

None yet.

---

## Security Updates

None yet.

---

[Unreleased]: https://github.com/asherdowd/LIFTR/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/asherdowd/LIFTR/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/asherdowd/LIFTR/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/asherdowd/LIFTR/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/asherdowd/LIFTR/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/asherdowd/LIFTR/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/asherdowd/LIFTR/releases/tag/v1.0.0
