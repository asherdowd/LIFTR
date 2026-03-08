import Foundation
import SwiftData

/// Schema V1 - Build 8/9 Baseline (March 2026)
/// FROZEN snapshot - DO NOT MODIFY after shipping to production
///
/// This is the baseline schema for LIFTR v1.0 production release.
/// Includes all models with Strava and Apple Health integration properties.
///
/// Model implementations are in SchemaVersions/V1/ folder.
/// Future changes require creating SchemaV2.swift and V2/ folder.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            User.self,
            GlobalProgressionSettings.self,
            ExerciseProgressionSettings.self,
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            Program.self,
            TrainingDay.self,
            ProgramExercise.self,
            ExerciseSession.self,
            Progression.self,
            WorkoutSession.self,
            WorkoutSet.self,
            CardioProgression.self,
            CardioSession.self
        ]
    }
}
