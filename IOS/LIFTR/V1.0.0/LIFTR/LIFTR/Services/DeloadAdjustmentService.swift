import Foundation
import SwiftData

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

enum DeloadAdjustmentService {

    static func analyzePerformance(session: ExerciseSession, settings: GlobalProgressionSettings) -> ProgressionAdjustment {
        let totalPlanned = session.totalPlannedReps
        let totalCompleted = session.totalCompletedReps

        guard totalPlanned > 0 else { return .continueAsPlanned }

        let percentage = (Double(totalCompleted) / Double(totalPlanned)) * 100

        if percentage >= Double(settings.excellentThreshold) {
            return .continueAsPlanned
        } else if percentage >= Double(settings.goodThreshold) {
            return .repeatWeight
        } else if percentage >= Double(settings.adjustmentThreshold) {
            return .reduceBy(percent: settings.reductionPercent)
        } else {
            return .deload(percent: settings.deloadPercent)
        }
    }

    static func applyAdjustment(
        _ adjustment: ProgressionAdjustment,
        session: ExerciseSession,
        workoutExercise: WorkoutExercise,
        settings: GlobalProgressionSettings
    ) {
        let useMetric = settings.useMetric

        switch adjustment {
        case .continueAsPlanned:
            break

        case .repeatWeight:
            let nextWeekSessions = workoutExercise.sessions.filter { $0.weekNumber == session.weekNumber + 1 }
            let roundedWeight = session.plannedWeight.roundedToNearestFive(useMetric: useMetric)
            for nextSession in nextWeekSessions {
                nextSession.plannedWeight = roundedWeight
                for set in nextSession.sets {
                    set.targetWeight = roundedWeight
                }
            }

        case .reduceBy(let percent):
            adjustFutureWeights(reductionPercent: percent, session: session, workoutExercise: workoutExercise, settings: settings)

        case .deload(let percent):
            insertDeloadWeek(reductionPercent: percent, session: session, workoutExercise: workoutExercise, settings: settings)
        }
    }

    static func adjustFutureWeights(
        reductionPercent: Double,
        session: ExerciseSession,
        workoutExercise: WorkoutExercise,
        settings: GlobalProgressionSettings
    ) {
        let useMetric = settings.useMetric
        let multiplier = 1.0 - (reductionPercent / 100.0)

        let futureSessions = workoutExercise.sessions.filter { $0.weekNumber > session.weekNumber }
        for futureSession in futureSessions {
            let adjustedWeight = (futureSession.plannedWeight * multiplier).roundedToNearestFive(useMetric: useMetric)
            futureSession.plannedWeight = adjustedWeight
            for set in futureSession.sets {
                set.targetWeight = adjustedWeight
            }
        }
    }

    static func insertDeloadWeek(
        reductionPercent: Double,
        session: ExerciseSession,
        workoutExercise: WorkoutExercise,
        settings: GlobalProgressionSettings
    ) {
        let useMetric = settings.useMetric
        let deloadWeight = (session.plannedWeight * (1.0 - (reductionPercent / 100.0))).roundedToNearestFive(useMetric: useMetric)

        let nextWeekSessions = workoutExercise.sessions.filter { $0.weekNumber == session.weekNumber + 1 }
        for nextSession in nextWeekSessions {
            nextSession.plannedWeight = deloadWeight
            nextSession.wasDeload = true
            nextSession.deloadPercent = reductionPercent
            for set in nextSession.sets {
                set.targetWeight = deloadWeight
            }
        }
    }

    static func checkAndAdvanceWeek(session: ExerciseSession, workoutExercise: WorkoutExercise) {
        guard let workout = workoutExercise.day?.workout else { return }

        // Doing a session that was skipped means it is no longer skipped.
        if session.completed { session.skipped = false }

        let allSessions = workout.days
            .flatMap { $0.exercises }
            .flatMap { $0.sessions }
        let sessionsThisWeek = allSessions.filter { $0.weekNumber == session.weekNumber }

        // A skipped session counts as done for week advance only.
        // It stays recorded as skipped, never as completed.
        let doneThisWeek = sessionsThisWeek.filter { $0.completed || $0.skipped }.count

        // Only finishing the CURRENT week advances it, so re-skipping or re-completing
        // a session from an earlier week can never advance the workout twice.
        if session.weekNumber == workout.currentWeek
            && doneThisWeek >= sessionsThisWeek.count
            && workout.currentWeek < workout.totalWeeks {
            workout.currentWeek += 1
        }

        // Every session in the whole workout is completed or skipped.
        if !allSessions.isEmpty && allSessions.allSatisfy({ $0.completed || $0.skipped }) {
            workout.status = .completed
        }
    }
}
