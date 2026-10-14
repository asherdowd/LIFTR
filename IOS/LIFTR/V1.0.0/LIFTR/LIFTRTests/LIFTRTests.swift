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
}
