import Foundation
import SwiftData

/// Model type aliases
/// Maps friendly names to the current schema version
/// Views use these names (User, WorkoutSession, etc.) which automatically
/// point to the correct schema version (CurrentSchema.User, etc.)
///
/// When CurrentSchema updates to V2, all these automatically point to V2 models
/// No view code changes needed!

// User Models
typealias User = CurrentSchema.User

// Settings Models  
typealias GlobalProgressionSettings = CurrentSchema.GlobalProgressionSettings
typealias ExerciseProgressionSettings = CurrentSchema.ExerciseProgressionSettings

// Inventory Models
typealias PlateItem = CurrentSchema.PlateItem
typealias BarItem = CurrentSchema.BarItem
typealias CollarItem = CurrentSchema.CollarItem

// Shared Models
typealias WorkoutSet = CurrentSchema.WorkoutSet

// Strength Models
typealias Progression = CurrentSchema.Progression
typealias WorkoutSession = CurrentSchema.WorkoutSession

// Program Models
typealias Program = CurrentSchema.Program
typealias TrainingDay = CurrentSchema.TrainingDay
typealias ProgramExercise = CurrentSchema.ProgramExercise
typealias ExerciseSession = CurrentSchema.ExerciseSession

// Cardio Models
typealias CardioProgression = CurrentSchema.CardioProgression
typealias CardioSession = CurrentSchema.CardioSession
