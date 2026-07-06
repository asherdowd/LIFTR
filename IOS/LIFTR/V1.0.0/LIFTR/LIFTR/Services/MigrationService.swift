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
        
        // V2 uses fresh schema - no migrations needed from V1
        // Future migrations will be added here when moving to V3:
        // repairV2toV3_NewFeature(context: context)
        
        print("✅ MigrationService: All checks complete")
    }
    
    // MARK: - Future Migrations
    
    /// V2 → V3 Migration Template
    /// Uncomment and implement when V3 is released
    /*
    private static func repairV2toV3_NewFeature(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<GlobalWorkoutSettings>()
            let settings = try context.fetch(descriptor)
            
            guard let currentSettings = settings.first else {
                print("⚠️  No GlobalWorkoutSettings found - will be created on first use")
                return
            }
            
            // Check if migration is needed
            // Apply migration logic here
            
            try context.save()
            print("✅ V2→V3 Migration: Complete")
        } catch {
            print("❌ V2→V3 Migration failed: \(error.localizedDescription)")
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
 
 CURRENT SCHEMA VERSION: V2 (Unified Architecture - Build 10)
 NEXT VERSION: V3 (TBD)
 
 See Docs/DATABASE_SCHEMA.md for complete schema history.
 */
