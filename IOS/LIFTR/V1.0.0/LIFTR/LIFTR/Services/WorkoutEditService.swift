import Foundation

// MARK: - Workout Edit Service
// Rules for manual edits made on the Workout detail/edit screens (step 8e).
// Every change that marks a session done or not done goes through here so the week and
// the Workout status stay consistent with `DeloadAdjustmentService.checkAndAdvanceWeek`.
// Pure model logic: no fetches, no saves (the caller saves).

enum WorkoutEditService {

    /// Mark a session completed or not completed by hand.
    /// Completing clears skipped and paused and stamps a completed date if there is none.
    /// Un-completing clears the completed date. If the Workout was already marked completed,
    /// it goes back to active. `currentWeek` is never moved backwards automatically.
    static func setCompleted(_ done: Bool, session: ExerciseSession) {
        if done {
            session.completed = true
            session.completedDate = session.completedDate ?? Date()
            session.skipped = false
            session.paused = false
        } else {
            session.completed = false
            session.completedDate = nil
            session.endTime = nil
        }
        reevaluate(session)
    }

    /// Mark a session skipped or not skipped by hand.
    /// Skipping clears completed, the completed date and paused.
    static func setSkipped(_ skipped: Bool, session: ExerciseSession) {
        if skipped {
            session.skipped = true
            session.completed = false
            session.completedDate = nil
            session.paused = false
        } else {
            session.skipped = false
        }
        reevaluate(session)
    }

    /// Set the current week, kept inside 1...totalWeeks.
    static func setCurrentWeek(_ week: Int, workout: Workout) {
        workout.currentWeek = min(max(week, 1), max(workout.totalWeeks, 1))
    }

    private static func reevaluate(_ session: ExerciseSession) {
        guard let workoutExercise = session.workoutExercise else { return }
        if session.isDone {
            DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
        } else if let workout = workoutExercise.day?.workout, workout.status == .completed {
            workout.status = .active
        }
    }
}
