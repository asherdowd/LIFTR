import Foundation
import SwiftData

/// CurrentSchema points to the latest schema version used by the app.
/// This is the ONLY file you modify when adding a new schema version.
///
/// Version History:
/// - Build 8/9: SchemaV1 (baseline with Strava and Apple Health properties)
///
/// When creating SchemaV2:
/// 1. Create SchemaV2.swift and V2/ folder with models
/// 2. Update this to: typealias CurrentSchema = SchemaV2
/// 3. Update MigrationPlan.swift with V1→V2 stage
/// 4. All typealiases automatically point to new schema

typealias CurrentSchema = SchemaV1
