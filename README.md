# LIFTR - Strength Training Tracker

Progressive overload tracking app for iOS with intelligent progression algorithms and automated workout planning.

## ⚠️ CRITICAL: Data Migration

**NEVER modify `@Model` classes without following migration procedures.**

See `Docs/CRITICAL_REMINDERS.md` for mandatory guidelines.

**Current Schema:** V2 (Rest Timer - January 27, 2026)

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
- **[DATABASE_SCHEMA.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATABASE_SCHEMA.md)** - Complete model documentation (15 models)
- **[CRITICAL_REMINDERS.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/CRITICAL_REMINDERS.md)** - Mandatory development rules
- **[DATA_MIGRATION_POLICY.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/DATA_MIGRATION_POLICY.md)** - Migration procedures
- **[PLACEHOLDER_FEATURES.md](IOS/LIFTR/V1.0.0/LIFTR/Docs/PLACEHOLDER_FEATURES.md)** - Unimplemented features

### Quick Reference
- **Models:** 15 SwiftData models (GlobalProgressionSettings, Progression, Program, WorkoutSession, etc.)
- **Schema Version:** V2 (with rest timer properties)
- **TestFlight:** Active
- **Branch:** `feature/program-system-refactor`

---

## 🚀 Current Status

**Version:** 1.2.1 (Build 5)  
**TestFlight Build:** 5 (uploaded January 27, 2026)  
**Active Branch:** `feature/program-system-refactor`

### ✅ Completed Milestones
- **Milestone 1:** Core strength tracking, cardio, inventory, calculator, analytics, settings
- **Milestone 2-4:** Program system data models, SwiftData integration, session generation
- **Milestone 5:** Program workout execution, multi-exercise workouts, week advancement
- **Milestone 5.5:** Program management views (detail, edit, navigation)
- **Milestone 6:** Program templates (Starting Strength, Texas Method, Madcow 5×5, 5/3/1)
- **Milestone 7:** Rest timer system with settings integration

### ⏳ In Progress
- **Milestone 8:** Data migration & safety (current)

### 📋 Upcoming
- **Milestone 9:** Code optimization, testing, documentation
- **Milestone 10:** Strava integration
- **Future:** Apple Health integration, metric units, advanced analytics

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
- Performance-based auto-adjustments

### Equipment Management
- Plate inventory tracking
- Bar inventory (Olympic, specialty bars)
- Collar tracking
- Plate loading calculator with available equipment

### Analytics
- Progress charts
- Volume tracking
- PR history
- Workout frequency
- Performance trends

---

## 🛠️ Development Rules

### Before Modifying Models

**MANDATORY steps when changing any `@Model` class:**

1. **Read** `Docs/CRITICAL_REMINDERS.md`
2. **Update** `Docs/DATABASE_SCHEMA.md` with version bump
3. **Add migration** to `Services/MigrationService.swift`
4. **Test migration** with existing data on device
5. **Update** this README with new schema version

**Failure to follow these steps = USER DATA LOSS**

### Schema Versions

| Version | Date | Changes | Migration |
|---------|------|---------|-----------|
| **V1** | Jan 1-26, 2026 | Original schema | N/A |
| **V2** | Jan 27, 2026 | Added rest timer properties to GlobalProgressionSettings | ✅ MigrationService |
| **V3** | Planned | Strava integration (startTime, endTime, totalDuration) | ⏳ Pending |
| **V4** | Planned | User profile expansion (age, weight, height) | ⏳ Pending |

### Current Schema (V2)

**Changed Models:**
- `GlobalProgressionSettings`: Added 4 rest timer properties
  - `defaultRestTime: Int` (default: 180 seconds)
  - `autoStartRestTimer: Bool` (default: true)
  - `restTimerSound: Bool` (default: true)
  - `restTimerHaptic: Bool` (default: true)

**Migration:** Handled by `repairRestTimerDefaults()` in `MigrationService.swift`

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
   git clone https://github.com/yourusername/LIFTRSwift.git
   cd LIFTRSwift
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

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Create progression and log workouts
- [ ] Create program and complete sessions
- [ ] Test rest timer functionality
- [ ] Verify plate calculator with custom inventory
- [ ] Test settings changes persist
- [ ] Test migration path (install old build, upgrade to new)

### Migration Testing (CRITICAL)
1. Install previous TestFlight build
2. Create substantial test data (progressions, workouts, programs)
3. Install new build with model changes
4. Verify:
   - [ ] App launches without crash
   - [ ] All data is preserved
   - [ ] New properties have correct defaults
   - [ ] Relationships intact

### Known Issues
- SwiftUI sheet dismissal bug with double presentations (workaround implemented)
- Metric unit toggle exists but conversion not implemented

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Make changes following migration policy
3. Test thoroughly on device
4. Update documentation
5. Create pull request

### Code Style
- SwiftUI for all views
- SwiftData for persistence
- MVVM-like architecture
- Descriptive variable names
- Comment complex logic

### Git Hooks
Pre-commit hook warns about model changes:
```bash
# Install hook (one-time setup)
chmod +x .git/hooks/pre-commit
```

Hook checks for:
- Modified `Models/*.swift` files
- Prompts for migration steps completion

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
- **Build Number** (incremental, e.g., Build 5)

### Release Process
1. Update version in Xcode project
2. Update `CHANGELOG.md`
3. Test migration path
4. Create TestFlight build
5. Submit for external testing
6. Monitor crash reports

### TestFlight
- **Current Build:** 5 (v1.2.1)
- **Status:** Active testing
- **Testers:** Internal + external beta

---

## 📝 Changelog

### Version 1.2.1 (Build 5) - January 27, 2026
**Added:**
- Rest timer system with countdown, haptic feedback, sound
- Rest timer settings (duration, auto-start, sound, haptic)
- Split settings views into separate files for better organization

**Changed:**
- Refactored settings UI into modular components
- GlobalProgressionSettings schema updated (V1 → V2)

**Fixed:**
- SwiftUI compiler timeout in complex Form views

### Version 1.2.0 (Build 4) - January 26, 2026
**Added:**
- Program template: 5/3/1 (Wendler) with wave periodization
- Program template: Madcow 5×5 with ramping sets
- Program template: Texas Method with light/heavy days

### Version 1.1.0 (Build 3) - January 23-24, 2026
**Added:**
- Program system (multi-exercise workouts)
- Starting Strength template
- Program management views

### Version 1.0.0 (Build 1-2) - January 2026
**Initial Release:**
- Core progression tracking
- Workout logging
- Inventory management
- Plate calculator
- Analytics dashboard
- Cardio progressions

---

## 🐛 Known Issues & Limitations

### Current Limitations
- ❌ Metric units toggle exists but conversion not implemented
- ❌ Apple Health integration not implemented (placeholder only)
- ❌ Strava integration not implemented (placeholder only)
- ❌ User profile basic (no body measurements, photos)
- ❌ Progression recalculation button non-functional (TODO)
- ❌ Support form doesn't submit (no backend)

### Planned Features
See `Docs/PLACEHOLDER_FEATURES.md` for complete list.

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

- **Issues:** [GitHub Issues](https://github.com/yourusername/LIFTRSwift/issues)
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

**Last Updated:** January 27, 2026  
**Schema Version:** V2  
**Build:** 5 (v1.2.1)
