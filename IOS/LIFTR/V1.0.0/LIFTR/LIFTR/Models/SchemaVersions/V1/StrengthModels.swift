import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    final class Progression {
        var id: UUID
        var exerciseName: String
        var templateType: TemplateType
        var progressionStyle: ProgressionStyle
        var status: ProgressionStatus
        
        var currentMax: Double
        var targetMax: Double
        var startingWeight: Double
        
        var totalWeeks: Int
        var currentWeek: Int
        var startDate: Date
        
        @Relationship(deleteRule: .cascade) var sessions: [WorkoutSession]
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            exerciseName: String,
            templateType: TemplateType,
            progressionStyle: ProgressionStyle,
            status: ProgressionStatus = .active,
            currentMax: Double,
            targetMax: Double,
            startingWeight: Double,
            totalWeeks: Int,
            currentWeek: Int = 1,
            startDate: Date = Date(),
            notes: String? = nil
        ) {
            self.id = id
            self.exerciseName = exerciseName
            self.templateType = templateType
            self.progressionStyle = progressionStyle
            self.status = status
            self.currentMax = currentMax
            self.targetMax = targetMax
            self.startingWeight = startingWeight
            self.totalWeeks = totalWeeks
            self.currentWeek = currentWeek
            self.startDate = startDate
            self.sessions = []
            self.notes = notes
        }
        
        var progressPercentage: Double {
            return Double(currentWeek) / Double(totalWeeks) * 100
        }
        
        var isActive: Bool {
            return status == .active
        }
    }
    
    @Model
    final class WorkoutSession {
        var id: UUID
        var date: Date
        var weekNumber: Int
        var dayNumber: Int
        
        var plannedWeight: Double
        var plannedSets: Int
        var plannedReps: Int
        
        var completed: Bool
        var completedDate: Date?
        var paused: Bool
        
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
        
        var progression: Progression?
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            date: Date = Date(),
            weekNumber: Int,
            dayNumber: Int = 1,
            plannedWeight: Double,
            plannedSets: Int,
            plannedReps: Int,
            completed: Bool = false,
            completedDate: Date? = nil,
            paused: Bool = false,
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
            self.dayNumber = dayNumber
            self.plannedWeight = plannedWeight
            self.plannedSets = plannedSets
            self.plannedReps = plannedReps
            self.completed = completed
            self.completedDate = completedDate
            self.paused = paused
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
