import Foundation

// MARK: - Analytics Service
// Pure functions behind the Overview, Progress and Goals tabs. They read the new Workout model
// only (strength sessions; cardio stats come later with #39). No fetches and no writes, so
// every rule can be unit tested with an in-memory container.
//
// Set rule (same as PR totals): a set counts when it is completed, has reps above zero and a
// logged weight. Skipped sessions never count. Quick (freeform) sessions count for volume and
// max weight but not for performance %, because they have no plan to compare against.

enum AnalyticsService {

    // MARK: Sessions

    /// Finished strength sessions inside the period, oldest first. `exerciseName` nil = all.
    static func completedStrengthSessions(
        workouts: [Workout],
        period: TimePeriod,
        exerciseName: String? = nil,
        now: Date = Date()
    ) -> [ExerciseSession] {
        let range = period.dateRange(from: now)
        return workouts
            .flatMap { $0.days }
            .flatMap { $0.exercises }
            .filter { !$0.isCardio && (exerciseName == nil || $0.exercise.name == exerciseName) }
            .flatMap { $0.sessions }
            .filter { session in
                let date = sortDate(session)
                return session.completed && !session.skipped && date >= range.start && date <= range.end
            }
            .sorted { sortDate($0) < sortDate($1) }
    }

    /// Names of the strength exercises across all Workouts, for the exercise filter.
    static func strengthExerciseNames(in workouts: [Workout]) -> [String] {
        let names = workouts
            .flatMap { $0.days }
            .flatMap { $0.exercises }
            .filter { !$0.isCardio }
            .map { $0.exercise.name }
        return Array(Set(names)).sorted()
    }

    // MARK: Numbers

    /// Sum of reps x weight over the qualifying sets of one session.
    static func volume(_ session: ExerciseSession) -> Double {
        qualifyingSets(session).reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    /// Heaviest qualifying set of one session, 0 when none.
    static func maxWeight(_ session: ExerciseSession) -> Double {
        qualifyingSets(session).map { $0.weight }.max() ?? 0
    }

    /// Sessions that have a plan to compare against (not quick workouts).
    static func performanceSessions(_ sessions: [ExerciseSession]) -> [ExerciseSession] {
        sessions.filter { !($0.workoutExercise?.isFreeform ?? false) }
    }

    static func averagePerformance(_ sessions: [ExerciseSession]) -> Double {
        let planned = performanceSessions(sessions)
        guard !planned.isEmpty else { return 0 }
        return planned.reduce(0) { $0 + $1.performancePercentage } / Double(planned.count)
    }

    /// Times a core lift's best set beat the earlier best inside the given sessions.
    /// The first session of a lift sets the baseline and is not counted. Exercises without a
    /// core type are ignored, as in PR totals.
    static func prCount(_ sessions: [ExerciseSession]) -> Int {
        var count = 0
        var best: [ExerciseCoreType: Double] = [:]
        for session in sessions.sorted(by: { sortDate($0) < sortDate($1) }) {
            guard let core = session.workoutExercise?.exercise.coreType else { continue }
            let weight = maxWeight(session)
            guard weight > 0 else { continue }
            if let previous = best[core] {
                if weight > previous {
                    count += 1
                    best[core] = weight
                }
            } else {
                best[core] = weight
            }
        }
        return count
    }

    // MARK: Chart data

    static func volumeByDay(_ sessions: [ExerciseSession], calendar: Calendar = .current) -> [(date: Date, volume: Int)] {
        Dictionary(grouping: sessions) { calendar.startOfDay(for: sortDate($0)) }
            .map { date, daySessions in
                (date: date, volume: Int(daySessions.reduce(0) { $0 + volume($1) }.rounded()))
            }
            .sorted { $0.date < $1.date }
    }

    static func maxWeightByDay(_ sessions: [ExerciseSession], calendar: Calendar = .current) -> [(date: Date, weight: Double)] {
        Dictionary(grouping: sessions) { calendar.startOfDay(for: sortDate($0)) }
            .map { date, daySessions in
                (date: date, weight: daySessions.map { maxWeight($0) }.max() ?? 0)
            }
            .sorted { $0.date < $1.date }
    }

    static func exerciseStats(_ sessions: [ExerciseSession]) -> [ExerciseStat] {
        Dictionary(grouping: sessions) { $0.workoutExercise?.exercise.name ?? "Unknown" }
            .map { name, group in
                ExerciseStat(
                    name: name,
                    sessions: group.count,
                    totalVolume: Int(group.reduce(0) { $0 + volume($1) }.rounded()),
                    maxWeight: group.map { maxWeight($0) }.max() ?? 0,
                    avgPerformance: averagePerformance(group)
                )
            }
            .sorted { $0.totalVolume > $1.totalVolume }
    }

    // MARK: Goals

    /// Active Workouts that have at least one planned strength exercise (quick workouts and
    /// cardio-only workouts have no goal to show).
    static func goalWorkouts(_ workouts: [Workout]) -> [Workout] {
        workouts.filter { $0.status == .active && !goalExercises(of: $0).isEmpty }
    }

    /// The planned strength exercises of a Workout, in order.
    static func goalExercises(of workout: Workout) -> [WorkoutExercise] {
        workout.sortedDays
            .flatMap { $0.sortedExercises }
            .filter { !$0.isCardio && !$0.isFreeform }
    }

    // MARK: Private

    private static func qualifyingSets(_ session: ExerciseSession) -> [(reps: Int, weight: Double)] {
        session.sets.compactMap { set in
            guard set.completed, let reps = set.actualReps, reps > 0, let weight = set.actualWeight else { return nil }
            return (reps: reps, weight: weight)
        }
    }

    private static func sortDate(_ session: ExerciseSession) -> Date {
        session.completedDate ?? session.date
    }
}
