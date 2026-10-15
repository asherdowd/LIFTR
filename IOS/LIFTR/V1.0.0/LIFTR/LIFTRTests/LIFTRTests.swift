import XCTest
import SwiftData
@testable import LIFTR

/// Tests use an in-memory container with the same model list as LIFTRApp.
/// If a model is added to LIFTRApp's ModelContainer, add it to `makeContainer()` too.
final class LiftrTests: XCTestCase {
    var container: ModelContainer!

    override func setUpWithError() throws {
        container = try Self.makeContainer()
    }

    override func tearDownWithError() throws {
        container = nil
    }

    private static func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: User.self,
            GlobalProgressionSettings.self,
            ExerciseProgressionSettings.self,
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            Workout.self,
            WorkoutDay.self,
            WorkoutExercise.self,
            ExerciseSession.self,
            Progression.self,
            WorkoutSession.self,
            WorkoutSet.self,
            CardioProgression.self,
            CardioSession.self,
            Exercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - Helpers

    /// Builds Workout -> Day -> Exercise -> sessions the same way the setup views do
    /// (set the parent AND append to the parent's array, then insert).
    /// `sessionCount` sessions are created, one per week (week 1...sessionCount).
    @MainActor
    private func makeWorkout(
        in context: ModelContext,
        totalWeeks: Int,
        sessionCount: Int
    ) -> (workout: Workout, workoutExercise: WorkoutExercise, sessions: [ExerciseSession]) {
        let exercise = Exercise(name: "Squat", coreType: .squat)
        context.insert(exercise)

        let workout = Workout(name: "Test", templateType: .custom, totalWeeks: totalWeeks)
        context.insert(workout)

        let day = WorkoutDay(name: "Day A", dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            orderIndex: 0,
            progressionStyle: .linear,
            startingWeight: 100,
            targetSets: 3,
            targetReps: 5
        )
        workoutExercise.day = day
        day.exercises.append(workoutExercise)
        context.insert(workoutExercise)

        var sessions: [ExerciseSession] = []
        for week in 1...sessionCount {
            let session = ExerciseSession(
                weekNumber: week,
                sessionNumber: week,
                plannedWeight: 100,
                plannedSets: 3,
                plannedReps: 5
            )
            session.workoutExercise = workoutExercise
            workoutExercise.sessions.append(session)
            context.insert(session)
            sessions.append(session)
        }
        return (workout, workoutExercise, sessions)
    }

    private func count<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    // MARK: - Inventory (PlateItem)

    @MainActor func testAddPlateItem() throws {
        let context = container.mainContext
        context.insert(PlateItem(weight: 45, quantity: 2))
        try context.save()

        let items = try context.fetch(FetchDescriptor<PlateItem>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.weight, 45)
        XCTAssertEqual(items.first?.quantity, 2)
    }

    @MainActor func testDeletePlateItem() throws {
        let context = container.mainContext
        let plate = PlateItem(weight: 25, quantity: 4)
        context.insert(plate)
        try context.save()

        context.delete(plate)
        try context.save()

        XCTAssertEqual(try count(PlateItem.self, in: context), 0)
    }

    // MARK: - Schema: skipped field

    @MainActor func testSkippedDefaultsToFalse() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        try context.save()

        XCTAssertFalse(sessions[0].skipped)
        XCTAssertFalse(sessions[0].completed)
    }

    @MainActor func testSkippedPersists() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        sessions[0].skipped = true
        try context.save()

        let fresh = ModelContext(container)
        let fetched = try fresh.fetch(FetchDescriptor<ExerciseSession>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(fetched[0].skipped)
        XCTAssertFalse(fetched[0].completed)
    }

    // MARK: - Schema: WorkoutSet relationship pairing (V4)

    @MainActor func testSetsPersistAndPairWithExerciseSession() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let session = sessions[0]

        for n in 1...3 {
            let set = WorkoutSet(setNumber: n, targetReps: 5, targetWeight: 100, actualReps: 5, actualWeight: 100, completed: true)
            set.exerciseSession = session
            session.sets.append(set)
            context.insert(set)
        }
        try context.save()

        let fresh = ModelContext(container)
        let fetchedSession = try XCTUnwrap(try fresh.fetch(FetchDescriptor<ExerciseSession>()).first)
        XCTAssertEqual(fetchedSession.sets.count, 3)
        for set in fetchedSession.sets {
            XCTAssertTrue(set.exerciseSession === fetchedSession)
            XCTAssertNil(set.session, "New-system sets must not attach to the legacy WorkoutSession")
        }
    }

    /// Checks that appending to ExerciseSession.sets alone (without setting set.exerciseSession)
    /// still pairs with WorkoutSet.exerciseSession, i.e. SwiftData inferred the inverse.
    @MainActor func testAppendingToSessionSetsPairsInverse() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let session = sessions[0]

        let set = WorkoutSet(setNumber: 1, targetReps: 5, targetWeight: 100)
        context.insert(set)
        session.sets.append(set)
        try context.save()

        let fresh = ModelContext(container)
        let fetchedSet = try XCTUnwrap(try fresh.fetch(FetchDescriptor<WorkoutSet>()).first)
        XCTAssertNotNil(fetchedSet.exerciseSession)
        XCTAssertNil(fetchedSet.session)
    }

    // MARK: - Schema: cascade delete

    @MainActor func testDeletingWorkoutCascadesToAllChildren() throws {
        let context = container.mainContext
        let (workout, _, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)
        for session in sessions {
            let set = WorkoutSet(setNumber: 1, targetReps: 5, targetWeight: 100)
            set.exerciseSession = session
            session.sets.append(set)
            context.insert(set)
        }
        try context.save()
        XCTAssertEqual(try count(WorkoutSet.self, in: context), 2)

        context.delete(workout)
        try context.save()

        XCTAssertEqual(try count(Workout.self, in: context), 0)
        XCTAssertEqual(try count(WorkoutDay.self, in: context), 0)
        XCTAssertEqual(try count(WorkoutExercise.self, in: context), 0)
        XCTAssertEqual(try count(ExerciseSession.self, in: context), 0)
        XCTAssertEqual(try count(WorkoutSet.self, in: context), 0)
        // The shared Exercise is referenced, not owned, so it must survive.
        XCTAssertEqual(try count(Exercise.self, in: context), 1)
    }

    @MainActor func testDeletingSessionCascadesToItsSetsOnly() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)
        for session in sessions {
            let set = WorkoutSet(setNumber: 1, targetReps: 5, targetWeight: 100)
            set.exerciseSession = session
            session.sets.append(set)
            context.insert(set)
        }
        try context.save()

        context.delete(sessions[0])
        try context.save()

        XCTAssertEqual(try count(ExerciseSession.self, in: context), 1)
        XCTAssertEqual(try count(WorkoutSet.self, in: context), 1)
    }

    // MARK: - Completion logic (DeloadAdjustmentService.checkAndAdvanceWeek)

    @MainActor func testWeekAdvancesWhenSessionCompleted() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)

        sessions[0].completed = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)

        XCTAssertEqual(workout.currentWeek, 2)
        XCTAssertEqual(workout.status, .active)
    }

    @MainActor func testWeekAdvancesWhenSessionSkipped() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)

        sessions[0].skipped = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)

        XCTAssertEqual(workout.currentWeek, 2)
        XCTAssertFalse(sessions[0].completed, "A skipped session must never be recorded as completed")
    }

    @MainActor func testWeekDoesNotAdvanceWhileSessionOutstanding() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)

        // Add a second exercise to week 1 that is not done yet.
        let exercise2 = Exercise(name: "Bench Press", coreType: .benchPress)
        context.insert(exercise2)
        let day = try XCTUnwrap(workout.days.first)
        let workoutExercise2 = WorkoutExercise(
            exercise: exercise2,
            orderIndex: 1,
            progressionStyle: .linear,
            startingWeight: 80,
            targetSets: 3,
            targetReps: 5
        )
        workoutExercise2.day = day
        day.exercises.append(workoutExercise2)
        context.insert(workoutExercise2)
        let pending = ExerciseSession(weekNumber: 1, sessionNumber: 1, plannedWeight: 80, plannedSets: 3, plannedReps: 5)
        pending.workoutExercise = workoutExercise2
        workoutExercise2.sessions.append(pending)
        context.insert(pending)

        sessions[0].completed = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)

        XCTAssertEqual(workout.currentWeek, 1)
    }

    @MainActor func testWorkoutMarkedCompletedWhenAllSessionsCompletedOrSkipped() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)

        sessions[0].completed = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)
        XCTAssertEqual(workout.status, .active)

        sessions[1].skipped = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[1], workoutExercise: workoutExercise)
        XCTAssertEqual(workout.status, .completed)
        XCTAssertEqual(workout.currentWeek, 2, "currentWeek must not go past totalWeeks")
    }

    @MainActor func testSingleSessionQuickWorkoutIsMarkedCompleted() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)

        sessions[0].completed = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)

        XCTAssertEqual(workout.status, .completed)
    }

    // MARK: - Skip rules and day/week helpers (8b + 8c)

    @MainActor func testCompletingASkippedSessionClearsSkipped() throws {
        let context = container.mainContext
        let (_, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)

        sessions[0].skipped = true
        sessions[0].completed = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)

        XCTAssertTrue(sessions[0].completed)
        XCTAssertFalse(sessions[0].skipped, "A session that was done after being skipped must not stay skipped")
    }

    @MainActor func testCheckingAnEarlierWeekNeverAdvancesTheWorkoutAgain() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)

        sessions[0].skipped = true
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)
        XCTAssertEqual(workout.currentWeek, 2)

        // Same week-1 session checked again (for example skipped, undone, skipped again).
        DeloadAdjustmentService.checkAndAdvanceWeek(session: sessions[0], workoutExercise: workoutExercise)
        XCTAssertEqual(workout.currentWeek, 2, "Only the current week may advance the workout")
    }

    @MainActor func testNextDayPicksFirstUnfinishedDay() throws {
        let context = container.mainContext
        let (workout, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let dayA = try XCTUnwrap(workout.days.first)

        let exercise2 = Exercise(name: "Bench Press", coreType: .benchPress)
        context.insert(exercise2)
        let dayB = WorkoutDay(name: "Day B", dayNumber: 2)
        dayB.workout = workout
        workout.days.append(dayB)
        context.insert(dayB)
        let workoutExercise2 = WorkoutExercise(
            exercise: exercise2, orderIndex: 0, progressionStyle: .linear,
            startingWeight: 80, targetSets: 3, targetReps: 5
        )
        workoutExercise2.day = dayB
        dayB.exercises.append(workoutExercise2)
        context.insert(workoutExercise2)
        let sessionB = ExerciseSession(weekNumber: 1, sessionNumber: 1, plannedWeight: 80, plannedSets: 3, plannedReps: 5)
        sessionB.workoutExercise = workoutExercise2
        workoutExercise2.sessions.append(sessionB)
        context.insert(sessionB)

        XCTAssertTrue(workout.nextDay === dayA)

        sessions[0].completed = true
        XCTAssertTrue(workout.nextDay === dayB)

        sessionB.skipped = true
        XCTAssertNil(workout.nextDay, "Skipped counts as done when picking the next day")
    }

    @MainActor func testSessionForWeekPicksFirstNotDoneThenLast() throws {
        let context = container.mainContext
        let (_, workoutExercise, _) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)

        // Single-lift progressions can have several sessions in the same week.
        let extra1 = ExerciseSession(weekNumber: 1, sessionNumber: 2, plannedWeight: 100, plannedSets: 3, plannedReps: 5)
        let extra2 = ExerciseSession(weekNumber: 1, sessionNumber: 3, plannedWeight: 100, plannedSets: 3, plannedReps: 5)
        for extra in [extra1, extra2] {
            extra.workoutExercise = workoutExercise
            workoutExercise.sessions.append(extra)
            context.insert(extra)
        }
        let first = try XCTUnwrap(workoutExercise.sessions.first { $0.sessionNumber == 1 })

        XCTAssertTrue(workoutExercise.session(forWeek: 1) === first)

        first.completed = true
        XCTAssertTrue(workoutExercise.session(forWeek: 1) === extra1)

        extra1.skipped = true
        extra2.completed = true
        XCTAssertTrue(workoutExercise.session(forWeek: 1) === extra2, "All done: the last session is returned")
    }

    @MainActor func testFreeformFlagMatchesQuickWorkoutShape() throws {
        let context = container.mainContext
        let exercise = Exercise(name: "Curl")
        context.insert(exercise)

        let quick = WorkoutExercise(
            exercise: exercise, orderIndex: 0, progressionStyle: .linear,
            startingWeight: 30, targetSets: 0, targetReps: 0
        )
        let planned = WorkoutExercise(
            exercise: exercise, orderIndex: 1, progressionStyle: .linear,
            startingWeight: 30, targetSets: 3, targetReps: 10
        )
        XCTAssertTrue(quick.isFreeform)
        XCTAssertFalse(planned.isFreeform)
    }

    // MARK: - Home tab summary (WorkoutSummaryService)

    @MainActor
    private func addSet(
        to session: ExerciseSession, number: Int,
        reps: Int?, weight: Double?, completed: Bool = true,
        in context: ModelContext
    ) {
        let set = WorkoutSet(
            setNumber: number, targetReps: 5, targetWeight: 100,
            actualReps: reps, actualWeight: weight, completed: completed
        )
        set.exerciseSession = session
        session.sets.append(set)
        context.insert(set)
    }

    @MainActor func testPRCountsOnlyQualifyingSets() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)

        // Qualifying: completed, reps > 0, weight logged -> 200
        addSet(to: sessions[0], number: 1, reps: 5, weight: 200, in: context)
        // Ignored: zero reps, not completed, no weight
        addSet(to: sessions[0], number: 2, reps: 0, weight: 400, in: context)
        addSet(to: sessions[0], number: 3, reps: 5, weight: 500, completed: false, in: context)
        addSet(to: sessions[0], number: 4, reps: 5, weight: nil, in: context)
        // Ignored: skipped session
        sessions[1].skipped = true
        addSet(to: sessions[1], number: 1, reps: 5, weight: 600, in: context)

        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .squat, in: [workout]), 200)
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .deadlift, in: [workout]), 0, "Other core lifts are unaffected")

        // Finished programs still count
        workout.status = .completed
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .squat, in: [workout]), 200)

        // Exercises without a core type are excluded
        workoutExercise.exercise.coreType = nil
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .squat, in: [workout]), 0)
    }

    @MainActor func testUpcomingDaysSelection() throws {
        let context = container.mainContext
        let now = Date()
        let cal = Calendar.current

        // Active workout: week 1 today, week 2 in 3 days, week 3 in 30 days (outside window)
        let (active, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        sessions[0].date = now
        sessions[1].date = cal.date(byAdding: .day, value: 3, to: now)!
        sessions[2].date = cal.date(byAdding: .day, value: 30, to: now)!

        let result = WorkoutSummaryService.upcomingDays(in: [active], now: now, withinDays: 7)
        XCTAssertEqual(result.map { $0.week }, [1, 2], "Window is today through N days, one row per day and week")
        XCTAssertEqual(result.first?.pendingCount, 1)

        // Done sessions are excluded
        sessions[0].completed = true
        sessions[1].skipped = true
        XCTAssertTrue(WorkoutSummaryService.upcomingDays(in: [active], now: now, withinDays: 7).isEmpty)

        // Overdue: the next unfinished day of the current week is shown, marked overdue
        sessions[0].completed = false
        sessions[0].date = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: now))!
        let overdue = WorkoutSummaryService.upcomingDays(in: [active], now: now, withinDays: 7)
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.status, .overdue)

        // Non-active workouts are excluded
        sessions[0].date = now
        active.status = .paused
        XCTAssertTrue(WorkoutSummaryService.upcomingDays(in: [active], now: now, withinDays: 7).isEmpty)
    }

    @MainActor func testRecentSessionsOrderAndQuickWorkoutLabel() throws {
        let context = container.mainContext
        let now = Date()

        let (programWorkout, _, programSessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        programSessions[0].completed = true
        programSessions[0].completedDate = now.addingTimeInterval(-3 * 86_400)
        programSessions[1].completed = true
        programSessions[1].completedDate = now.addingTimeInterval(-1 * 86_400)
        // Finished program still contributes
        programWorkout.status = .completed

        // Quick workout (freeform), newest
        let curl = Exercise(name: "Curl")
        context.insert(curl)
        let quick = Workout(name: "Quick", templateType: .custom, totalWeeks: 1)
        context.insert(quick)
        let quickDay = WorkoutDay(name: "Workout", dayNumber: 1)
        quickDay.workout = quick
        quick.days.append(quickDay)
        context.insert(quickDay)
        let quickExercise = WorkoutExercise(
            exercise: curl, orderIndex: 0, progressionStyle: .linear,
            startingWeight: 0, targetSets: 0, targetReps: 0
        )
        quickExercise.day = quickDay
        quickDay.exercises.append(quickExercise)
        context.insert(quickExercise)
        let quickSession = ExerciseSession(
            weekNumber: 1, sessionNumber: 1, plannedWeight: 0, plannedSets: 0, plannedReps: 0,
            completed: true, completedDate: now
        )
        quickSession.workoutExercise = quickExercise
        quickExercise.sessions.append(quickSession)
        context.insert(quickSession)
        addSet(to: quickSession, number: 1, reps: 10, weight: 30, in: context)
        addSet(to: quickSession, number: 2, reps: 10, weight: 30, in: context)

        let entries = WorkoutSummaryService.recentEntries(
            workouts: [programWorkout, quick], legacySessions: [], limit: 5
        )
        XCTAssertEqual(entries.count, 3, "Uncompleted sessions are not listed")
        XCTAssertEqual(entries.first?.name, "Curl", "Newest first")
        XCTAssertEqual(entries.first?.detail, "2 sets")
        XCTAssertNil(entries.first?.percentage, "Quick workouts show no percentage")
        XCTAssertNotNil(entries.last?.percentage)

        let limited = WorkoutSummaryService.recentEntries(
            workouts: [programWorkout, quick], legacySessions: [], limit: 2
        )
        XCTAssertEqual(limited.count, 2)
    }

    // MARK: - Manual edits (WorkoutEditService)

    @MainActor func testManualCompleteStampsDateClearsSkippedAndAdvancesWeek() throws {
        let context = container.mainContext
        let (workout, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        sessions[0].skipped = true
        sessions[0].paused = true

        WorkoutEditService.setCompleted(true, session: sessions[0])

        XCTAssertTrue(sessions[0].completed)
        XCTAssertFalse(sessions[0].skipped)
        XCTAssertFalse(sessions[0].paused)
        XCTAssertNotNil(sessions[0].completedDate)
        XCTAssertEqual(workout.currentWeek, 2, "Only session of week 1 is done, so the week advances")
    }

    @MainActor func testManualSkipClearsCompleted() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        sessions[0].completed = true
        sessions[0].completedDate = Date()

        WorkoutEditService.setSkipped(true, session: sessions[0])

        XCTAssertTrue(sessions[0].skipped)
        XCTAssertFalse(sessions[0].completed)
        XCTAssertNil(sessions[0].completedDate)
    }

    @MainActor func testUncompletingReopensCompletedWorkoutButKeepsWeek() throws {
        let context = container.mainContext
        let (workout, _, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)
        WorkoutEditService.setCompleted(true, session: sessions[0])
        WorkoutEditService.setCompleted(true, session: sessions[1])
        XCTAssertEqual(workout.status, .completed)
        XCTAssertEqual(workout.currentWeek, 2)

        WorkoutEditService.setCompleted(false, session: sessions[1])

        XCTAssertEqual(workout.status, .active, "A finished workout with an open session is active again")
        XCTAssertEqual(workout.currentWeek, 2, "Week is never moved back automatically")
        XCTAssertNil(sessions[1].completedDate)
    }

    @MainActor func testSetCurrentWeekIsClamped() throws {
        let context = container.mainContext
        let (workout, _, _) = makeWorkout(in: context, totalWeeks: 4, sessionCount: 4)
        WorkoutEditService.setCurrentWeek(9, workout: workout)
        XCTAssertEqual(workout.currentWeek, 4)
        WorkoutEditService.setCurrentWeek(0, workout: workout)
        XCTAssertEqual(workout.currentWeek, 1)
        WorkoutEditService.setCurrentWeek(3, workout: workout)
        XCTAssertEqual(workout.currentWeek, 3)
    }

    @MainActor func testUpcomingInProgressAndOverdueRules() throws {
        let context = container.mainContext
        let now = Date()
        let cal = Calendar.current
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: now))!

        // Three weeks, everything in the past and nothing done: only ONE overdue row (current week).
        let (workout, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        for session in sessions { session.date = twoDaysAgo }
        let overdue = WorkoutSummaryService.upcomingDays(in: [workout], now: now, withinDays: 7)
        XCTAssertEqual(overdue.map { $0.week }, [1], "Old weeks do not pile up")
        XCTAssertEqual(overdue.first?.status, .overdue)

        // A day with logged sets is in progress whatever its date, and is not listed twice.
        addSet(to: sessions[0], number: 1, reps: 5, weight: 100, in: context)
        let started = WorkoutSummaryService.upcomingDays(in: [workout], now: now, withinDays: 7)
        XCTAssertEqual(started.count, 1)
        XCTAssertEqual(started.first?.status, .inProgress)

        // Order: in progress, then overdue, then scheduled.
        let (second, _, secondSessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        secondSessions[0].date = now
        let (third, _, thirdSessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        thirdSessions[0].date = twoDaysAgo
        let ordered = WorkoutSummaryService.upcomingDays(in: [second, third, workout], now: now, withinDays: 7)
        XCTAssertEqual(ordered.map { $0.status }, [.inProgress, .overdue, .scheduled])

        // Finished or skipped removes it.
        sessions[0].skipped = true
        sessions[1].skipped = true
        sessions[2].skipped = true
        XCTAssertTrue(WorkoutSummaryService.upcomingDays(in: [workout], now: now, withinDays: 7).isEmpty)
    }
}
