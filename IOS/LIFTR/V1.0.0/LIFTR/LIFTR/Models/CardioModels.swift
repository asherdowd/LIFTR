import Foundation
import SwiftData

// MARK: - Enums

enum CardioType: String, Codable, CaseIterable {
    case running = "Running"
    case swimming = "Swimming"
    case calisthenics = "Calisthenics"
    case crossfit = "CrossFit"
    case freeCardio = "Free Cardio"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .swimming: return "figure.pool.swim"
        case .calisthenics: return "figure.climbing"
        case .crossfit: return "figure.strengthtraining.functional"
        case .freeCardio: return "heart.fill"
        }
    }
    
    var description: String {
        switch self {
        case .running: return "Distance-based running progressions"
        case .swimming: return "Swimming distance and time tracking"
        case .calisthenics: return "Bodyweight movement progressions"
        case .crossfit: return "CrossFit WOD tracking"
        case .freeCardio: return "General cardio sessions"
        }
    }
}

enum CrossFitWorkoutType: String, Codable, CaseIterable {
    case forTime = "For Time"
    case amrap = "AMRAP"
    case emom = "EMOM"
    case tabata = "Tabata"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .forTime: return "Complete rounds as fast as possible"
        case .amrap: return "As Many Rounds/Reps As Possible"
        case .emom: return "Every Minute On the Minute"
        case .tabata: return "20 seconds work, 10 seconds rest"
        case .custom: return "Custom workout format"
        }
    }
}

// MARK: - Models

@Model
class CardioProgression {
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
class CardioSession {
    var id: UUID
    var date: Date
    var weekNumber: Int
    var dayNumber: Int
    
    var completed: Bool
    var completedDate: Date?
    var duration: TimeInterval?
    
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
    
    func calculatePace(useMetric: Bool = false) -> Double? {
        guard let distance = actualDistance, let duration = duration, distance > 0 else { return nil }
        let minutes = duration / 60.0
        return minutes / distance
    }
}
