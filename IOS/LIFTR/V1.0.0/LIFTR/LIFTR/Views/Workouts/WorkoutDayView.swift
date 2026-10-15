import SwiftUI
import SwiftData

// MARK: - Workout Day Screen
// Lists one program day's exercises for a given week. Exercises can be done in any order,
// skipped individually (swipe left), or the whole day can be finished at any time.
// Reuses ExerciseSessionView (programs) and LiveSingleWorkoutView (quick/freeform workouts).
// Presented as a sheet with its own NavigationStack (see WorkoutCardView).

struct WorkoutDayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]

    let workout: Workout
    /// The week this screen was opened for. Fixed on purpose: finishing the last exercise
    /// can advance `workout.currentWeek`, and this screen must keep showing the same week.
    let week: Int

    @State private var selectedDay: WorkoutDay
    @State private var showFinishConfirmation = false
    @State private var activeExercise: ActiveExercise?

    /// Which exercise screen is pushed. Held in state (not in a list-row link) so a redraw
    /// of the list, for example when a set is saved, cannot pop the screen.
    private struct ActiveExercise: Hashable {
        let session: ExerciseSession
        let exercise: WorkoutExercise
    }

    init(workout: Workout, day: WorkoutDay, week: Int) {
        self.workout = workout
        self.week = week
        _selectedDay = State(initialValue: day)
    }

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var useMetric: Bool {
        globalSettings.first?.useMetric == true
    }

    /// Sessions in this day that are not completed or skipped yet.
    private var pending: [(session: ExerciseSession, exercise: WorkoutExercise)] {
        selectedDay.sortedExercises.compactMap { exercise in
            guard let session = exercise.session(forWeek: week), !session.isDone else { return nil }
            return (session: session, exercise: exercise)
        }
    }

    var body: some View {
        List {
            if workout.days.count > 1 {
                Section {
                    Menu {
                        ForEach(workout.sortedDays) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                if day.id == selectedDay.id {
                                    Label(day.name, systemImage: "checkmark")
                                } else {
                                    Text(day.name)
                                }
                            }
                        }
                    } label: {
                        Label("Choose a different day", systemImage: "calendar")
                    }
                }
            }

            Section {
                ForEach(selectedDay.sortedExercises) { exercise in
                    if let session = exercise.session(forWeek: week) {
                        exerciseRow(session: session, exercise: exercise)
                    }
                }
            } header: {
                Text(workout.totalWeeks > 1 ? "\(selectedDay.name) · Week \(week)" : selectedDay.name)
            } footer: {
                Text("Do exercises in any order. Swipe left on an exercise to skip it.")
            }

            Section {
                Button(action: finishTapped) {
                    HStack {
                        Spacer()
                        Text("Finish Day")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
        }
        .navigationDestination(item: $activeExercise) { item in
            destination(session: item.session, exercise: item.exercise)
        }
        .confirmationDialog(
            "Finish Day?",
            isPresented: $showFinishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finish Day") { finishDay() }
            Button("Cancel", role: .cancel) { }
        } message: {
            let count = pending.count
            Text("\(count) exercise\(count == 1 ? "" : "s") not done will be marked skipped.")
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func exerciseRow(session: ExerciseSession, exercise: WorkoutExercise) -> some View {
        if session.completed {
            ExerciseRow(
                name: exercise.exercise.name,
                detail: detail(session: session, exercise: exercise),
                status: .done
            )
        } else {
            Button {
                activeExercise = ActiveExercise(session: session, exercise: exercise)
            } label: {
                HStack {
                    ExerciseRow(
                        name: exercise.exercise.name,
                        detail: detail(session: session, exercise: exercise),
                        status: status(for: session)
                    )
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !session.skipped {
                    Button {
                        skip(session: session, exercise: exercise)
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .tint(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private func destination(session: ExerciseSession, exercise: WorkoutExercise) -> some View {
        if exercise.isCardio {
            // Cardio is entered on the shared session editor (distance, time, heart rate...).
            EditSessionView(session: session)
        } else if exercise.isFreeform {
            LiveSingleWorkoutView(session: session, workoutExercise: exercise)
        } else {
            ExerciseSessionView(session: session, workoutExercise: exercise)
        }
    }

    private func status(for session: ExerciseSession) -> ExerciseRow.Status {
        if session.completed { return .done }
        if session.skipped { return .skipped }
        if session.paused || session.hasLoggedSets { return .inProgress }
        return .todo
    }

    private func detail(session: ExerciseSession, exercise: WorkoutExercise) -> String {
        if exercise.isCardio {
            return session.completed
                ? WorkoutSummaryService.cardioDetail(session, useMetric: useMetric)
                : WorkoutSummaryService.cardioPlanDetail(session, useMetric: useMetric)
        }
        if exercise.isFreeform {
            let logged = session.sets.filter { $0.completed }.count
            return logged > 0 ? "\(logged) set\(logged == 1 ? "" : "s") logged" : "Log sets as you go"
        }
        return "\(session.plannedSets) × \(session.plannedReps) @ \(Int(session.plannedWeight)) \(unitLabel)"
    }

    // MARK: - Actions

    private func skip(session: ExerciseSession, exercise: WorkoutExercise) {
        session.skipped = true
        session.paused = false
        DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: exercise)
        try? context.save()
    }

    private func finishTapped() {
        if pending.isEmpty {
            dismiss()
        } else {
            showFinishConfirmation = true
        }
    }

    private func finishDay() {
        let toSkip = pending
        for item in toSkip {
            item.session.skipped = true
            item.session.paused = false
        }
        // One call is enough: it evaluates the whole week.
        if let last = toSkip.last {
            DeloadAdjustmentService.checkAndAdvanceWeek(session: last.session, workoutExercise: last.exercise)
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Row

private struct ExerciseRow: View {
    enum Status {
        case todo, inProgress, done, skipped

        var label: String {
            switch self {
            case .todo: return "To do"
            case .inProgress: return "In progress"
            case .done: return "Done"
            case .skipped: return "Skipped"
            }
        }

        var icon: String {
            switch self {
            case .todo: return "circle"
            case .inProgress: return "circle.lefthalf.filled"
            case .done: return "checkmark.circle.fill"
            case .skipped: return "forward.circle"
            }
        }

        var color: Color {
            switch self {
            case .todo: return .secondary
            case .inProgress: return .orange
            case .done: return .green
            case .skipped: return .gray
            }
        }
    }

    let name: String
    let detail: String
    let status: Status

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundColor(status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(status.label)
                .font(.caption)
                .foregroundColor(status.color)
        }
        .padding(.vertical, 4)
    }
}
