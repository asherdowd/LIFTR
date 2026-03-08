import Foundation
import SwiftData

/// MigrationPlan defines how SwiftData migrates between schema versions
///
/// Current schemas:
/// - V1 (Build 8/9): Baseline with all current models

enum LIFTRMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self
            // Future schemas added here:
            // SchemaV2.self,
            // SchemaV3.self,
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            // No migration stages yet - V1 is baseline
            // Future migrations added here:
            // migrateV1toV2,
            // migrateV2toV3,
        ]
    }
    
    // MARK: - Future Migration Stages
    
    // Example migration stage for V1 → V2 (uncomment when creating SchemaV2):
    /*
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            print("🔄 Starting migration V1 → V2...")
        },
        didMigrate: { context in
            print("✅ Migration V1 → V2 complete")
            // Call MigrationService repair functions if needed
        }
    )
    */
}
