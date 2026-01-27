# LIFTR - Placeholder Features & Incomplete Implementations

**Last Updated:** January 27, 2026  
**Version:** 1.2.1 (Build 5)

This document tracks all placeholder features, incomplete implementations, and TODOs that need completion before full production release.

---

## 🚨 HIGH PRIORITY - Core Functionality

### 1. **Data Migration System** (Milestone 8)
**Status:** ❌ Not Implemented  
**Location:** Models layer  
**Priority:** CRITICAL

**Issue:**
- SwiftData schema changes currently break existing user data
- No versioned schema migration system in place
- Users must delete and reinstall app after model changes

**Required Implementation:**
- Create `SchemaVersions.swift` with versioned schemas
- Implement `SchemaMigrationPlan` for V1 → V2 → V3 migrations
- Add migration tests
- Document migration procedures

**Impact:** User data loss on updates - BLOCKER for production

---

### 2. **Apple Health Integration**
**Status:** ❌ Placeholder Only  
**Location:** `Views/SettingsView.swift` - IntegrationsView  
**Priority:** HIGH

**Current State:**
```swift
struct IntegrationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Integrations Coming Soon")
        }
    }
}
```

**Required Implementation:**
- HealthKit authorization flow
- Workout data export (strength sessions with sets/reps/weight)
- Cardio data export (duration, distance, calories)
- Background sync
- Privacy settings

**Files to Create:**
- `Services/HealthKitService.swift`
- `Views/Settings/HealthKitSettingsView.swift`

---

### 3. **Strava Integration** (Milestone 10)
**Status:** ❌ Placeholder Only  
**Location:** `Views/SettingsView.swift` - IntegrationsView  
**Priority:** MEDIUM-HIGH  
**Dependencies:** Milestone 7 (Timer System) - ✅ COMPLETE

**Required Implementation:**
- OAuth 2.0 authentication flow
- Activity upload (workouts as strength training activities)
- Duration tracking (from workout timer)
- Rate limit handling (100 requests/15 min, 1000/day)
- Sync history view
- Error handling and retry logic

**Files to Create:**
- `Services/StravaService.swift`
- `Models/StravaModels.swift`
- `Views/Settings/StravaSettingsView.swift`

**API Requirements:**
- Strava API Client ID/Secret (register at developers.strava.com)
- Callback URL configuration
- Token storage (secure keychain)

---

## 🔧 MEDIUM PRIORITY - Enhancements

### 4. **Progression Recalculation**
**Status:** ❌ TODO in Code  
**Location:** `Views/Progression/EditProgressionView.swift:302`  
**Priority:** MEDIUM

**Current State:**
```swift
Button(action: {
    // TODO: Implement recalculation logic
    dismiss()
}) {
    Text("Recalculate")
}
```

**Required Implementation:**
- Recalculate progression based on new current max
- Regenerate remaining workout sessions
- Preserve completed session history
- Update weights for future sessions

**Complexity:** Medium - involves session regeneration logic

---

### 5. **User Profile Functionality**
**Status:** ⚠️ Partially Implemented  
**Location:** `Views/SettingsView.swift` - UserProfileView  
**Priority:** MEDIUM

**Current State:**
- Basic firstName/email fields exist
- No User model integration with workouts
- No profile photos
- No additional user metadata

**Missing Features:**
- Age, weight, height tracking
- Profile photo upload
- Workout preferences
- Training goals
- Experience level
- Body measurements tracking

**Required:**
- Expand User model in `Models/SettingsModels.swift`
- Add body measurement tracking views
- Integrate with workout planning

---

### 6. **Support/Issue Reporting**
**Status:** ⚠️ UI Only, No Backend  
**Location:** `Views/SupportView.swift`  
**Priority:** MEDIUM

**Current State:**
- Form UI exists (title, description, screenshot upload)
- `submitIssue()` function has no backend integration
- No actual issue submission mechanism

**Required Implementation:**
- Backend API endpoint for issue submission
- Email integration (send to support@liftr.app)
- Or third-party service integration (Zendesk, Intercom, etc.)
- Issue tracking system
- User notification of submission success

---

## 📱 LOW PRIORITY - Nice to Have

### 7. **Program Templates - Additional Options**
**Status:** ⚠️ Some Templates Missing  
**Location:** `Views/Program/CreateProgramView.swift`  
**Priority:** LOW

**Implemented:**
- ✅ Starting Strength
- ✅ Texas Method
- ✅ Madcow 5×5
- ✅ 5/3/1 (Wendler)

**Commented Out / Not Implemented:**
- ❌ Smolov (intentionally skipped - too complex/niche)
- ❌ Other intermediate/advanced templates

**Potential Additions:**
- Westside Barbell (advanced)
- GZCL Method (intermediate)
- nSuns (intermediate-advanced)
- Upper/Lower splits
- Push/Pull/Legs splits

**Note:** Current template library covers beginner → intermediate lifters adequately.

---

### 8. **Metric Unit Support**
**Status:** ⚠️ Toggle Exists But Incomplete  
**Location:** Settings → Preferences  
**Priority:** LOW

**Current State:**
- Settings toggle for useMetric exists
- Unit conversion NOT implemented throughout app
- All displays hardcoded to lbs
- Inventory, workouts, progressions all use imperial

**Required Implementation:**
- Unit conversion utility functions
- Update all weight displays (lbs ↔ kg)
- Update all increment values (2.5 lbs = 1.25 kg)
- Plate calculator metric support (20kg, 15kg, 10kg, 5kg, 2.5kg, 1.25kg)
- Settings to choose display precision

**Complexity:** Medium - touches many views

---

### 9. **Advanced Analytics**
**Status:** ⚠️ Basic Analytics Only  
**Location:** `Views/AnalyticsView.swift`  
**Priority:** LOW

**Current Features:**
- Basic PR tracking
- Simple charts

**Missing Features:**
- Volume tracking (total weight × reps)
- Tonnage over time
- Workout frequency analysis
- Rest day patterns
- Exercise-specific trends
- Body part split tracking
- Estimated 1RM calculations
- Strength standards comparison
- Export data to CSV

---

### 10. **Social Features**
**Status:** ❌ Not Planned Yet  
**Priority:** VERY LOW

**Potential Features:**
- Share workouts/PRs
- Follow other users
- Leaderboards
- Challenges
- Workout feed
- Comments/likes

**Note:** Requires backend infrastructure, user accounts, moderation

---

## 🐛 KNOWN ISSUES / BUGS

### 11. **SwiftUI Sheet Dismissal Bug**
**Status:** ⚠️ Workaround Implemented  
**Location:** `Views/Tests/` (test files document the issue)  
**Priority:** LOW (workaround functional)

**Issue:**
- Double sheet presentations cause dismiss() to malfunction
- Specific pattern: Sheet 1 → Sheet 2 → Alert → dismiss() doesn't work

**Current Workaround:**
- Using `programWasCreated` binding to cascade dismissals
- Tested in Test1_MinimalView.swift through Test7

**Status:** Functional but not ideal. May need Apple bug report.

---

## 🔬 TESTING GAPS

### 12. **Unit Tests**
**Status:** ❌ No Unit Tests  
**Priority:** MEDIUM-HIGH

**Missing:**
- Model validation tests
- Calculation tests (plate loading, progression, etc.)
- Service layer tests
- Data integrity tests

**Required:**
- XCTest target setup
- Test coverage for critical calculations
- Mock data generators

---

### 13. **UI Tests**
**Status:** ❌ No UI Tests  
**Priority:** MEDIUM

**Missing:**
- Critical user flows
- Workout creation/logging
- Navigation tests
- Settings persistence tests

---

## 📝 DOCUMENTATION GAPS

### 14. **Code Documentation**
**Status:** ⚠️ Minimal Comments  
**Priority:** MEDIUM

**Missing:**
- Function-level documentation
- Complex algorithm explanations
- Architecture documentation (ARCHITECTURE.md)
- API integration guides

---

### 15. **User Documentation**
**Status:** ❌ No User Guide  
**Priority:** LOW (for now)

**Missing:**
- In-app tutorial/onboarding
- Help documentation
- Video tutorials
- FAQ section

---

## 🚀 DEPLOYMENT REQUIREMENTS

### 16. **App Store Metadata**
**Status:** ⚠️ Incomplete  
**Priority:** HIGH (before production)

**Required:**
- App description
- Screenshots (all device sizes)
- App Store keywords
- Privacy policy
- Support URL
- Marketing materials

---

### 17. **Backend Infrastructure** (If Applicable)
**Status:** ❌ Not Planned Yet  
**Priority:** Depends on Feature Set

**Potential Needs:**
- User authentication system
- Cloud data sync
- Issue tracking system
- Analytics backend
- Push notifications

**Current:** App is fully local - no backend required for core functionality

---

## 📊 PRIORITY SUMMARY

### Must Have Before Production (v1.0):
1. ✅ ~~Data Migration System~~ → Add to Milestone 8
2. ❌ Apple Health Integration (if marketed feature)
3. ❌ Unit Testing (critical paths)
4. ❌ App Store metadata

### Should Have (v1.1):
1. Strava Integration
2. Progression Recalculation
3. Enhanced User Profile
4. Issue Reporting Backend

### Nice to Have (v1.2+):
1. Metric Unit Support
2. Additional Program Templates
3. Advanced Analytics
4. Social Features

---

## 📋 MILESTONE ALIGNMENT

| Milestone | Status | Placeholder Features |
|-----------|--------|---------------------|
| 1-6 | ✅ Complete | Core strength tracking, programs, templates |
| 7 | ✅ Complete | Timer system |
| 8 | ⏳ Planned | **Data Migration** ← CRITICAL |
| 9 | ⏳ Planned | Code optimization, testing |
| 10 | ⏳ Planned | **Strava Integration** |
| 11+ | 🔮 Future | Apple Health, Social, Advanced Analytics |

---

## 🎯 RECOMMENDED NEXT STEPS

1. **Immediate (This Week):**
   - Document current database schema (V1)
   - Plan V2 migration strategy
   - Test Build 5 thoroughly

2. **Short Term (Next 2 Weeks):**
   - Implement Milestone 8 (Data Migration)
   - Add critical unit tests
   - Fix any bugs from TestFlight feedback

3. **Medium Term (Next Month):**
   - Apple Health integration
   - Strava integration
   - Enhanced analytics

4. **Long Term (2-3 Months):**
   - Metric support
   - Social features
   - Advanced program templates

---

**END OF DOCUMENT**

*This is a living document. Update as features are implemented or requirements change.*
