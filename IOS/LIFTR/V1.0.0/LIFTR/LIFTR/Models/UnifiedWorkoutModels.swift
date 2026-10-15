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
/// What a WorkoutExercise records. Strength is the default (existing data).
enum ExerciseKind: String, Codable {
    case strength = "Strength"
    case cardio = "Cardio"
}

/// Where a session's recorded numbers came from.
enum ActivitySource: String, Codable {
    case manual = "Manual"
    case healthKit = "Apple Health"
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
    /// V5. Fully qualified inline default so lightweight migration can fill existing rows.
    var kind: ExerciseKind = ExerciseKind.strength

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
        kind: ExerciseKind = .strength,
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
        self.kind = kind
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
    var skipped: Bool = false
    var wasDeload: Bool = false
    var deloadPercent: Double?

    // V5: all optional (nil on existing rows). Units are always SI so data from Health needs
    // no conversion: distance and elevation in meters, duration in seconds, heart rate in bpm,
    // calories in kcal. Screens convert for display using the user's unit setting.
    var startTime: Date?
    var endTime: Date?
    var distance: Double?
    var duration: TimeInterval?
    var elevationGain: Double?
    var avgHeartRate: Double?
    var maxHeartRate: Double?
    var caloriesBurned: Double?
    var dataSource: ActivitySource?
    /// Identifier in the source system, for example the Apple Health workout UUID. Used to
    /// avoid importing the same activity twice.
    var externalID: String?
    var plannedDistance: Double?
    var plannedDuration: TimeInterval?

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
        skipped: Bool = false,
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
        self.skipped = skipped
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

// MARK: - Derived helpers (computed only, nothing stored: no schema impact)

extension ExerciseSession {
    /// Finished for scheduling purposes: completed or skipped.
    var isDone: Bool { completed || skipped }

    /// At least one set has been logged as completed.
    var hasLoggedSets: Bool { sets.contains { $0.completed } }
}

extension WorkoutExercise {
    var isCardio: Bool { kind == .cardio }

    /// Quick (freeform) workouts are created with no planned sets or reps and log sets as they go.
    var isFreeform: Bool { targetSets == 0 }

    /// The session to show for a week: the first one not done yet, otherwise the last one.
    /// Most exercises have one session per week; single-lift progressions can have several.
    func session(forWeek week: Int) -> ExerciseSession? {
        let inWeek = sessions
            .filter { $0.weekNumber == week }
            .sorted { $0.sessionNumber < $1.sessionNumber }
        return inWeek.first(where: { !$0.isDone }) ?? inWeek.last
    }
}

extension WorkoutDay {
    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// One session per exercise (see `WorkoutExercise.session(forWeek:)`).
    func sessions(forWeek week: Int) -> [ExerciseSession] {
        exercises.compactMap { $0.session(forWeek: week) }
    }

    func isFinished(forWeek week: Int) -> Bool {
        sessions(forWeek: week).allSatisfy { $0.isDone }
    }
}

extension Workout {
    var sortedDays: [WorkoutDay] {
        days.sorted { $0.dayNumber < $1.dayNumber }
    }

    /// First day (by day number) that has sessions this week and is not finished.
    func nextDay(forWeek week: Int) -> WorkoutDay? {
        sortedDays.first { day in
            !day.sessions(forWeek: week).isEmpty && !day.isFinished(forWeek: week)
        }
    }

    var nextDay: WorkoutDay? { nextDay(forWeek: currentWeek) }

    func hasPausedSession(forWeek week: Int) -> Bool {
        days.contains { day in
            day.sessions(forWeek: week).contains { $0.paused && !$0.isDone }
        }
    }
}
