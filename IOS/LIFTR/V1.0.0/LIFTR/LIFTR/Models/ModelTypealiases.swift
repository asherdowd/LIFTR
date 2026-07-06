import Foundation
import SwiftData

/// Model type aliases - V2

typealias CurrentSchema = SchemaV2

// MARK: - V2 Models

typealias Plan = CurrentSchema.Plan
typealias ScheduledWorkout = CurrentSchema.ScheduledWorkout
typealias WorkoutExercise = CurrentSchema.WorkoutExercise
typealias WorkoutSet = CurrentSchema.WorkoutSet  // ← RENAMED from Set
typealias PlannedExercise = CurrentSchema.PlannedExercise
typealias CustomExercise = CurrentSchema.CustomExercise
typealias GlobalWorkoutSettings = CurrentSchema.GlobalWorkoutSettings

// MARK: - Unchanged from V1 (but copied into V2)

typealias User = CurrentSchema.User
typealias PlateItem = CurrentSchema.PlateItem
typealias BarItem = CurrentSchema.BarItem
typealias CollarItem = CurrentSchema.CollarItem
typealias ExerciseProgressionSettings = CurrentSchema.ExerciseProgressionSettings

// MARK: - V2 Supporting Types

typealias ExerciseDefinition = CurrentSchema.ExerciseDefinition
typealias ExerciseCategory = CurrentSchema.ExerciseCategory
typealias ExerciseStyle = CurrentSchema.ExerciseStyle
typealias ExerciseType = CurrentSchema.ExerciseType
typealias PlanType = CurrentSchema.PlanType
typealias PlanStatus = CurrentSchema.PlanStatus
typealias ProgressionStyle = CurrentSchema.ProgressionStyle
typealias WarmupStyle = CurrentSchema.WarmupStyle
typealias WarmupRepsStyle = CurrentSchema.WarmupRepsStyle
typealias WorkoutType = CurrentSchema.WorkoutType
typealias AdjustmentMode = CurrentSchema.AdjustmentMode
typealias DefaultView = CurrentSchema.DefaultView
typealias DayOfWeek = CurrentSchema.DayOfWeek

// MARK: - UI Helpers

typealias PresetProfile = CurrentSchema.PresetProfile
