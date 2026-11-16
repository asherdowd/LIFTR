import Foundation
import SwiftData

// MARK: - Health Import Service
// Turns activities read from Health into the shared Workout model. Each imported activity
// becomes a finished quick Workout (built by CardioWorkoutService, which manual logging and
// the sample data also use). No HealthKit types here, so it can be unit tested with an in-memory
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

            let record = CardioActivityRecord(
                name: activity.activityName,
                date: activity.start,
                completedDate: activity.end,
                startTime: activity.start,
                endTime: activity.end,
                duration: activity.duration,
                distance: activity.distance,
                elevationGain: activity.elevationGain,
                elevationLoss: activity.elevationLoss,
                maxSpeed: activity.maxSpeed,
                avgHeartRate: activity.avgHeartRate,
                maxHeartRate: activity.maxHeartRate,
                caloriesBurned: activity.caloriesBurned,
                dataSource: .healthKit,
                externalID: activity.externalID
            )
            CardioWorkoutService.createFinishedWorkout(record, exercise: exercise, context: context)

            knownIDs.insert(activity.externalID)
            created += 1
        }
        return created
    }
}
