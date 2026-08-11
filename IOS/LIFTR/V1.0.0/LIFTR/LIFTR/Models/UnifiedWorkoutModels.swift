import Foundation
import SwiftData

enum ProgressionStyle: String, Codable, CaseIterable {
    case linear = "Linear"
    case periodization = "Periodization"

    var description: String {
        switch self {
        case .linear:
            return "Consistent weight increases each session/week"
        case .periodization:
            return "Wave-like progression with planned variation (light/medium/heavy weeks)"
        }
    }
}
@Model
class Workout {
    var id: UUID = UUID()
    var name: String
    var templateType: TemplateType
    var status: ProgressionStatus = ProgressionStatus.active

    var totalWeeks: Int
    var currentWeek: Int = 1
    var startDate: Date = Date()

    @Relationship(deleteRule: .cascade) var days: [WorkoutDay]

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
        self.days = []
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
class WorkoutDay {
    var id: UUID = UUID()
    var name: String
    var dayNumber: Int

    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]

    var workout: Workout?

    init(
        id: UUID = UUID(),
        name: String,
        dayNumber: Int
    ) {
        self.id = id
        self.name = name
        self.dayNumber = dayNumber
        self.exercises = []
    }
}

@Model
class WorkoutExercise {
    var id: UUID
    var exercise: Exercise
    var orderIndex: Int
    var progressionStyle: ProgressionStyle
    var startingWeight: Double
    var currentWeight: Double
    var targetSets: Int
    var targetReps: Int
    var increment: Double = 5.0

    @Relationship(deleteRule: .cascade) var sessions: [ExerciseSession]

    var day: WorkoutDay?

    var notes: String?

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        orderIndex: Int,
        progressionStyle: ProgressionStyle,
        startingWeight: Double,
        currentWeight: Double? = nil,
        targetSets: Int,
        targetReps: Int,
        increment: Double = 5.0,
        notes: String? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.progressionStyle = progressionStyle
        self.startingWeight = startingWeight
        self.currentWeight = currentWeight ?? startingWeight
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.increment = increment
        self.sessions = []
        self.notes = notes
    }
}

@Model
class ExerciseSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var weekNumber: Int
    var sessionNumber: Int

    var plannedWeight: Double
    var plannedSets: Int
    var plannedReps: Int

    var completed: Bool = false
    var completedDate: Date?
    var paused: Bool = false
    var wasDeload: Bool = false
    var deloadPercent: Double?

    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    var workoutExercise: WorkoutExercise?

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
        paused: Bool = false,
        wasDeload: Bool = false,
        deloadPercent: Double? = nil,
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
        self.paused = paused
        self.wasDeload = wasDeload
        self.deloadPercent = deloadPercent
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
