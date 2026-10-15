import Foundation
import SwiftData

// MARK: - Health Import Service
// Turns activities read from Health into the shared Workout model. Each imported activity
// becomes a finished quick Workout: one day, one cardio exercise, one completed session
// carrying the numbers. No HealthKit types here, so it can be unit tested with an in-memory
// container.

enum HealthImportService {

    /// Creates a Workout per activity that has not been imported yet (matched by
    /// `externalID` on existing sessions). Returns how many were created. Does not save;
    /// the caller saves.
    @discardableResult
    static func importActivities(
        _ activities: [ImportedActivity],
        into context: ModelContext
    ) throws -> Int {
        let existingSessions = try context.fetch(FetchDescriptor<ExerciseSession>())
        var knownIDs = Set(existingSessions.compactMap { $0.externalID })
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())

        var exercisesByName: [String: Exercise] = [:]
        for exercise in existingExercises {
            exercisesByName[exercise.name.lowercased()] = exercise
        }

        var created = 0
        for activity in activities where !knownIDs.contains(activity.externalID) {
            let exercise: Exercise
            if let existing = exercisesByName[activity.activityName.lowercased()] {
                exercise = existing
            } else {
                exercise = Exercise(name: activity.activityName, coreType: nil)
                context.insert(exercise)
                exercisesByName[activity.activityName.lowercased()] = exercise
            }

            let workout = Workout(
                name: activity.activityName,
                templateType: .custom,
                status: .completed,
                totalWeeks: 1,
                startDate: Calendar.current.startOfDay(for: activity.start)
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
                date: activity.start,
                weekNumber: 1,
                sessionNumber: 1,
                plannedWeight: 0,
                plannedSets: 0,
                plannedReps: 0,
                completed: true,
                completedDate: activity.end
            )
            session.startTime = activity.start
            session.endTime = activity.end
            session.duration = activity.duration
            session.distance = activity.distance
            session.elevationGain = activity.elevationGain
            session.elevationLoss = activity.elevationLoss
            session.maxSpeed = activity.maxSpeed
            session.avgHeartRate = activity.avgHeartRate
            session.maxHeartRate = activity.maxHeartRate
            session.caloriesBurned = activity.caloriesBurned
            session.dataSource = .healthKit
            session.externalID = activity.externalID
            session.workoutExercise = workoutExercise
            workoutExercise.sessions.append(session)
            context.insert(session)

            knownIDs.insert(activity.externalID)
            created += 1
        }
        return created
    }
}
