import Foundation
import SwiftData

// MARK: - Program Models

@Model
class Program {
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
class TrainingDay {
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
class ProgramExercise {
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
class ExerciseSession {
    var id: UUID
    var date: Date
    var weekNumber: Int
    var sessionNumber: Int
    
    var plannedWeight: Double
    var plannedSets: Int
    var plannedReps: Int
    
    var completed: Bool
    var completedDate: Date?
    
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
