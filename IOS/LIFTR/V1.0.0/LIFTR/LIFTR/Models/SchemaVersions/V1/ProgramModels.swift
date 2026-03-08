import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    final class Program {
        var id: UUID
        var name: String
        var templateType: TemplateType
        var status: ProgressionStatus
        
        var totalWeeks: Int
        var currentWeek: Int
        var startDate: Date
        
        @Relationship(deleteRule: .cascade) var trainingDays: [TrainingDay]
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            name: String,
            templateType: TemplateType,
            status: ProgressionStatus = .active,
            totalWeeks: Int,
            currentWeek: Int = 1,
            startDate: Date = Date(),
            notes: String? = nil
        ) {
            self.id = id
            self.name = name
            self.templateType = templateType
            self.status = status
            self.totalWeeks = totalWeeks
            self.currentWeek = currentWeek
            self.startDate = startDate
            self.trainingDays = []
            self.notes = notes
        }
        
        var progressPercentage: Double {
            return Double(currentWeek) / Double(totalWeeks) * 100
        }
    }
    
    @Model
    final class TrainingDay {
        var id: UUID
        var name: String
        var dayNumber: Int
        
        @Relationship(deleteRule: .cascade) var exercises: [ProgramExercise]
        @Relationship(deleteRule: .cascade) var sessions: [ExerciseSession]
        
        var program: Program?
        
        init(
            id: UUID = UUID(),
            name: String,
            dayNumber: Int
        ) {
            self.id = id
            self.name = name
            self.dayNumber = dayNumber
            self.exercises = []
            self.sessions = []
        }
    }
    
    @Model
    final class ProgramExercise {
        var id: UUID
        var exerciseName: String
        var orderIndex: Int
        
        var startingWeight: Double
        var currentWeight: Double
        var targetSets: Int
        var targetReps: Int
        var increment: Double
        
        var trainingDay: TrainingDay?
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            exerciseName: String,
            orderIndex: Int,
            startingWeight: Double,
            currentWeight: Double? = nil,
            targetSets: Int,
            targetReps: Int,
            increment: Double = 5.0,
            notes: String? = nil
        ) {
            self.id = id
            self.exerciseName = exerciseName
            self.orderIndex = orderIndex
            self.startingWeight = startingWeight
            self.currentWeight = currentWeight ?? startingWeight
            self.targetSets = targetSets
            self.targetReps = targetReps
            self.increment = increment
            self.notes = notes
        }
    }
    
    @Model
    final class ExerciseSession {
        var id: UUID
        var date: Date
        var weekNumber: Int
        var sessionNumber: Int
        
        var plannedWeight: Double
        var plannedSets: Int
        var plannedReps: Int
        
        var completed: Bool
        var completedDate: Date?
        
        // Strava Integration
        var startTime: Date?
        var endTime: Date?
        var totalDuration: TimeInterval?
        var stravaActivityId: String?
        var syncedToStrava: Bool
        
        // Apple Health Integration
        var healthKitWorkoutId: String?
        var syncedToHealthKit: Bool?
        var caloriesBurned: Double?
        var heartRateAverage: Int?
        var heartRateMax: Int?
        
        @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
        
        var exercise: ProgramExercise?
        var trainingDay: TrainingDay?
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            date: Date = Date(),
            weekNumber: Int,
            sessionNumber: Int,
            plannedWeight: Double,
            plannedSets: Int,
            plannedReps: Int,
            completed: Bool = false,
            completedDate: Date? = nil,
            startTime: Date? = nil,
            endTime: Date? = nil,
            totalDuration: TimeInterval? = nil,
            stravaActivityId: String? = nil,
            syncedToStrava: Bool = false,
            healthKitWorkoutId: String? = nil,
            syncedToHealthKit: Bool? = nil,
            caloriesBurned: Double? = nil,
            heartRateAverage: Int? = nil,
            heartRateMax: Int? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.date = date
            self.weekNumber = weekNumber
            self.sessionNumber = sessionNumber
            self.plannedWeight = plannedWeight
            self.plannedSets = plannedSets
            self.plannedReps = plannedReps
            self.completed = completed
            self.completedDate = completedDate
            self.startTime = startTime
            self.endTime = endTime
            self.totalDuration = totalDuration
            self.stravaActivityId = stravaActivityId
            self.syncedToStrava = syncedToStrava
            self.healthKitWorkoutId = healthKitWorkoutId
            self.syncedToHealthKit = syncedToHealthKit
            self.caloriesBurned = caloriesBurned
            self.heartRateAverage = heartRateAverage
            self.heartRateMax = heartRateMax
            self.sets = []
            self.notes = notes
        }
        
        var totalPlannedReps: Int {
            return plannedSets * plannedReps
        }
        
        var totalCompletedReps: Int {
            return sets.reduce(0) { $0 + ($1.actualReps ?? 0) }
        }
        
        var performancePercentage: Double {
            guard totalPlannedReps > 0 else { return 0 }
            return Double(totalCompletedReps) / Double(totalPlannedReps) * 100
        }
    }
}
