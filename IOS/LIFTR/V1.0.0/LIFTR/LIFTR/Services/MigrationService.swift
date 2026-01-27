import SwiftData
import Foundation

/// Service responsible for handling data migrations and repairs between schema versions
/// Run performStartupChecks() on app launch to ensure data integrity
class MigrationService {
    
    // MARK: - Public Interface
    
    /// Performs all necessary migration checks and repairs on app startup
    /// Should be called once when the app launches
    /// - Parameter context: The ModelContext to use for data operations
    static func performStartupChecks(context: ModelContext) {
        print("🔄 MigrationService: Starting startup checks...")
        
        // Run all migration repairs in order
        repairV1toV2_RestTimerDefaults(context: context)
        
        // Future migrations will be added here:
        // repairV2toV3_StravaIntegration(context: context)
        // repairV3toV4_UserProfileExpansion(context: context)
        
        print("✅ MigrationService: All checks complete")
    }
    
    // MARK: - V1 → V2 Migration (Rest Timer Settings)
    
    /// Repairs V1 to V2 migration by setting default values for rest timer properties
    /// V2 added: defaultRestTime, autoStartRestTimer, restTimerSound, restTimerHaptic
    /// This runs once for users upgrading from V1 (Build 4 or earlier) to V2 (Build 5+)
    private static func repairV1toV2_RestTimerDefaults(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<GlobalProgressionSettings>()
            let settings = try context.fetch(descriptor)
            
            guard let currentSettings = settings.first else {
                print("⚠️  No GlobalProgressionSettings found - will be created on first use")
                return
            }
            
            // Check if this is a V1 → V2 upgrade
            // V1 data will have defaultRestTime = 0 (Int default)
            if currentSettings.defaultRestTime == 0 {
                print("🔧 V1→V2 Migration: Setting rest timer defaults")
                
                currentSettings.defaultRestTime = 180        // 3 minutes
                currentSettings.autoStartRestTimer = true
                currentSettings.restTimerSound = true
                currentSettings.restTimerHaptic = true
                
                try context.save()
                print("✅ V1→V2 Migration: Rest timer defaults applied")
            } else {
                print("✓ V1→V2 Migration: Already completed (defaultRestTime = \(currentSettings.defaultRestTime)s)")
            }
            
        } catch {
            print("❌ V1→V2 Migration failed: \(error.localizedDescription)")
            // Don't crash - log error and continue
            // User can still use app, just with wrong defaults
        }
    }
    
    // MARK: - Future Migrations
    
    /// V2 → V3 Migration (Strava Integration)
    /// Planned: Add startTime, endTime, totalDuration, stravaActivityId to sessions
    /// Uncomment and implement when V3 is released
    /*
    private static func repairV2toV3_StravaIntegration(context: ModelContext) {
        do {
            // Fetch all WorkoutSession, ExerciseSession, CardioSession
            // Set default values for new Strava properties
            // Example:
            // let descriptor = FetchDescriptor<WorkoutSession>()
            // let sessions = try context.fetch(descriptor)
            // for session in sessions {
            //     if session.stravaActivityId == nil {
            //         // This is old data, initialize new properties
            //         session.syncedToStrava = false
            //     }
            // }
            // try context.save()
            print("✅ V2→V3 Migration: Strava properties initialized")
        } catch {
            print("❌ V2→V3 Migration failed: \(error)")
        }
    }
    */
    
    /// V3 → V4 Migration (User Profile Expansion)
    /// Planned: Expand User model with body measurements, preferences
    /// Uncomment and implement when V4 is released
    /*
    private static func repairV3toV4_UserProfileExpansion(context: ModelContext) {
        do {
            // Fetch User
            // Set default values for new profile properties
            // Example:
            // let descriptor = FetchDescriptor<User>()
            // let users = try context.fetch(descriptor)
            // for user in users {
            //     if user.experienceLevel == nil {
            //         user.experienceLevel = "Beginner"
            //     }
            // }
            // try context.save()
            print("✅ V3→V4 Migration: User profile expanded")
        } catch {
            print("❌ V3→V4 Migration failed: \(error)")
        }
    }
    */
    
    // MARK: - Utility Functions
    
    /// Checks if a specific migration has already been applied
    /// Useful for complex migrations that shouldn't run twice
    private static func hasMigrationRun(key: String, context: ModelContext) -> Bool {
        // Could store migration history in a dedicated model if needed
        // For now, we check property values to determine migration status
        return false
    }
    
    /// Logs migration activity for debugging
    private static func logMigration(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] MIGRATION: \(message)")
    }
}

// MARK: - Migration Notes

/*
 MIGRATION STRATEGY:
 
 1. LIGHTWEIGHT MIGRATIONS (Preferred):
    - SwiftData handles automatically
    - Works for adding optional properties
    - We use repair functions to set proper defaults
    
 2. REPAIR FUNCTIONS (Current Approach):
    - Check for "uninitialized" property values (0, nil, false)
    - Set proper defaults if migration detected
    - Run on every app launch (negligible performance cost)
    - Simple, maintainable, no schema duplication
    
 3. MANUAL MIGRATIONS (Only if Needed):
    - Required for: type changes, property renames, relationship changes
    - Uses SchemaVersions.swift with full schema duplication
    - Complex, high maintenance, use as last resort
    
 WHEN TO ADD A NEW REPAIR FUNCTION:
 
 1. Model changed? (added/removed properties)
 2. Update DATABASE_SCHEMA.md with version bump
 3. Add new repair function here (e.g., repairV2toV3_FeatureName)
 4. Call it from performStartupChecks()
 5. Test migration path with old data
 6. Update CRITICAL_REMINDERS.md
 
 CURRENT SCHEMA VERSION: V2 (Rest Timer - January 27, 2026)
 NEXT VERSION: V3 (Strava Integration - TBD)
 
 See Docs/DATABASE_SCHEMA.md for complete schema history.
 See Docs/DATA_MIGRATION_POLICY.md for migration procedures.
 */
