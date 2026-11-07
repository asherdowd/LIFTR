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
        var result: [ExerciseSession] = []
        for workout in workouts {
            for day in workout.days {
                for workoutExercise in day.exercises {
                    if workoutExercise.isCardio { continue }
                    if let exerciseName, workoutExercise.exercise.name != exerciseName { continue }
                    for session in workoutExercise.sessions {
                        guard session.completed, !session.skipped else { continue }
                        let date = sortDate(session)
                        if date >= range.start && date <= range.end {
                            result.append(session)
                        }
                    }
                }
            }
        }
        return result.sorted { sortDate($0) < sortDate($1) }
    }

    /// Names of the strength exercises across all Workouts, for the exercise filter.
    static func strengthExerciseNames(in workouts: [Workout]) -> [String] {
        var names = Set<String>()
        for workout in workouts {
            for day in workout.days {
                for workoutExercise in day.exercises where !workoutExercise.isCardio {
                    names.insert(workoutExercise.exercise.name)
                }
            }
        }
        return names.sorted()
    }

    // MARK: Numbers

    /// Sum of reps x weight over the qualifying sets of one session.
    static func volume(_ session: ExerciseSession) -> Double {
        var total: Double = 0
        for set in qualifyingSets(session) {
            total += Double(set.reps) * set.weight
        }
        return total
    }

    /// Heaviest qualifying set of one session, 0 when none.
    static func maxWeight(_ session: ExerciseSession) -> Double {
        var heaviest: Double = 0
        for set in qualifyingSets(session) {
            heaviest = max(heaviest, set.weight)
        }
        return heaviest
    }

    /// Sessions that have a plan to compare against (not quick workouts).
    static func performanceSessions(_ sessions: [ExerciseSession]) -> [ExerciseSession] {
        sessions.filter { !($0.workoutExercise?.isFreeform ?? false) }
    }

    static func averagePerformance(_ sessions: [ExerciseSession]) -> Double {
        let planned = performanceSessions(sessions)
        guard !planned.isEmpty else { return 0 }
        var total: Double = 0
        for session in planned {
            total += session.performancePercentage
        }
        return total / Double(planned.count)
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

    /// Total volume of the sessions, rounded to whole units.
    static func totalVolume(_ sessions: [ExerciseSession]) -> Int {
        var total: Double = 0
        for session in sessions {
            total += volume(session)
        }
        return Int(total.rounded())
    }

    // MARK: Chart data

    static func volumeByDay(_ sessions: [ExerciseSession], calendar: Calendar = .current) -> [(date: Date, volume: Int)] {
        var totals: [Date: Double] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: sortDate(session))
            totals[day, default: 0] += volume(session)
        }
        var result: [(date: Date, volume: Int)] = []
        for (day, total) in totals {
            result.append((date: day, volume: Int(total.rounded())))
        }
        return result.sorted { $0.date < $1.date }
    }

    static func maxWeightByDay(_ sessions: [ExerciseSession], calendar: Calendar = .current) -> [(date: Date, weight: Double)] {
        var best: [Date: Double] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: sortDate(session))
            best[day] = max(best[day] ?? 0, maxWeight(session))
        }
        var result: [(date: Date, weight: Double)] = []
        for (day, weight) in best {
            result.append((date: day, weight: weight))
        }
        return result.sorted { $0.date < $1.date }
    }

    static func exerciseStats(_ sessions: [ExerciseSession]) -> [ExerciseStat] {
        var groups: [String: [ExerciseSession]] = [:]
        for session in sessions {
            let name: String = session.workoutExercise?.exercise.name ?? "Unknown"
            groups[name, default: []].append(session)
        }

        var stats: [ExerciseStat] = []
        for (name, group) in groups {
            var totalVolume: Double = 0
            var heaviest: Double = 0
            for session in group {
                totalVolume += volume(session)
                heaviest = max(heaviest, maxWeight(session))
            }
            stats.append(ExerciseStat(
                name: name,
                sessions: group.count,
                totalVolume: Int(totalVolume.rounded()),
                maxWeight: heaviest,
                avgPerformance: averagePerformance(group)
            ))
        }
        return stats.sorted { $0.totalVolume > $1.totalVolume }
    }

    // MARK: Goals

    /// Active Workouts that have at least one planned strength exercise (quick workouts and
    /// cardio-only workouts have no goal to show).
    static func goalWorkouts(_ workouts: [Workout]) -> [Workout] {
        var result: [Workout] = []
        for workout in workouts where workout.status == .active {
            if !goalExercises(of: workout).isEmpty {
                result.append(workout)
            }
        }
        return result
    }

    /// The planned strength exercises of a Workout, in order.
    static func goalExercises(of workout: Workout) -> [WorkoutExercise] {
        var result: [WorkoutExercise] = []
        for day in workout.sortedDays {
            for workoutExercise in day.sortedExercises where !workoutExercise.isCardio && !workoutExercise.isFreeform {
                result.append(workoutExercise)
            }
        }
        return result
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
