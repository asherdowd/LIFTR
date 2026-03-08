# LIFTR - Placeholder Features & Incomplete Implementations

**Last Updated:** March 8, 2026  
**Version:** 1.2.1 (Build 9)

---

## ✅ COMPLETED

### Data Migration System
**Status:** ✅ Implemented (Build 9)  
**Date:** March 8, 2026

Versioned schema system with automatic migration handling.

---

## 🚨 HIGH PRIORITY

### 1. Apple Health Integration
**Status:** ❌ Placeholder Only  
**Location:** `Views/SettingsView.swift` - IntegrationsView

**Required:**
- HealthKit authorization
- Workout export (strength + cardio)
- Background sync
- Privacy settings

**Files to Create:**
- `Services/HealthKitService.swift`
- `Views/Settings/HealthKitSettingsView.swift`

---

### 2. Strava Integration (Milestone 10)
**Status:** ❌ Placeholder Only  
**Location:** `Views/SettingsView.swift` - IntegrationsView

**Required:**
- OAuth 2.0 authentication
- Activity upload
- Rate limit handling
- Sync history

**Files to Create:**
- `Services/StravaService.swift`
- `Models/StravaModels.swift`
- `Views/Settings/StravaSettingsView.swift`

**API:** Register at developers.strava.com

---

### 3. Progression Recalculation
**Status:** ❌ TODO  
**Location:** `Views/Progression/EditProgressionView.swift:302`

**Required:**
- Recalculate based on new current max
- Regenerate remaining sessions
- Preserve completed history

---

## 🔧 MEDIUM PRIORITY

### 4. User Profile Expansion
**Status:** ⚠️ Basic Only

**Current:** firstName, email  
**Missing:** age, weight, height, measurements, photo, preferences

**Required:**
- Expand User model
- Body measurement tracking
- Profile photo upload

---

### 5. Support/Issue Reporting
**Status:** ⚠️ UI Only  
**Location:** `Views/SupportView.swift`

**Current:** Form exists but doesn't submit  
**Required:** Backend endpoint or email integration

---

### 6. Metric Unit Support
**Status:** ⚠️ Toggle exists, no conversion  
**Location:** Settings → Preferences

**Required:**
- Unit conversion throughout app
- Metric plate calculator
- Display precision settings

---

## 📊 LOW PRIORITY

### 7. Advanced Analytics
**Current:** Basic PR tracking, simple charts  
**Missing:** Volume tracking, tonnage, frequency analysis, CSV export

---

### 8. Additional Program Templates
**Implemented:** Starting Strength, Texas Method, Madcow, 5/3/1  
**Potential:** GZCL, nSuns, Push/Pull/Legs

---

### 9. Social Features
**Status:** ❌ Not Planned  
**Features:** Share workouts, follow users, leaderboards, challenges

**Note:** Requires backend infrastructure

---

## 🐛 KNOWN ISSUES

### SwiftUI Sheet Dismissal Bug
**Status:** ⚠️ Workaround Implemented  
**Location:** `Views/Tests/`

Double sheet presentations cause dismiss() issues. Functional workaround using binding cascade.

---

## 🔬 TESTING GAPS

### Unit Tests
**Status:** ❌ None  
**Required:** Model validation, calculations, data integrity

### UI Tests
**Status:** ❌ None  
**Required:** Critical user flows, navigation, persistence

---

## 📝 DOCUMENTATION GAPS

### Code Documentation
**Status:** ⚠️ Minimal  
**Missing:** Function docs, algorithm explanations, architecture guide

### User Documentation
**Status:** ❌ None  
**Missing:** Tutorial, help docs, FAQ

---

## 🚀 DEPLOYMENT REQUIREMENTS

### App Store Metadata
**Status:** ⚠️ Incomplete  
**Required:** Description, screenshots, keywords, privacy policy, support URL

---

## 📋 MILESTONE ALIGNMENT

| Milestone | Status | Features |
|-----------|--------|----------|
| 1-6 | ✅ Complete | Core tracking, programs, templates |
| 7 | ✅ Complete | Rest timer |
| 8 | ✅ Complete | **Versioned schemas** |
| 9 | ⏳ Planned | Testing, optimization |
| 10 | ⏳ Planned | **Strava integration** |
| 11+ | 🔮 Future | Apple Health, social, analytics |

---

## 🎯 NEXT STEPS

**Immediate:**
- Thorough testing of Build 9
- Fix bugs from TestFlight

**Short Term (Next Month):**
- Strava integration
- Apple Health integration
- Unit tests for critical paths

**Long Term:**
- Metric support
- Advanced analytics
- Social features

---

**END OF DOCUMENT**
