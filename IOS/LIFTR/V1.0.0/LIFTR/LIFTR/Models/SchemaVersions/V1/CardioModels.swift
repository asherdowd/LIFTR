import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    final class CardioProgression {
        var id: UUID
        var name: String
        var cardioType: CardioType
        var status: ProgressionStatus
        
        var totalWeeks: Int
        var currentWeek: Int
        var startDate: Date
        
        var targetDistance: Double?
        var startingWeeklyDistance: Double?
        
        var exerciseName: String?
        var targetReps: Int?
        var startingReps: Int?
        
        var workoutType: CrossFitWorkoutType?
        var workoutDescription: String?
        
        var useMetric: Bool
        
        @Relationship(deleteRule: .cascade) var sessions: [CardioSession]
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            name: String,
            cardioType: CardioType,
            status: ProgressionStatus = .active,
            totalWeeks: Int,
            currentWeek: Int = 1,
            startDate: Date = Date(),
            targetDistance: Double? = nil,
            startingWeeklyDistance: Double? = nil,
            exerciseName: String? = nil,
            targetReps: Int? = nil,
            startingReps: Int? = nil,
            workoutType: CrossFitWorkoutType? = nil,
            workoutDescription: String? = nil,
            useMetric: Bool = false,
            notes: String? = nil
        ) {
            self.id = id
            self.name = name
            self.cardioType = cardioType
            self.status = status
            self.totalWeeks = totalWeeks
            self.currentWeek = currentWeek
            self.startDate = startDate
            self.targetDistance = targetDistance
            self.startingWeeklyDistance = startingWeeklyDistance
            self.exerciseName = exerciseName
            self.targetReps = targetReps
            self.startingReps = startingReps
            self.workoutType = workoutType
            self.workoutDescription = workoutDescription
            self.useMetric = useMetric
            self.sessions = []
            self.notes = notes
        }
        
        var progressPercentage: Double {
            return Double(currentWeek) / Double(totalWeeks) * 100
        }
    }
    
    @Model
    final class CardioSession {
        var id: UUID
        var date: Date
        var weekNumber: Int
        var dayNumber: Int
        
        var completed: Bool
        var completedDate: Date?
        var duration: TimeInterval?
        
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
        
        var plannedDistance: Double?
        var actualDistance: Double?
        var pace: Double?
        
        var plannedSets: Int?
        var plannedReps: Int?
        var actualSets: Int?
        var actualReps: Int?
        
        var rounds: Int?
        var movements: String?
        
        var activityType: String?
        
        var progression: CardioProgression?
        
        var notes: String?
        var rpe: Int?
        
        init(
            id: UUID = UUID(),
            date: Date = Date(),
            weekNumber: Int,
            dayNumber: Int = 1,
            completed: Bool = false,
            completedDate: Date? = nil,
            duration: TimeInterval? = nil,
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
            plannedDistance: Double? = nil,
            actualDistance: Double? = nil,
            pace: Double? = nil,
            plannedSets: Int? = nil,
            plannedReps: Int? = nil,
            actualSets: Int? = nil,
            actualReps: Int? = nil,
            rounds: Int? = nil,
            movements: String? = nil,
            activityType: String? = nil,
            notes: String? = nil,
            rpe: Int? = nil
        ) {
            self.id = id
            self.date = date
            self.weekNumber = weekNumber
            self.dayNumber = dayNumber
            self.completed = completed
            self.completedDate = completedDate
            self.duration = duration
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
            self.plannedDistance = plannedDistance
            self.actualDistance = actualDistance
            self.pace = pace
            self.plannedSets = plannedSets
            self.plannedReps = plannedReps
            self.actualSets = actualSets
            self.actualReps = actualReps
            self.rounds = rounds
            self.movements = movements
            self.activityType = activityType
            self.notes = notes
            self.rpe = rpe
        }
        
        func calculatePace(useMetric: Bool) -> Double? {
            guard let distance = actualDistance, let duration = duration, distance > 0 else {
                return nil
            }
            let paceInMinutesPerUnit = (duration / 60.0) / distance
            return paceInMinutesPerUnit
        }
    }
}
