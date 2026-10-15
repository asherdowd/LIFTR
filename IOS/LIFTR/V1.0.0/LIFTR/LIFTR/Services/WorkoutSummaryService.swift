import Foundation

// MARK: - Workout Summary Service
// Pure functions that read the new Workout model for the Home tab (MainView):
// PR totals, upcoming days and recent sessions. No SwiftData fetches and no writes here,
// so every rule can be unit tested with an in-memory container.

/// One row in "Upcoming Workouts": a day of a Workout for a given week that still has work to do.
struct UpcomingWorkoutDay: Identifiable {
    /// Why the row is listed. Rows sort in this order: in progress, overdue, scheduled.
    enum Status: Int {
        case inProgress   // sets already logged (or paused), listed whatever its date
        case overdue      // the workout's next unfinished day, dated before today
        case scheduled    // dated today through the upcoming window
    }

    let workout: Workout
    let day: WorkoutDay
    let week: Int
    /// Earliest planned date among the not-done sessions of this day and week.
    let date: Date
    /// Number of not-done sessions (one per exercise in the usual case).
    let pendingCount: Int
    let status: Status

    var id: String { "\(workout.id.uuidString)-\(day.id.uuidString)-\(week)" }
}

/// One row in "Recent Workouts" (Strength). Built from either the new or the legacy model.
struct RecentStrengthEntry: Identifiable {
    let id: UUID
    let name: String
    let date: Date
    let detail: String
    /// Nil for quick workouts, which have no plan to compare against.
    let percentage: Double?
}

enum WorkoutSummaryService {

    // MARK: PR totals

    /// Heaviest weight lifted for a core lift across all Workouts, including finished programs.
    /// Counts only sets that are completed, have reps above zero and a logged weight, and
    /// belong to a session that was not skipped. Exercises without a core type are ignored.
    static func maxWeight(for coreType: ExerciseCoreType, in workouts: [Workout]) -> Double {
        var best: Double = 0
        for workout in workouts {
            for day in workout.days {
                for workoutExercise in day.exercises where workoutExercise.exercise.coreType == coreType {
                    for session in workoutExercise.sessions where !session.skipped {
                        for set in session.sets where set.completed && (set.actualReps ?? 0) > 0 {
                            if let weight = set.actualWeight, weight > best {
                                best = weight
                            }
                        }
                    }
                }
            }
        }
        return best
    }

    // MARK: Upcoming

    /// Rows for Active Workouts only, one per (workout, day, week) with not-done sessions:
    /// - in progress: any day that already has logged sets or a paused session, whatever its date;
    /// - overdue: the workout's next unfinished day (current week) when it is dated before today,
    ///   at most one per workout so old weeks never pile up;
    /// - scheduled: days dated from the start of today through `withinDays` days from `now`.
    /// Sorted: in progress, overdue, scheduled; each group by date, then week, then day.
    static func upcomingDays(
        in workouts: [Workout],
        now: Date = Date(),
        withinDays: Int,
        calendar: Calendar = .current
    ) -> [UpcomingWorkoutDay] {
        let startOfToday = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: withinDays, to: now) ?? now

        var result: [UpcomingWorkoutDay] = []

        for workout in workouts where workout.status == .active {
            let nextDayID = workout.nextDay?.id
            var listed: [UpcomingWorkoutDay] = []

            for day in workout.days {
                let pending = day.exercises.flatMap { $0.sessions }.filter { !$0.isDone }

                for week in Set(pending.map { $0.weekNumber }) {
                    let inWeek = pending.filter { $0.weekNumber == week }
                    guard let earliest = inWeek.map({ $0.date }).min() else { continue }

                    let status: UpcomingWorkoutDay.Status?
                    if inWeek.contains(where: { $0.hasLoggedSets || $0.paused }) {
                        status = .inProgress
                    } else if earliest < startOfToday {
                        status = (day.id == nextDayID && week == workout.currentWeek) ? .overdue : nil
                    } else if earliest <= end {
                        status = .scheduled
                    } else {
                        status = nil
                    }

                    if let status {
                        listed.append(UpcomingWorkoutDay(
                            workout: workout, day: day, week: week,
                            date: earliest, pendingCount: inWeek.count, status: status
                        ))
                    }
                }
            }
            result.append(contentsOf: listed)
        }

        return result.sorted {
            if $0.status != $1.status { return $0.status.rawValue < $1.status.rawValue }
            if $0.date != $1.date { return $0.date < $1.date }
            if $0.week != $1.week { return $0.week < $1.week }
            return $0.day.dayNumber < $1.day.dayNumber
        }
    }

    // MARK: Recent

    /// Completed exercise sessions from every Workout (any status), newest first.
    static func recentSessions(in workouts: [Workout], limit: Int) -> [ExerciseSession] {
        let completed = workouts
            .flatMap { $0.days }
            .flatMap { $0.exercises }
            .flatMap { $0.sessions }
            .filter { $0.completed }
            .sorted { sortDate($0) > sortDate($1) }
        return Array(completed.prefix(limit))
    }

    /// Recent entries from the new Workouts and the legacy WorkoutSessions, mixed, newest first.
    static func recentEntries(
        workouts: [Workout],
        legacySessions: [WorkoutSession],
        limit: Int
    ) -> [RecentStrengthEntry] {
        var entries: [RecentStrengthEntry] = []

        for session in recentSessions(in: workouts, limit: limit) {
            guard let workoutExercise = session.workoutExercise else { continue }
            let name = workoutExercise.exercise.name
            if workoutExercise.isFreeform {
                let count = session.sets.filter { $0.completed }.count
                entries.append(RecentStrengthEntry(
                    id: session.id,
                    name: name,
                    date: sortDate(session),
                    detail: "\(count) set\(count == 1 ? "" : "s")",
                    percentage: nil
                ))
            } else {
                entries.append(RecentStrengthEntry(
                    id: session.id,
                    name: name,
                    date: sortDate(session),
                    detail: "\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)",
                    percentage: session.performancePercentage
                ))
            }
        }

        for session in legacySessions where session.completed {
            entries.append(RecentStrengthEntry(
                id: session.id,
                name: session.progression?.exerciseName ?? "Unknown Exercise",
                date: session.completedDate ?? session.date,
                detail: "\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)",
                percentage: session.performancePercentage
            ))
        }

        return Array(entries.sorted { $0.date > $1.date }.prefix(limit))
    }

    private static func sortDate(_ session: ExerciseSession) -> Date {
        session.completedDate ?? session.date
    }
}
