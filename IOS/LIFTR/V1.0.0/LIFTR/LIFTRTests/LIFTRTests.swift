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

    // MARK: - V5: cardio fields, Health import, times

    private func sampleActivity(id: String = "HK-1", name: String = "Running") -> ImportedActivity {
        let start = Date().addingTimeInterval(-3_600)
        return ImportedActivity(
            externalID: id,
            activityName: name,
            start: start,
            end: start.addingTimeInterval(3_000),
            duration: 3_000,
            distance: 10_000,
            elevationGain: 250,
            avgHeartRate: 150,
            maxHeartRate: 178,
            caloriesBurned: 640,
            elevationLoss: 240,
            maxSpeed: 4.5
        )
    }

    @MainActor func testV5FieldsDefaultToNilAndKindToStrength() throws {
        let context = container.mainContext
        let (_, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        XCTAssertEqual(workoutExercise.kind, .strength)
        XCTAssertFalse(workoutExercise.isCardio)
        let session = sessions[0]
        XCTAssertNil(session.startTime)
        XCTAssertNil(session.endTime)
        XCTAssertNil(session.distance)
        XCTAssertNil(session.duration)
        XCTAssertNil(session.avgHeartRate)
        XCTAssertNil(session.dataSource)
        XCTAssertNil(session.externalID)
    }

    @MainActor func testHealthImportCreatesFinishedCardioWorkoutAndSkipsDuplicates() throws {
        let context = container.mainContext
        let activity = sampleActivity()

        let created = try HealthImportService.importActivities([activity], into: context)
        try context.save()
        XCTAssertEqual(created, 1)

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts.count, 1)
        let workout = try XCTUnwrap(workouts.first)
        XCTAssertEqual(workout.status, .completed)
        let workoutExercise = try XCTUnwrap(workout.days.first?.exercises.first)
        XCTAssertTrue(workoutExercise.isCardio)
        XCTAssertNil(workoutExercise.exercise.coreType, "Cardio never counts toward PR totals")
        let session = try XCTUnwrap(workoutExercise.sessions.first)
        XCTAssertTrue(session.completed)
        XCTAssertEqual(session.distance, 10_000)
        XCTAssertEqual(session.duration, 3_000)
        XCTAssertEqual(session.elevationGain, 250)
        XCTAssertEqual(session.avgHeartRate, 150)
        XCTAssertEqual(session.elevationLoss, 240)
        XCTAssertEqual(session.maxSpeed, 4.5)
        XCTAssertEqual(session.dataSource, .healthKit)
        XCTAssertEqual(session.externalID, "HK-1")
        XCTAssertEqual(session.startTime, activity.start)
        XCTAssertEqual(session.endTime, activity.end)

        // Importing again adds nothing; a new id adds one and reuses the Running exercise.
        let again = try HealthImportService.importActivities([activity, sampleActivity(id: "HK-2")], into: context)
        try context.save()
        XCTAssertEqual(again, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Workout>()).count, 2)
        let running = try context.fetch(FetchDescriptor<Exercise>()).filter { $0.name == "Running" }
        XCTAssertEqual(running.count, 1)
    }

    @MainActor func testRecentSeparatesCardioFromStrengthAndFormatsUnits() throws {
        let context = container.mainContext
        let (strengthWorkout, _, strengthSessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        strengthSessions[0].completed = true
        strengthSessions[0].completedDate = Date()
        try HealthImportService.importActivities([sampleActivity()], into: context)
        let workouts = try context.fetch(FetchDescriptor<Workout>())

        let strength = WorkoutSummaryService.recentEntries(workouts: workouts, legacySessions: [], limit: 5)
        XCTAssertEqual(strength.count, 1)
        XCTAssertFalse(strength[0].isCardio)
        XCTAssertTrue(strength[0].session === strengthSessions[0], "Row must carry its session so a tap can open it")
        _ = strengthWorkout

        let imperial = WorkoutSummaryService.recentEntries(workouts: workouts, legacySessions: [], limit: 5, cardio: true)
        XCTAssertEqual(imperial.count, 1)
        XCTAssertTrue(imperial[0].isCardio)
        XCTAssertNil(imperial[0].percentage)
        XCTAssertNotNil(imperial[0].session)
        XCTAssertEqual(imperial[0].detail, "6.2 mi · 50 min")

        let metric = WorkoutSummaryService.recentEntries(workouts: workouts, legacySessions: [], limit: 5, cardio: true, useMetric: true)
        XCTAssertEqual(metric[0].detail, "10.0 km · 50 min")
    }

    @MainActor func testHistoryGroupsByMonthNewestFirstAndFiltersKind() throws {
        let context = container.mainContext
        let calendar = Calendar.current
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 2)
        let thisMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
        sessions[0].completed = true
        sessions[0].completedDate = lastMonth
        sessions[1].completed = true
        sessions[1].completedDate = thisMonth
        try HealthImportService.importActivities([sampleActivity()], into: context)
        let workouts = try context.fetch(FetchDescriptor<Workout>())

        let all = WorkoutSummaryService.historyMonths(workouts: workouts, kind: .all)
        XCTAssertEqual(all.count, 2)
        XCTAssertGreaterThan(all[0].monthStart, all[1].monthStart, "Newest month first")
        XCTAssertEqual(all[0].entries.count, 2, "This month: one strength session and the imported run")
        XCTAssertEqual(all[1].entries.count, 1)
        XCTAssertGreaterThanOrEqual(all[0].entries[0].date, all[0].entries[1].date, "Newest first inside a month")

        let strength = WorkoutSummaryService.historyMonths(workouts: workouts, kind: .strength)
        XCTAssertEqual(strength.flatMap { $0.entries }.count, 2)
        XCTAssertTrue(strength.flatMap { $0.entries }.allSatisfy { !$0.isCardio })

        let cardio = WorkoutSummaryService.historyMonths(workouts: workouts, kind: .cardio)
        XCTAssertEqual(cardio.count, 1)
        XCTAssertTrue(cardio[0].entries[0].isCardio)
        XCTAssertEqual(WorkoutSummaryService.historyMonths(workouts: [], kind: .all).count, 0)
    }

    @MainActor func testAnalyticsVolumeMaxWeightAndPRRules() throws {
        let context = container.mainContext
        let now = Date()
        let cal = Calendar.current
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        let dates = [
            cal.date(byAdding: .day, value: -2, to: now)!,
            cal.date(byAdding: .day, value: -1, to: now)!,
            now
        ]
        for (index, session) in sessions.enumerated() {
            session.completed = true
            session.completedDate = dates[index]
        }
        // Session 0: one qualifying set (5 x 200); zero reps and not-completed sets are ignored
        addSet(to: sessions[0], number: 1, reps: 5, weight: 200, in: context)
        addSet(to: sessions[0], number: 2, reps: 0, weight: 400, in: context)
        addSet(to: sessions[0], number: 3, reps: 5, weight: 500, completed: false, in: context)
        // Session 1 beats it (PR), session 2 does not
        addSet(to: sessions[1], number: 1, reps: 5, weight: 220, in: context)
        addSet(to: sessions[2], number: 1, reps: 5, weight: 210, in: context)

        XCTAssertEqual(AnalyticsService.volume(sessions[0]), 1_000)
        XCTAssertEqual(AnalyticsService.maxWeight(sessions[0]), 200)

        let month = try context.fetch(FetchDescriptor<Workout>())
        let inMonth = AnalyticsService.completedStrengthSessions(workouts: month, period: .month, now: now)
        XCTAssertEqual(inMonth.count, 3)
        XCTAssertEqual(inMonth.first?.id, sessions[0].id, "Oldest first")
        XCTAssertEqual(AnalyticsService.prCount(inMonth), 1, "First session is the baseline; only 220 beats it")

        XCTAssertEqual(AnalyticsService.completedStrengthSessions(workouts: month, period: .day, now: now).count, 1)
        XCTAssertEqual(AnalyticsService.completedStrengthSessions(workouts: month, period: .month, exerciseName: "Squat", now: now).count, 3)
        XCTAssertEqual(AnalyticsService.completedStrengthSessions(workouts: month, period: .month, exerciseName: "Bench", now: now).count, 0)

        let stats = AnalyticsService.exerciseStats(inMonth)
        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats[0].name, "Squat")
        XCTAssertEqual(stats[0].sessions, 3)
        XCTAssertEqual(stats[0].totalVolume, 3_150)
        XCTAssertEqual(stats[0].maxWeight, 220)

        XCTAssertEqual(AnalyticsService.volumeByDay(inMonth).map { $0.volume }, [1_000, 1_100, 1_050])
        XCTAssertEqual(AnalyticsService.averagePerformance([]), 0)
    }

    @MainActor func testAnalyticsLeavesOutCardioAndShowsGoalsForActiveStrengthPrograms() throws {
        let context = container.mainContext
        let (program, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)
        sessions[0].completed = true
        sessions[0].completedDate = Date()
        try HealthImportService.importActivities([sampleActivity()], into: context)
        let workouts = try context.fetch(FetchDescriptor<Workout>())

        let all = AnalyticsService.completedStrengthSessions(workouts: workouts, period: .allTime)
        XCTAssertEqual(all.count, 1, "The imported run is cardio and is not a strength session")
        XCTAssertEqual(AnalyticsService.strengthExerciseNames(in: workouts), ["Squat"])

        XCTAssertEqual(AnalyticsService.goalWorkouts(workouts).map { $0.id }, [program.id], "Imported (finished, cardio-only) workouts have no goal")
        XCTAssertEqual(AnalyticsService.goalExercises(of: program).map { $0.exercise.name }, ["Squat"])
        program.status = .completed
        XCTAssertTrue(AnalyticsService.goalWorkouts(workouts).isEmpty, "Only active programs show goals")
    }

#if DEBUG
    @MainActor func testSampleDataLoadsPRsOnAllLiftsAndRemovesOnlySamples() throws {
        let context = container.mainContext
        // A real workout that must survive removal
        let (real, _, _) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        real.notes = "mine"

        let created = try SampleDataService.load(into: context)
        XCTAssertEqual(created, 12, "3 programs + 3 quick workouts + 6 cardio")
        XCTAssertEqual(try SampleDataService.load(into: context), 0, "Loading twice is refused")
        XCTAssertTrue(try SampleDataService.hasSampleData(in: context))

        var workouts = try context.fetch(FetchDescriptor<Workout>())
        // Highest weight per core lift: program C / quick workouts beat the earlier programs
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .squat, in: workouts), 285, "Quick workout squat is the heaviest")
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .benchPress, in: workouts), 152.5)
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .deadlift, in: workouts), 305, "500 and 400 sets are ignored")
        XCTAssertEqual(WorkoutSummaryService.maxWeight(for: .overheadPress, in: workouts), 95)

        // Analytics: PRs exist on every lift, Barbell Row (no core type) never counts
        let all = AnalyticsService.completedStrengthSessions(workouts: workouts, period: .allTime)
        XCTAssertGreaterThan(AnalyticsService.prCount(all), 4)
        let rowOnly = AnalyticsService.completedStrengthSessions(workouts: workouts, period: .allTime, exerciseName: "Barbell Row")
        XCTAssertEqual(AnalyticsService.prCount(rowOnly), 0)

        // History shows strength and cardio, and goals show only the active program
        XCTAssertFalse(WorkoutSummaryService.historyMonths(workouts: workouts, kind: .cardio).isEmpty)
        let goalNames = Set(AnalyticsService.goalWorkouts(workouts).map { $0.name })
        XCTAssertEqual(goalNames, ["Test", "Sample: 5/3/1 Active"], "Finished sample programs have no goal; the real active workout does")

        // Removal deletes only samples
        let removed = try SampleDataService.remove(from: context)
        XCTAssertEqual(removed, 12)
        workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts.first?.notes, "mine")
        XCTAssertFalse(try SampleDataService.hasSampleData(in: context))
    }
#endif

    /// Starts a live cardio workout and finishes it, with controlled times (step 5).
    @MainActor private func runLiveCardio(
        type: CardioType, minutes: Double, distanceEntered: Double?, notes: String,
        useMetric: Bool, in context: ModelContext
    ) throws -> Workout {
        let t0 = Date(timeIntervalSince1970: 4_000_000)
        let live = try CardioWorkoutService.startLiveWorkout(type: type, customName: "", into: context, now: t0)
        var meters: Double? = nil
        if let entered = distanceEntered {
            meters = CardioWorkoutService.meters(fromEntered: entered, type: type, useMetric: useMetric)
        }
        try CardioWorkoutService.finishLiveWorkout(
            session: live.session, workoutExercise: live.workoutExercise,
            durationSeconds: minutes * 60, distanceMeters: meters, notes: notes,
            into: context, now: t0.addingTimeInterval(minutes * 60)
        )
        return live.workout
    }

    @MainActor func testLiveCardioStartAndFinishUsesSharedModelAndHealthImportNames() throws {
        let context = container.mainContext
        let t0 = Date(timeIntervalSince1970: 4_000_000)

        // Start: an active, running, not-completed cardio session
        let live = try CardioWorkoutService.startLiveWorkout(type: .running, customName: "", into: context, now: t0)
        XCTAssertEqual(live.workout.status, .active)
        XCTAssertEqual(live.workout.name, "Running")
        XCTAssertTrue(live.workout.isCardioWorkout)
        XCTAssertFalse(live.workout.isEmptyQuickWorkout, "A live cardio workout is never hidden as an empty quick workout")
        XCTAssertFalse(live.session.completed)
        XCTAssertEqual(live.session.startTime, t0)
        XCTAssertEqual(live.session.dataSource, .manual)
        XCTAssertTrue(LiveSessionClock.isRunningSession(live.session))
        XCTAssertEqual(LiveSessionClock.elapsed(live.session, now: t0.addingTimeInterval(600)), 600, accuracy: 0.001)

        // Stop and save
        try CardioWorkoutService.finishLiveWorkout(
            session: live.session, workoutExercise: live.workoutExercise,
            durationSeconds: 1_800,
            distanceMeters: CardioWorkoutService.meters(fromEntered: 3.1, type: .running, useMetric: false),
            notes: " easy ", into: context, now: t0.addingTimeInterval(1_800)
        )
        XCTAssertEqual(live.workout.status, .completed)
        let session = live.session
        XCTAssertEqual(session.distance ?? 0, 3.1 * 1_609.344, accuracy: 0.01)
        XCTAssertEqual(session.duration, 1_800)
        XCTAssertNil(session.externalID)
        XCTAssertEqual(session.notes, "easy")
        XCTAssertTrue(session.completed)
        XCTAssertEqual(session.endTime, t0.addingTimeInterval(1_800), "End time is stamped on completion")
        XCTAssertFalse(LiveSessionClock.isRunningSession(session))

        // A Health import of the same activity kind shares the Exercise (no duplicate names)
        try HealthImportService.importActivities([sampleActivity()], into: context)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(exercises.filter { $0.name == "Running" }.count, 1)

        // It shows up in Recent and History like an imported run
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        let recent = WorkoutSummaryService.recentEntries(workouts: workouts, legacySessions: [], limit: 5, cardio: true, useMetric: false)
        XCTAssertEqual(recent.count, 2)
        XCTAssertTrue(recent.contains { $0.detail == "3.1 mi · 30 min" })
        XCTAssertEqual(WorkoutSummaryService.historyMonths(workouts: workouts, kind: .cardio).flatMap { $0.entries }.count, 2)
    }

    @MainActor func testLiveCardioStaleCheckAndTypeLookup() throws {
        let context = container.mainContext
        let t0 = Date(timeIntervalSince1970: 4_000_000)
        let live = try CardioWorkoutService.startLiveWorkout(type: .swimming, customName: "", into: context, now: t0)

        // Cardio logs no sets, so staleness must not depend on logged sets
        XCTAssertFalse(live.session.hasLoggedSets)
        XCTAssertFalse(LiveSessionClock.isStale(live.session, now: t0.addingTimeInterval(5 * 3600)))
        XCTAssertTrue(LiveSessionClock.isStale(live.session, now: t0.addingTimeInterval(7 * 3600)))

        // A paused cardio session is not stale
        LiveSessionClock.pause(live.session, now: t0.addingTimeInterval(600))
        XCTAssertFalse(LiveSessionClock.isStale(live.session, now: t0.addingTimeInterval(7 * 3600)))

        // A strength session with no logged sets is still never stale
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        LiveSessionClock.start(sessions[0], now: t0)
        XCTAssertFalse(LiveSessionClock.isStale(sessions[0], now: t0.addingTimeInterval(7 * 3600)))

        // The live screen finds the cardio type from the exercise name
        XCTAssertEqual(CardioWorkoutService.cardioType(forExerciseName: "Running"), .running)
        XCTAssertEqual(CardioWorkoutService.cardioType(forExerciseName: "swimming"), .swimming)
        XCTAssertEqual(CardioWorkoutService.cardioType(forExerciseName: "CrossFit"), .crossfit)
        XCTAssertEqual(CardioWorkoutService.cardioType(forExerciseName: "Elliptical"), .freeCardio)

        // Strength workouts are not cardio workouts
        let (strength, _, _) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        XCTAssertFalse(strength.isCardioWorkout)
    }

    @MainActor func testManualCardioNamesAndUnitConversions() throws {
        XCTAssertEqual(CardioWorkoutService.activityName(for: .swimming, custom: ""), "Swimming")
        XCTAssertEqual(CardioWorkoutService.activityName(for: .crossfit, custom: ""), "CrossFit")
        XCTAssertEqual(CardioWorkoutService.activityName(for: .freeCardio, custom: "  Elliptical "), "Elliptical")
        XCTAssertEqual(CardioWorkoutService.activityName(for: .freeCardio, custom: " "), "Cardio")

        XCTAssertEqual(CardioWorkoutService.meters(fromEntered: 5, type: .running, useMetric: true), 5_000)
        XCTAssertEqual(try XCTUnwrap(CardioWorkoutService.meters(fromEntered: 1, type: .running, useMetric: false)), 1_609.344, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(CardioWorkoutService.meters(fromEntered: 100, type: .swimming, useMetric: false)), 91.44, accuracy: 0.001)
        XCTAssertEqual(CardioWorkoutService.meters(fromEntered: 400, type: .swimming, useMetric: true), 400)
        XCTAssertNil(CardioWorkoutService.meters(fromEntered: 10, type: .crossfit, useMetric: true), "No distance field outside running and swimming")

        // A type without a distance field stores no distance and an empty note stays nil
        let context = container.mainContext
        let workout = try runLiveCardio(type: .calisthenics, minutes: 20, distanceEntered: 9, notes: "", useMetric: false, in: context)
        let session = try XCTUnwrap(workout.days.first?.exercises.first?.sessions.first)
        XCTAssertNil(session.distance)
        XCTAssertNil(session.notes)
        XCTAssertEqual(session.duration, 1_200)
    }

    @MainActor func testCompletionSummaryLinesForStrengthAndCardio() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        addSet(to: sessions[0], number: 1, reps: 5, weight: 225, in: context)
        addSet(to: sessions[0], number: 2, reps: 3, weight: 232.5, in: context)
        addSet(to: sessions[0], number: 3, reps: 5, weight: 300, completed: false, in: context)

        XCTAssertEqual(WorkoutSummaryService.completionLines(for: sessions[0], useMetric: false),
                       ["2 sets · 8 reps", "Heaviest set: 232.5 lbs", "Performance: 100% · Week 1"])
        XCTAssertEqual(WorkoutSummaryService.completionLines(for: sessions[0], useMetric: true),
                       ["2 sets · 8 reps", "Heaviest set: 232.5 kg", "Performance: 100% · Week 1"])

        let run = try runLiveCardio(type: .running, minutes: 30, distanceEntered: 3.1, notes: "", useMetric: false, in: context)
        let runSession = try XCTUnwrap(run.days.first?.exercises.first?.sessions.first)
        XCTAssertEqual(WorkoutSummaryService.completionLines(for: runSession, useMetric: false), ["3.1 mi · 30 min"])
    }

    @MainActor func testCardioDetailFallbacks() throws {
        let session = ExerciseSession(weekNumber: 1, sessionNumber: 1, plannedWeight: 0, plannedSets: 0, plannedReps: 0)
        XCTAssertEqual(WorkoutSummaryService.cardioDetail(session, useMetric: false), "Activity")
        XCTAssertEqual(WorkoutSummaryService.cardioPlanDetail(session, useMetric: false), "Log this activity")
        session.plannedDistance = 9_656.064
        session.plannedDuration = 3_600
        XCTAssertEqual(WorkoutSummaryService.cardioPlanDetail(session, useMetric: false), "6.0 mi · 60 min")
    }

    @MainActor func testEndTimeStampedOnCompletionAndClearedWhenReopened() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)
        sessions[0].startTime = Date().addingTimeInterval(-1_800)

        WorkoutEditService.setCompleted(true, session: sessions[0])
        XCTAssertNotNil(sessions[0].endTime)
        XCTAssertNotNil(sessions[0].startTime, "Start time is kept")

        WorkoutEditService.setCompleted(false, session: sessions[0])
        XCTAssertNil(sessions[0].endTime)
        XCTAssertNotNil(sessions[0].startTime)
    }

    // MARK: - Performance % (capped volume ratio, decided 2026-11-16)

    @MainActor func testPerformancePercentageIsCappedVolumeRatio() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 4, sessionCount: 4)
        // Plan: 3 sets x 5 reps at 100 = 1500 volume.

        // On plan
        for n in 1...3 { addSet(to: sessions[0], number: n, reps: 5, weight: 100, in: context) }
        XCTAssertEqual(sessions[0].performancePercentage, 100, accuracy: 0.001)

        // All reps but lighter: 5 x 90 x 3 = 1350 of 1500
        for n in 1...3 { addSet(to: sessions[1], number: n, reps: 5, weight: 90, in: context) }
        XCTAssertEqual(sessions[1].performancePercentage, 90, accuracy: 0.001)

        // Heavier than planned is capped at 100
        for n in 1...3 { addSet(to: sessions[2], number: n, reps: 5, weight: 120, in: context) }
        XCTAssertEqual(sessions[2].performancePercentage, 100, accuracy: 0.001)

        // Missed reps at the planned weight: 12 of 15 reps = 80
        addSet(to: sessions[3], number: 1, reps: 5, weight: 100, in: context)
        addSet(to: sessions[3], number: 2, reps: 5, weight: 100, in: context)
        addSet(to: sessions[3], number: 3, reps: 2, weight: 100, in: context)
        XCTAssertEqual(sessions[3].performancePercentage, 80, accuracy: 0.001)
    }

    @MainActor func testPerformancePercentageEdgeCases() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 3, sessionCount: 3)

        // A set that was not completed does not count
        addSet(to: sessions[0], number: 1, reps: 5, weight: 100, in: context)
        addSet(to: sessions[0], number: 2, reps: 5, weight: 100, completed: false, in: context)
        XCTAssertEqual(sessions[0].performancePercentage, 100.0 / 3.0, accuracy: 0.001)

        // No weight logged: the set counts at its target weight (100 in addSet)
        addSet(to: sessions[1], number: 1, reps: 5, weight: nil, in: context)
        XCTAssertEqual(sessions[1].performancePercentage, 100.0 / 3.0, accuracy: 0.001)

        // No planned weight: falls back to the rep ratio, still capped
        sessions[2].plannedWeight = 0
        addSet(to: sessions[2], number: 1, reps: 10, weight: 0, in: context)
        addSet(to: sessions[2], number: 2, reps: 10, weight: 0, in: context)
        XCTAssertEqual(sessions[2].performancePercentage, 100, accuracy: 0.001)
    }

    @MainActor func testSuggestionUsesVolumeNotJustReps() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 2, sessionCount: 2)
        let settings = GlobalProgressionSettings()
        settings.excellentThreshold = 90
        settings.goodThreshold = 75
        settings.adjustmentThreshold = 60

        // Every rep done but at 70% of the planned weight: volume 70%, so a reduction is suggested
        for n in 1...3 { addSet(to: sessions[0], number: n, reps: 5, weight: 70, in: context) }
        XCTAssertEqual(sessions[0].totalCompletedReps, sessions[0].totalPlannedReps)
        XCTAssertEqual(DeloadAdjustmentService.analyzePerformance(session: sessions[0], settings: settings),
                       .reduceBy(percent: settings.reductionPercent))

        // On plan continues as planned
        for n in 1...3 { addSet(to: sessions[1], number: n, reps: 5, weight: 100, in: context) }
        XCTAssertEqual(DeloadAdjustmentService.analyzePerformance(session: sessions[1], settings: settings), .continueAsPlanned)
    }

    @MainActor func testQuickWorkoutCompletionLinesHaveNoPerformanceLine() throws {
        let context = container.mainContext
        let (_, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        workoutExercise.targetSets = 0   // freeform, as a quick workout
        addSet(to: sessions[0], number: 1, reps: 5, weight: 100, in: context)
        let lines = WorkoutSummaryService.completionLines(for: sessions[0], useMetric: false)
        XCTAssertEqual(lines, ["1 set · 5 reps", "Heaviest set: 100 lbs"])
    }

    // MARK: - Live session clock (step 2, 2026-11-16)

    private let clockStart = Date(timeIntervalSince1970: 1_000_000)

    @MainActor func testLiveSessionClockStartPauseResume() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let session = sessions[0]
        let t0 = clockStart

        XCTAssertTrue(LiveSessionClock.needsStart(session))
        LiveSessionClock.pause(session, now: t0)
        XCTAssertNil(session.pausedAt, "Cannot pause a session that has not started")

        LiveSessionClock.start(session, now: t0)
        XCTAssertFalse(LiveSessionClock.needsStart(session))
        XCTAssertEqual(LiveSessionClock.elapsed(session, now: t0.addingTimeInterval(600)), 600, accuracy: 0.001)

        // Pause: the clock freezes
        LiveSessionClock.pause(session, now: t0.addingTimeInterval(600))
        XCTAssertTrue(LiveSessionClock.isPaused(session))
        XCTAssertEqual(LiveSessionClock.elapsed(session, now: t0.addingTimeInterval(900)), 600, accuracy: 0.001)

        // Resume: the 300 s gap is not counted
        LiveSessionClock.resume(session, now: t0.addingTimeInterval(900))
        XCTAssertFalse(LiveSessionClock.isPaused(session))
        XCTAssertEqual(try XCTUnwrap(session.pausedSeconds), 300, accuracy: 0.001)
        XCTAssertEqual(LiveSessionClock.elapsed(session, now: t0.addingTimeInterval(1200)), 900, accuracy: 0.001)

        // A second pause adds to the total
        LiveSessionClock.pause(session, now: t0.addingTimeInterval(1200))
        LiveSessionClock.resume(session, now: t0.addingTimeInterval(1260))
        XCTAssertEqual(try XCTUnwrap(session.pausedSeconds), 360, accuracy: 0.001)
        XCTAssertEqual(LiveSessionClock.elapsed(session, now: t0.addingTimeInterval(1500)), 1140, accuracy: 0.001)

        // Start is only honoured once
        LiveSessionClock.start(session, now: t0.addingTimeInterval(5_000))
        XCTAssertEqual(session.startTime, t0)
    }

    @MainActor func testCompletingWhilePausedFoldsThePauseAndStampsEnd() throws {
        let context = container.mainContext
        let (_, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let session = sessions[0]
        let t0 = clockStart

        LiveSessionClock.start(session, now: t0)
        LiveSessionClock.pause(session, now: t0.addingTimeInterval(600))
        session.completed = true
        session.completedDate = t0.addingTimeInterval(900)
        DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)

        XCTAssertEqual(session.endTime, t0.addingTimeInterval(900))
        XCTAssertNil(session.pausedAt)
        XCTAssertEqual(try XCTUnwrap(session.pausedSeconds), 300, accuracy: 0.001)
        XCTAssertEqual(LiveSessionClock.elapsed(session), 600, accuracy: 0.001)
        XCTAssertFalse(LiveSessionClock.isRunningSession(session))
    }

    @MainActor func testStaleSessionDetectionAndFinishDuration() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let session = sessions[0]
        let t0 = clockStart
        let sevenHours = t0.addingTimeInterval(7 * 3600)

        LiveSessionClock.start(session, now: t0)
        XCTAssertFalse(LiveSessionClock.isStale(session, now: sevenHours), "No sets logged: not stale")

        addSet(to: session, number: 1, reps: 5, weight: 100, in: context)
        XCTAssertFalse(LiveSessionClock.isStale(session, now: t0.addingTimeInterval(5 * 3600)))
        XCTAssertTrue(LiveSessionClock.isStale(session, now: sevenHours))

        // A paused clock is not stale
        LiveSessionClock.pause(session, now: t0.addingTimeInterval(600))
        XCTAssertFalse(LiveSessionClock.isStale(session, now: sevenHours))
        LiveSessionClock.resume(session, now: t0.addingTimeInterval(660))   // 60 s paused in total

        // Finish with a stated duration: active time equals it
        LiveSessionClock.setEnd(session, durationSeconds: 3_600, now: sevenHours)
        XCTAssertEqual(LiveSessionClock.elapsed(session), 3_600, accuracy: 0.001)

        // A duration longer than the session really lasted is clamped to now
        session.endTime = nil
        LiveSessionClock.setEnd(session, durationSeconds: 100 * 3600, now: sevenHours)
        XCTAssertEqual(session.endTime, sevenHours)
    }

    @MainActor func testClockFormatAndRunningSessionLookup() throws {
        XCTAssertEqual(LiveSessionClock.format(125), "02:05")
        XCTAssertEqual(LiveSessionClock.format(3_725), "1:02:05")
        XCTAssertEqual(LiveSessionClock.format(-5), "00:00")

        let context = container.mainContext
        let (workout, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        XCTAssertNil(workout.runningSession(forWeek: 1))
        LiveSessionClock.start(sessions[0], now: clockStart)
        XCTAssertTrue(workout.runningSession(forWeek: 1) === sessions[0])
        sessions[0].completed = true
        XCTAssertNil(workout.runningSession(forWeek: 1))
    }

    @MainActor func testEmptyQuickWorkoutIsHiddenUntilASetIsLogged() throws {
        let context = container.mainContext
        let (workout, workoutExercise, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)

        XCTAssertFalse(workout.isEmptyQuickWorkout, "A program workout is never an empty quick workout")

        workoutExercise.targetSets = 0   // quick (freeform) workout
        XCTAssertTrue(workout.isEmptyQuickWorkout)

        addSet(to: sessions[0], number: 1, reps: 5, weight: 100, in: context)
        XCTAssertFalse(workout.isEmptyQuickWorkout, "Once a set is logged the workout is kept and shown")
    }

    // MARK: - Rest clock (step 3, 2026-11-17)

    func testRestClockRemainingProgressAndFinish() throws {
        let t0 = Date(timeIntervalSince1970: 2_000_000)
        let clock = RestClock(startedAt: t0, duration: 90)

        XCTAssertEqual(clock.totalSeconds, 90, accuracy: 0.001)
        XCTAssertEqual(clock.remaining(at: t0), 90, accuracy: 0.001)
        XCTAssertEqual(clock.remaining(at: t0.addingTimeInterval(30)), 60, accuracy: 0.001)
        XCTAssertEqual(clock.progress(at: t0), 0, accuracy: 0.001)
        XCTAssertEqual(clock.progress(at: t0.addingTimeInterval(45)), 0.5, accuracy: 0.001)
        XCTAssertFalse(clock.isFinished(at: t0.addingTimeInterval(89.9)))
        XCTAssertTrue(clock.isFinished(at: t0.addingTimeInterval(90)))

        // Never negative, never past 1, even long after the end (app was suspended)
        XCTAssertEqual(clock.remaining(at: t0.addingTimeInterval(500)), 0, accuracy: 0.001)
        XCTAssertEqual(clock.progress(at: t0.addingTimeInterval(500)), 1, accuracy: 0.001)
    }

    func testRestClockAddTimeAndFormat() throws {
        let t0 = Date(timeIntervalSince1970: 2_000_000)
        let clock = RestClock(startedAt: t0, duration: 60).adding(15)

        XCTAssertEqual(clock.totalSeconds, 75, accuracy: 0.001)
        XCTAssertEqual(clock.remaining(at: t0.addingTimeInterval(10)), 65, accuracy: 0.001)
        XCTAssertFalse(clock.isFinished(at: t0.addingTimeInterval(60)), "Added time moves the end")
        XCTAssertTrue(clock.isFinished(at: t0.addingTimeInterval(75)))

        // Rounds up so 0:00 only shows when the rest is really over
        XCTAssertEqual(RestClock.format(72), "1:12")
        XCTAssertEqual(RestClock.format(0.2), "0:01")
        XCTAssertEqual(RestClock.format(0), "0:00")
        XCTAssertEqual(RestClock.format(180), "3:00")
    }

    // MARK: - Session Live Activity (step 4, 2026-11-21)

    @MainActor func testActivityClockStartKeepsLockScreenClockEqualToElapsed() throws {
        let context = container.mainContext
        let (_, _, sessions) = makeWorkout(in: context, totalWeeks: 1, sessionCount: 1)
        let session = sessions[0]
        let t0 = clockStart

        LiveSessionClock.start(session, now: t0)
        LiveSessionClock.pause(session, now: t0.addingTimeInterval(600))
        LiveSessionClock.resume(session, now: t0.addingTimeInterval(900))   // 300 s paused

        // The Lock Screen counts up from this date: it must equal the in-app elapsed time.
        let origin = LiveSessionClock.activityClockStart(session)
        XCTAssertEqual(origin, t0.addingTimeInterval(300))
        let probe = t0.addingTimeInterval(1500)
        XCTAssertEqual(probe.timeIntervalSince(origin), LiveSessionClock.elapsed(session, now: probe), accuracy: 0.001)

        // While paused the Lock Screen freezes at pausedAt: same value as the frozen in-app clock.
        LiveSessionClock.pause(session, now: t0.addingTimeInterval(1500))
        let frozenAt = try XCTUnwrap(session.pausedAt)
        XCTAssertEqual(frozenAt.timeIntervalSince(LiveSessionClock.activityClockStart(session)),
                       LiveSessionClock.elapsed(session, now: t0.addingTimeInterval(9_999)), accuracy: 0.001)
    }

    func testSessionActivityStateFlagsAndRanges() throws {
        let t0 = Date(timeIntervalSince1970: 3_000_000)
        var state = RestTimerAttributes.ContentState(
            clockStart: t0,
            pausedAt: nil,
            progressText: "2 of 5 sets",
            restStart: nil,
            restEnd: nil,
            restOver: false
        )
        XCTAssertFalse(state.isResting)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.clockRange.lowerBound, t0)

        state.restStart = t0.addingTimeInterval(100)
        state.restEnd = t0.addingTimeInterval(190)
        XCTAssertTrue(state.isResting)
        XCTAssertEqual(state.restRange.upperBound.timeIntervalSince(state.restRange.lowerBound), 90, accuracy: 0.001)

        // "Rest over" is not "resting"
        state.restOver = true
        XCTAssertFalse(state.isResting)

        state.pausedAt = t0.addingTimeInterval(50)
        XCTAssertTrue(state.isPaused)
        XCTAssertEqual(RestTimerAttributes.strengthType, "Strength")
        XCTAssertEqual(RestTimerAttributes.cardioType, "Cardio")
    }

    // MARK: - Step 6: GPS route, elevation, storage

    func testRouteAccumulatorFiltersAndMeasures() {
        var route = RouteAccumulator()
        XCTAssertFalse(route.add(lat: 0, lon: 0, time: 0, accuracy: 80), "Inaccurate reading is ignored")
        XCTAssertTrue(route.add(lat: 0, lon: 0, time: 1, accuracy: 5))
        XCTAssertFalse(route.add(lat: 0.00001, lon: 0, time: 5, accuracy: 5), "About 1 m of wander is ignored")
        XCTAssertTrue(route.add(lat: 0.001, lon: 0, time: 20, accuracy: 5))
        XCTAssertEqual(route.distance, 111.2, accuracy: 1.0)
        XCTAssertFalse(route.add(lat: 0.01, lon: 0, time: 21, accuracy: 5), "A jump faster than 25 m/s is ignored")
        XCTAssertFalse(route.add(lat: 0.002, lon: 0, time: 20, accuracy: 5), "Not newer than the last point")
        XCTAssertEqual(route.points.count, 2)

        // After a break the next point starts a new segment and the jump is not counted.
        let before = route.distance
        route.breakSegment()
        XCTAssertTrue(route.add(lat: 0.01, lon: 0, time: 400, accuracy: 5))
        XCTAssertEqual(route.distance, before, accuracy: 0.001)
        XCTAssertTrue(route.add(lat: 0.011, lon: 0, time: 420, accuracy: 5))
        XCTAssertEqual(route.distance, before + 111.2, accuracy: 1.5)
    }

    func testElevationAccumulatorHysteresisAndRebase() {
        var elevation = ElevationAccumulator()
        elevation.add(altitude: 0)
        elevation.add(altitude: 0.5)
        XCTAssertEqual(elevation.gain, 0, accuracy: 0.001, "Under 1 m is noise")
        elevation.add(altitude: 3)
        XCTAssertEqual(elevation.gain, 3, accuracy: 0.001)
        elevation.add(altitude: 1)
        XCTAssertEqual(elevation.loss, 2, accuracy: 0.001)

        // After a pause the barometer restarts from zero: no fake loss or gain.
        elevation.rebase()
        elevation.add(altitude: 0)
        elevation.add(altitude: 2)
        XCTAssertEqual(elevation.gain, 5, accuracy: 0.001)
        XCTAssertEqual(elevation.loss, 2, accuracy: 0.001)
    }

    func testRouteCodecRoundTripAndThinning() throws {
        var route = RouteAccumulator()
        for i in 0..<300 {
            route.add(lat: Double(i) * 0.001, lon: 0, time: Double(i) * 20, accuracy: 5)
        }
        XCTAssertEqual(route.points.count, 300)

        let thin = route.thinned(maxPoints: 50)
        XCTAssertLessThanOrEqual(thin.count, 51)
        XCTAssertEqual(thin.first, route.points.first)
        XCTAssertEqual(thin.last, route.points.last)

        let data = try XCTUnwrap(RouteCodec.encode(thin))
        XCTAssertEqual(RouteCodec.decode(data), thin)
        XCTAssertNil(RouteCodec.encode([RoutePoint(lat: 1, lon: 1, time: 0)]), "One point is not a route")
        XCTAssertEqual(RouteCodec.decode(Data([1, 2, 3])), [])
    }

    func testRouteStoreCheckpointRoundTripAndFormat() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("route-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let id = UUID()
        XCTAssertNil(RouteStore.load(for: id, in: dir))

        var snapshot = RouteSnapshot()
        snapshot.route.add(lat: 0, lon: 0, time: 1, accuracy: 5)
        snapshot.route.add(lat: 0.001, lon: 0, time: 20, accuracy: 5)
        snapshot.elevation.add(altitude: 0)
        snapshot.elevation.add(altitude: 4)
        snapshot.hasElevation = true
        RouteStore.save(snapshot, for: id, in: dir)
        XCTAssertEqual(RouteStore.load(for: id, in: dir), snapshot)
        RouteStore.remove(for: id, in: dir)
        XCTAssertNil(RouteStore.load(for: id, in: dir))

        XCTAssertEqual(RouteFormat.distance(1609.344, useMetric: false), "1.00 mi")
        XCTAssertEqual(RouteFormat.distance(5020, useMetric: true), "5.02 km")
        XCTAssertEqual(RouteFormat.distanceNumber(3218.688, useMetric: false), "2.00")
        XCTAssertEqual(RouteFormat.elevation(10, useMetric: true), "10 m")
        XCTAssertEqual(RouteFormat.elevation(10, useMetric: false), "33 ft")
    }

    @MainActor func testFinishLiveCardioStoresRouteElevationAndFreeCardioDistance() throws {
        let context = container.mainContext
        let t0 = Date(timeIntervalSince1970: 5_000_000)
        var route = RouteAccumulator()
        route.add(lat: 0, lon: 0, time: 1, accuracy: 5)
        route.add(lat: 0.001, lon: 0, time: 20, accuracy: 5)
        let routeData = try XCTUnwrap(RouteCodec.encode(route.points))

        let live = try CardioWorkoutService.startLiveWorkout(type: .freeCardio, customName: "Hike", into: context, now: t0)
        try CardioWorkoutService.finishLiveWorkout(
            session: live.session, workoutExercise: live.workoutExercise,
            durationSeconds: 1_800, distanceMeters: 111.2, elevationGain: 12, elevationLoss: 5,
            routeData: routeData, notes: "", into: context, now: t0.addingTimeInterval(1_800)
        )
        XCTAssertEqual(live.session.distance ?? 0, 111.2, accuracy: 0.001)
        XCTAssertEqual(live.session.elevationGain, 12)
        XCTAssertEqual(live.session.elevationLoss, 5)
        XCTAssertEqual(RouteCodec.decode(try XCTUnwrap(live.session.routeData)).count, 2)

        // Free Cardio distance is entered in km or miles, like running.
        XCTAssertEqual(CardioWorkoutService.meters(fromEntered: 2, type: .freeCardio, useMetric: true) ?? 0, 2_000, accuracy: 0.001)
        XCTAssertEqual(CardioWorkoutService.meters(fromEntered: 1, type: .freeCardio, useMetric: false) ?? 0, 1_609.344, accuracy: 0.001)
    }
}
