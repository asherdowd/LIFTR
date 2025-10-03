import Foundation
import SwiftData

// MARK: - Enums

enum TemplateType: String, Codable, CaseIterable {
    case startingStrength = "Starting Strength"
    case smolov = "Smolov"
    case fiveThreeOne = "5/3/1"
    case texasMethod = "Texas Method"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .startingStrength:
            return "Linear progression for beginners"
        case .smolov:
            return "Intense squat specialization program"
        case .fiveThreeOne:
            return "Wave periodization with deloads"
        case .texasMethod:
            return "Intermediate weekly progression"
        case .custom:
            return "Create your own progression"
        }
    }
}

enum ProgressionStyle: String, Codable, CaseIterable {
    case linear = "Linear"
    case periodization = "Periodization"
    case rpe = "RPE-Based"
    case percentage = "Percentage-Based"
    
    var description: String {
        switch self {
        case .linear:
            return "Consistent weight increases each session/week"
        case .periodization:
            return "Wave-like progression with planned variation"
        case .rpe:
            return "Based on Rate of Perceived Exertion"
        case .percentage:
            return "Based on percentage of max"
        }
    }
}

enum ProgressionStatus: String, Codable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
}

enum ProgressionAdjustment: Equatable {
    case continueAsPlanned
    case repeatWeight
    case reduceBy(percent: Double)
    case deload(percent: Double)
    
    var message: String {
        switch self {
        case .continueAsPlanned:
            return "Great work! Continue with your planned progression."
        case .repeatWeight:
            return "You completed most reps but not all. Repeat this weight next session."
        case .reduceBy(let percent):
            return "Performance below target. Reduce future weights by \(String(format: "%.1f", percent))%?"
        case .deload(let percent):
            return "Significant performance drop. Deload by \(String(format: "%.1f", percent))% for recovery?"
        }
    }
}

// MARK: - Models

@Model
class Progression {
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
class WorkoutSession {
    var id: UUID
    var date: Date
    var weekNumber: Int
    var dayNumber: Int
    
    var plannedWeight: Double
    var plannedSets: Int
    var plannedReps: Int
    
    var completed: Bool
    var completedDate: Date?
    
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

@Model
class WorkoutSet {
    var id: UUID
    var setNumber: Int
    
    var targetReps: Int
    var targetWeight: Double
    
    var actualReps: Int?
    var actualWeight: Double?
    var rpe: Int?
    var completed: Bool
    
    var session: WorkoutSession?
    
    var notes: String?
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        targetReps: Int,
        targetWeight: Double,
        actualReps: Int? = nil,
        actualWeight: Double? = nil,
        rpe: Int? = nil,
        completed: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.rpe = rpe
        self.completed = completed
        self.notes = notes
    }
    
    var wasSuccessful: Bool {
        guard let actualReps = actualReps else { return false }
        return actualReps >= targetReps
    }
}
