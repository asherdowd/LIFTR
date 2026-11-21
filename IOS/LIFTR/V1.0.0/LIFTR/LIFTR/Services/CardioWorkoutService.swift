import Foundation
import SwiftData

// MARK: - Cardio Workout Service
// The one place that builds a finished cardio activity in the shared Workout model:
// Workout (completed, 1 week) > Day > cardio exercise > one completed session carrying the
// numbers. Used by Apple Health import, manual "Log Cardio" and the Debug sample data, so the
// three can never drift apart. Units are SI (meters, seconds, bpm, kcal). No saving here
// except in `startLiveWorkout` and `finishLiveWorkout`; callers that batch save once.

/// Everything stored for one finished cardio activity.
struct CardioActivityRecord {
    /// Exercise and Workout name, for example "Running". Manual logs use the same names as
    /// Health imports so the two group together.
    var name: String
    /// Session date (Health: the start time; manual: when it was logged).
    var date: Date
    var completedDate: Date
    /// Real clock times. Nil for manual logs, where only the duration is known.
    var startTime: Date? = nil
    var endTime: Date? = nil
    var duration: TimeInterval? = nil
    var distance: Double? = nil
    var elevationGain: Double? = nil
    var elevationLoss: Double? = nil
    var maxSpeed: Double? = nil
    var avgHeartRate: Double? = nil
    var maxHeartRate: Double? = nil
    var caloriesBurned: Double? = nil
    var dataSource: ActivitySource
    var externalID: String? = nil
    /// Notes on the session.
    var notes: String? = nil
    /// Notes on the Workout (the Debug sample data uses this for its marker).
    var workoutNotes: String? = nil
}

enum CardioWorkoutService {

    // MARK: Build

    /// Inserts a completed quick Workout holding one cardio exercise and one completed session.
    /// Does not save.
    @discardableResult
    static func createFinishedWorkout(
        _ record: CardioActivityRecord,
        exercise: Exercise,
        context: ModelContext
    ) -> Workout {
        let workout = Workout(
            name: record.name,
            templateType: .custom,
            status: .completed,
            totalWeeks: 1,
            startDate: Calendar.current.startOfDay(for: record.date),
            notes: record.workoutNotes
        )
        context.insert(workout)

        let day = WorkoutDay(name: "Workout", dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            orderIndex: 0,
            progressionStyle: .linear,
            startingWeight: 0,
            targetSets: 0,
            targetReps: 0,
            kind: .cardio
        )
        workoutExercise.day = day
        day.exercises.append(workoutExercise)
        context.insert(workoutExercise)

        let session = ExerciseSession(
            date: record.date,
            weekNumber: 1,
            sessionNumber: 1,
            plannedWeight: 0,
            plannedSets: 0,
            plannedReps: 0,
            completed: true,
            completedDate: record.completedDate,
            notes: record.notes
        )
        session.startTime = record.startTime
        session.endTime = record.endTime
        session.duration = record.duration
        session.distance = record.distance
        session.elevationGain = record.elevationGain
        session.elevationLoss = record.elevationLoss
        session.maxSpeed = record.maxSpeed
        session.avgHeartRate = record.avgHeartRate
        session.maxHeartRate = record.maxHeartRate
        session.caloriesBurned = record.caloriesBurned
        session.dataSource = record.dataSource
        session.externalID = record.externalID
        session.workoutExercise = workoutExercise
        workoutExercise.sessions.append(session)
        context.insert(session)

        return workout
    }

    // MARK: Live logging

    /// A live cardio workout that was just started (Start Workout > Single Workout > Cardio).
    struct LiveStart {
        let workout: Workout
        let workoutExercise: WorkoutExercise
        let session: ExerciseSession
    }

    /// Creates an in-progress quick cardio Workout whose session clock starts now.
    /// Built with `createFinishedWorkout` (so the structure stays in one place), then reopened:
    /// the workout is active and the session is not completed until `finishLiveWorkout`.
    static func startLiveWorkout(
        type: CardioType,
        customName: String,
        into context: ModelContext,
        now: Date = Date()
    ) throws -> LiveStart {
        let name = activityName(for: type, custom: customName)
        let exercise = try findOrCreateExercise(named: name, in: context)

        let record = CardioActivityRecord(
            name: name,
            date: now,
            completedDate: now,
            startTime: now,
            dataSource: .manual
        )
        let workout = createFinishedWorkout(record, exercise: exercise, context: context)
        workout.status = .active

        guard let workoutExercise = workout.days.first?.exercises.first,
              let session = workoutExercise.sessions.first else {
            throw CocoaError(.coderInvalidValue)
        }
        session.completed = false
        session.completedDate = nil

        try context.save()
        return LiveStart(workout: workout, workoutExercise: workoutExercise, session: session)
    }

    /// Saves the numbers entered when a live cardio session is stopped and completes it.
    /// `checkAndAdvanceWeek` stamps the end time and marks the single-session Workout completed.
    static func finishLiveWorkout(
        session: ExerciseSession,
        workoutExercise: WorkoutExercise,
        durationSeconds: TimeInterval,
        distanceMeters: Double?,
        notes: String,
        into context: ModelContext,
        now: Date = Date()
    ) throws {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        session.duration = max(0, durationSeconds)
        session.distance = distanceMeters
        session.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        session.completed = true
        session.completedDate = now
        session.paused = false

        DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
        try context.save()
    }

    /// The cardio type for an exercise name made by `activityName` (the live screen only has the
    /// exercise). Names that are not one of the fixed types are Free Cardio.
    static func cardioType(forExerciseName name: String) -> CardioType {
        switch name.lowercased() {
        case "running": return .running
        case "swimming": return .swimming
        case "calisthenics": return .calisthenics
        case "crossfit": return .crossfit
        default: return .freeCardio
        }
    }

    /// Same names Apple Health imports use ("Running", "Swimming"), so activities group together.
    static func activityName(for type: CardioType, custom: String) -> String {
        switch type {
        case .running: return "Running"
        case .swimming: return "Swimming"
        case .calisthenics: return "Calisthenics"
        case .crossfit: return "CrossFit"
        case .freeCardio:
            let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Cardio" : trimmed
        }
    }

    /// Distance as typed in the form, converted to meters. Only running (km or miles) and
    /// swimming (meters or yards) have a distance field.
    static func meters(fromEntered value: Double, type: CardioType, useMetric: Bool) -> Double? {
        switch type {
        case .running:
            return useMetric ? value * 1_000 : value * 1_609.344
        case .swimming:
            return useMetric ? value : value * 0.9144
        case .calisthenics, .crossfit, .freeCardio:
            return nil
        }
    }

    /// Reuses an Exercise with the same name (case-insensitive), otherwise creates one.
    static func findOrCreateExercise(named name: String, in context: ModelContext) throws -> Exercise {
        let existing = try context.fetch(FetchDescriptor<Exercise>())
        for exercise in existing where exercise.name.lowercased() == name.lowercased() {
            return exercise
        }
        let created = Exercise(name: name, coreType: nil)
        context.insert(created)
        return created
    }
}
