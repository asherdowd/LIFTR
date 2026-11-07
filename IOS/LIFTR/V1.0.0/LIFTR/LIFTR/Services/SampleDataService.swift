import Foundation
import SwiftData

#if DEBUG
// MARK: - Sample Data Service (Debug builds only)
// Fills the store with about 22 weeks of history so Analytics, History, Home PRs and Recent
// can be checked with realistic and edge-case data. Every Workout it creates carries
// `marker` in its notes, and `remove` deletes only those, so real data is never touched.
// Compiled out of Release builds (TestFlight / App Store): nothing here ships.
//
// Deliberate cases:
// - Two finished programs and one active program, each with new PRs on all four core lifts.
// - Program B starts BELOW program A's best weights (lower weights), then climbs past them.
// - Active program C: a skipped session, partial reps, a zero-rep set, a set that was never
//   completed, a set with no weight, and a session still pending today.
// - A non-core lift (Barbell Row) heavier than every core lift: must NOT count as a PR.
// - Quick (freeform) workouts, one of them a heavier squat than any program (PR from a quick workout).
// - Cardio runs and rides with distance, time, elevation and heart rate.

enum SampleDataService {

    static let marker = "[sample data]"

    // MARK: Public

    static func hasSampleData(in context: ModelContext) throws -> Bool {
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        for workout in workouts where workout.notes == marker {
            return true
        }
        return false
    }

    /// Creates the sample Workouts and saves. Returns how many Workouts were created;
    /// 0 when sample data is already loaded (loading twice is refused).
    @discardableResult
    static func load(into context: ModelContext, now: Date = Date()) throws -> Int {
        if try hasSampleData(in: context) { return 0 }

        var exercises = try context.fetch(FetchDescriptor<Exercise>())
        var created = 0

        for plan in programPlans() {
            buildProgram(plan, now: now, context: context, exercises: &exercises)
            created += 1
        }
        for quick in quickPlans() {
            buildQuickWorkout(quick, now: now, context: context, exercises: &exercises)
            created += 1
        }
        for cardio in cardioPlans() {
            buildCardio(cardio, now: now, context: context, exercises: &exercises)
            created += 1
        }

        try context.save()
        return created
    }

    /// Deletes only the Workouts carrying the sample marker (days, exercises, sessions and
    /// sets go with them). Returns how many were deleted. Exercise rows are left in place.
    @discardableResult
    static func remove(from context: ModelContext) throws -> Int {
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        var removed = 0
        for workout in workouts where workout.notes == marker {
            context.delete(workout)
            removed += 1
        }
        try context.save()
        return removed
    }

    // MARK: Plans

    private struct LiftPlan {
        let name: String
        let core: ExerciseCoreType?
        let weights: [Double]   // planned weight for each week
        let sets: Int
        let reps: Int
    }

    private struct ExtraSet {
        let reps: Int?
        let weight: Double?
        let completed: Bool
    }

    private struct ProgramPlan {
        let name: String
        let template: TemplateType
        let finished: Bool
        let startDaysAgo: Int
        let doneThroughWeek: Int
        let currentWeek: Int
        let lifts: [LiftPlan]
        /// "Lift name-week" keys of sessions that were skipped.
        var skipped: Set<String> = []
        /// "Lift name-week" -> reps in the last two sets (the rest are full).
        var shortReps: [String: Int] = [:]
        /// "Lift name-week" -> extra odd sets appended to the session.
        var extraSets: [String: [ExtraSet]] = [:]
    }

    private static func programPlans() -> [ProgramPlan] {
        let programA = ProgramPlan(
            name: "Sample: Starting Strength A",
            template: .startingStrength,
            finished: true,
            startDaysAgo: 154,
            doneThroughWeek: 8,
            currentWeek: 8,
            lifts: [
                LiftPlan(name: "Squat", core: .squat, weights: [135, 145, 155, 165, 175, 185, 195, 205], sets: 3, reps: 5),
                LiftPlan(name: "Bench Press", core: .benchPress, weights: [95, 100, 105, 110, 115, 120, 125, 130], sets: 3, reps: 5),
                LiftPlan(name: "Deadlift", core: .deadlift, weights: [185, 195, 205, 215, 225, 235, 245, 255], sets: 1, reps: 5),
                LiftPlan(name: "Overhead Press", core: .overheadPress, weights: [65, 67.5, 70, 72.5, 75, 77.5, 80, 82.5], sets: 3, reps: 5)
            ]
        )

        // Starts below A's best on every lift (lower weights), dips, then passes A (new PRs).
        // Barbell Row is heavier than any core lift but has no core type: never a PR.
        let programB = ProgramPlan(
            name: "Sample: Madcow B",
            template: .madcow,
            finished: true,
            startDaysAgo: 98,
            doneThroughWeek: 8,
            currentWeek: 8,
            lifts: [
                LiftPlan(name: "Squat", core: .squat, weights: [185, 175, 165, 195, 205, 215, 225, 235], sets: 5, reps: 5),
                LiftPlan(name: "Bench Press", core: .benchPress, weights: [120, 115, 125, 130, 135, 140, 145, 150], sets: 5, reps: 5),
                LiftPlan(name: "Deadlift", core: .deadlift, weights: [245, 225, 235, 255, 265, 275, 285, 295], sets: 1, reps: 5),
                LiftPlan(name: "Overhead Press", core: .overheadPress, weights: [75, 70, 72.5, 77.5, 80, 85, 87.5, 90], sets: 3, reps: 5),
                LiftPlan(name: "Barbell Row", core: nil, weights: [315, 325, 335, 345, 355, 365, 385, 405], sets: 3, reps: 5)
            ]
        )

        var programC = ProgramPlan(
            name: "Sample: 5/3/1 Active",
            template: .fiveThreeOne,
            finished: false,
            startDaysAgo: 21,
            doneThroughWeek: 3,
            currentWeek: 4,
            lifts: [
                LiftPlan(name: "Squat", core: .squat, weights: [245, 250, 255, 260, 265, 270], sets: 3, reps: 5),
                LiftPlan(name: "Bench Press", core: .benchPress, weights: [150, 155, 152.5, 157.5, 160, 162.5], sets: 3, reps: 5),
                LiftPlan(name: "Deadlift", core: .deadlift, weights: [295, 300, 305, 310, 315, 320], sets: 1, reps: 5),
                LiftPlan(name: "Overhead Press", core: .overheadPress, weights: [90, 92.5, 95, 97.5, 100, 102.5], sets: 3, reps: 5)
            ]
        )
        programC.skipped = ["Bench Press-2"]
        programC.shortReps = ["Squat-3": 3]
        programC.extraSets = [
            "Deadlift-3": [
                ExtraSet(reps: 0, weight: 400, completed: true),     // zero reps: ignored
                ExtraSet(reps: 5, weight: 500, completed: false),    // never completed: ignored
                ExtraSet(reps: 5, weight: nil, completed: true)      // no weight logged: ignored
            ]
        ]

        return [programA, programB, programC]
    }

    private struct QuickPlan {
        let daysAgo: Int
        let exercise: String
        let core: ExerciseCoreType?
        let sets: [(reps: Int, weight: Double)]
    }

    private static func quickPlans() -> [QuickPlan] {
        return [
            QuickPlan(daysAgo: 45, exercise: "Barbell Curl", core: nil, sets: [(10, 60), (10, 60), (8, 65)]),
            QuickPlan(daysAgo: 30, exercise: "Squat", core: .squat, sets: [(3, 275), (3, 275), (2, 285)]),
            QuickPlan(daysAgo: 12, exercise: "Bench Press", core: .benchPress, sets: [(5, 135), (5, 135), (5, 135)])
        ]
    }

    private struct CardioPlan {
        let daysAgo: Int
        let name: String
        let meters: Double
        let seconds: Double
        let gain: Double
        let avgHR: Double
        let maxHR: Double
        let kcal: Double
    }

    private static func cardioPlans() -> [CardioPlan] {
        return [
            CardioPlan(daysAgo: 4, name: "Running", meters: 8_047, seconds: 2_700, gain: 120, avgHR: 152, maxHR: 176, kcal: 610),
            CardioPlan(daysAgo: 11, name: "Cycling", meters: 24_140, seconds: 3_900, gain: 210, avgHR: 138, maxHR: 165, kcal: 720),
            CardioPlan(daysAgo: 18, name: "Running", meters: 5_000, seconds: 1_620, gain: 40, avgHR: 158, maxHR: 181, kcal: 390),
            CardioPlan(daysAgo: 33, name: "Running", meters: 16_093, seconds: 5_700, gain: 460, avgHR: 147, maxHR: 172, kcal: 1_180),
            CardioPlan(daysAgo: 47, name: "Cycling", meters: 40_233, seconds: 6_300, gain: 380, avgHR: 141, maxHR: 168, kcal: 1_090),
            CardioPlan(daysAgo: 60, name: "Running", meters: 3_200, seconds: 1_080, gain: 15, avgHR: 149, maxHR: 170, kcal: 260)
        ]
    }

    // MARK: Builders

    private static func findOrCreateExercise(
        named name: String,
        core: ExerciseCoreType?,
        context: ModelContext,
        exercises: inout [Exercise]
    ) -> Exercise {
        for existing in exercises {
            if let core, existing.coreType == core { return existing }
        }
        for existing in exercises where existing.name.lowercased() == name.lowercased() {
            return existing
        }
        let created = Exercise(name: name, coreType: core)
        context.insert(created)
        exercises.append(created)
        return created
    }

    private static func date(daysAgo: Int, from now: Date) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) ?? now
    }

    private static func addSet(
        _ session: ExerciseSession,
        number: Int,
        targetReps: Int,
        targetWeight: Double,
        reps: Int?,
        weight: Double?,
        completed: Bool,
        context: ModelContext
    ) {
        let set = WorkoutSet(
            setNumber: number,
            targetReps: targetReps,
            targetWeight: targetWeight,
            actualReps: reps,
            actualWeight: weight,
            completed: completed
        )
        set.exerciseSession = session
        session.sets.append(set)
        context.insert(set)
    }

    private static func buildProgram(
        _ plan: ProgramPlan,
        now: Date,
        context: ModelContext,
        exercises: inout [Exercise]
    ) {
        let weeks = plan.lifts.first?.weights.count ?? 1
        let start = date(daysAgo: plan.startDaysAgo, from: now)

        let workout = Workout(
            name: plan.name,
            templateType: plan.template,
            status: plan.finished ? .completed : .active,
            totalWeeks: weeks,
            currentWeek: plan.currentWeek,
            startDate: Calendar.current.startOfDay(for: start),
            notes: marker
        )
        context.insert(workout)

        let day = WorkoutDay(name: "Day A", dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        var order = 0
        for lift in plan.lifts {
            let exercise = findOrCreateExercise(named: lift.name, core: lift.core, context: context, exercises: &exercises)
            let workoutExercise = WorkoutExercise(
                exercise: exercise,
                orderIndex: order,
                progressionStyle: .linear,
                startingWeight: lift.weights.first ?? 0,
                currentWeight: lift.weights[min(plan.currentWeek, weeks) - 1],
                targetSets: lift.sets,
                targetReps: lift.reps
            )
            workoutExercise.day = day
            day.exercises.append(workoutExercise)
            context.insert(workoutExercise)
            order += 1

            for week in 1...weeks {
                let weight = lift.weights[week - 1]
                let key = "\(lift.name)-\(week)"
                let sessionDate = Calendar.current.date(byAdding: .day, value: (week - 1) * 7, to: start) ?? start
                let isDone = week <= plan.doneThroughWeek
                let isSkipped = isDone && plan.skipped.contains(key)

                let session = ExerciseSession(
                    date: sessionDate,
                    weekNumber: week,
                    sessionNumber: week,
                    plannedWeight: weight,
                    plannedSets: lift.sets,
                    plannedReps: lift.reps,
                    completed: isDone && !isSkipped,
                    completedDate: (isDone && !isSkipped) ? sessionDate.addingTimeInterval(3_600) : nil,
                    skipped: isSkipped
                )
                if isDone && !isSkipped {
                    session.startTime = sessionDate
                    session.endTime = sessionDate.addingTimeInterval(3_600)
                }
                session.workoutExercise = workoutExercise
                workoutExercise.sessions.append(session)
                context.insert(session)

                guard isDone && !isSkipped else { continue }

                for setNumber in 1...lift.sets {
                    var reps = lift.reps
                    if let short = plan.shortReps[key], setNumber > lift.sets - 2 {
                        reps = short
                    }
                    addSet(session, number: setNumber, targetReps: lift.reps, targetWeight: weight,
                           reps: reps, weight: weight, completed: true, context: context)
                }
                var number = lift.sets
                if let extras = plan.extraSets[key] {
                    for extra in extras {
                        number += 1
                        addSet(session, number: number, targetReps: lift.reps, targetWeight: weight,
                               reps: extra.reps, weight: extra.weight, completed: extra.completed, context: context)
                    }
                }
            }
        }
    }

    private static func buildQuickWorkout(
        _ plan: QuickPlan,
        now: Date,
        context: ModelContext,
        exercises: inout [Exercise]
    ) {
        let when = date(daysAgo: plan.daysAgo, from: now)
        let workout = Workout(
            name: "Quick Workout",
            templateType: .custom,
            status: .completed,
            totalWeeks: 1,
            startDate: Calendar.current.startOfDay(for: when),
            notes: marker
        )
        context.insert(workout)

        let day = WorkoutDay(name: "Workout", dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        let exercise = findOrCreateExercise(named: plan.exercise, core: plan.core, context: context, exercises: &exercises)
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            orderIndex: 0,
            progressionStyle: .linear,
            startingWeight: 0,
            targetSets: 0,
            targetReps: 0
        )
        workoutExercise.day = day
        day.exercises.append(workoutExercise)
        context.insert(workoutExercise)

        let session = ExerciseSession(
            date: when,
            weekNumber: 1,
            sessionNumber: 1,
            plannedWeight: 0,
            plannedSets: 0,
            plannedReps: 0,
            completed: true,
            completedDate: when.addingTimeInterval(1_800)
        )
        session.startTime = when
        session.endTime = when.addingTimeInterval(1_800)
        session.workoutExercise = workoutExercise
        workoutExercise.sessions.append(session)
        context.insert(session)

        var number = 0
        for entry in plan.sets {
            number += 1
            addSet(session, number: number, targetReps: 0, targetWeight: 0,
                   reps: entry.reps, weight: entry.weight, completed: true, context: context)
        }
    }

    private static func buildCardio(
        _ plan: CardioPlan,
        now: Date,
        context: ModelContext,
        exercises: inout [Exercise]
    ) {
        let start = date(daysAgo: plan.daysAgo, from: now)
        let end = start.addingTimeInterval(plan.seconds)

        let workout = Workout(
            name: plan.name,
            templateType: .custom,
            status: .completed,
            totalWeeks: 1,
            startDate: Calendar.current.startOfDay(for: start),
            notes: marker
        )
        context.insert(workout)

        let day = WorkoutDay(name: "Workout", dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        let exercise = findOrCreateExercise(named: plan.name, core: nil, context: context, exercises: &exercises)
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
            date: start,
            weekNumber: 1,
            sessionNumber: 1,
            plannedWeight: 0,
            plannedSets: 0,
            plannedReps: 0,
            completed: true,
            completedDate: end
        )
        session.startTime = start
        session.endTime = end
        session.duration = plan.seconds
        session.distance = plan.meters
        session.elevationGain = plan.gain
        session.avgHeartRate = plan.avgHR
        session.maxHeartRate = plan.maxHR
        session.caloriesBurned = plan.kcal
        session.dataSource = .manual
        session.workoutExercise = workoutExercise
        workoutExercise.sessions.append(session)
        context.insert(session)
    }
}
#endif
