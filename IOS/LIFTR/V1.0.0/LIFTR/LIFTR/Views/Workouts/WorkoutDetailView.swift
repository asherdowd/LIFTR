import SwiftUI
import SwiftData

// MARK: - Workout Detail (new Workout model)
// Opened from the Details button on WorkoutCardView, in a sheet with its own NavigationStack.
// Pushes use value-based links registered once on this root, so a redraw of a list row
// (for example after toggling completed) cannot pop the pushed screen.
//
//   WorkoutDetailView -> EditWorkoutView            (name, notes, status, week, delete)
//                     -> ExerciseSessionsEditView   (all sessions of one exercise)
//                     -> EditSessionView            (planned values, completed, skipped)

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let workout: Workout
    /// Called after the owner confirms deletion in the edit screen. The card closes this sheet
    /// first and deletes afterwards.
    let onDelete: () -> Void

    var body: some View {
        List {
            Section("Workout") {
                LabeledContent("Type", value: workout.templateType.rawValue)
                LabeledContent("Status", value: workout.status.rawValue)
                if workout.totalWeeks > 1 {
                    LabeledContent("Week", value: "\(workout.currentWeek) of \(workout.totalWeeks)")
                }
                LabeledContent("Started", value: workout.startDate.formatted(date: .abbreviated, time: .omitted))
                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                NavigationLink(value: workout) {
                    Label("Edit Workout", systemImage: "pencil")
                }
            }

            ForEach(workout.sortedDays) { day in
                Section(day.name) {
                    ForEach(day.sortedExercises) { workoutExercise in
                        NavigationLink(value: workoutExercise) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workoutExercise.exercise.name)
                                    .font(.headline)
                                Text(progressText(for: workoutExercise))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
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
        .navigationDestination(for: Workout.self) { workout in
            EditWorkoutView(workout: workout, onDelete: onDelete)
        }
        .navigationDestination(for: WorkoutExercise.self) { workoutExercise in
            ExerciseSessionsEditView(workoutExercise: workoutExercise)
        }
        .navigationDestination(for: ExerciseSession.self) { session in
            EditSessionView(session: session)
        }
    }

    private func progressText(for workoutExercise: WorkoutExercise) -> String {
        let total = workoutExercise.sessions.count
        let done = workoutExercise.sessions.filter { $0.isDone }.count
        return "\(done) of \(total) sessions done"
    }
}

// MARK: - Edit Workout

struct EditWorkoutView: View {
    @Environment(\.modelContext) private var context

    @Bindable var workout: Workout
    let onDelete: () -> Void

    @State private var originalName: String
    @State private var showDeleteConfirmation = false

    init(workout: Workout, onDelete: @escaping () -> Void) {
        self.workout = workout
        self.onDelete = onDelete
        _originalName = State(initialValue: workout.name)
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { workout.notes ?? "" },
            set: { workout.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private var weekBinding: Binding<Int> {
        Binding(
            get: { workout.currentWeek },
            set: { WorkoutEditService.setCurrentWeek($0, workout: workout) }
        )
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Workout name", text: $workout.name)
            }

            Section("Notes") {
                TextField("Notes", text: notesBinding, axis: .vertical)
                    .lineLimit(1...5)
            }

            Section {
                Picker("Status", selection: $workout.status) {
                    Text(ProgressionStatus.active.rawValue).tag(ProgressionStatus.active)
                    // Paused has no behavior in the app yet (decision 2026-10-14), so it is only
                    // listed for a workout that already has it, keeping the picker valid.
                    if workout.status == .paused {
                        Text(ProgressionStatus.paused.rawValue).tag(ProgressionStatus.paused)
                    }
                    Text(ProgressionStatus.completed.rawValue).tag(ProgressionStatus.completed)
                }

                if workout.totalWeeks > 1 {
                    Stepper("Current week: \(workout.currentWeek) of \(workout.totalWeeks)",
                            value: weekBinding, in: 1...max(workout.totalWeeks, 1))
                }
            } footer: {
                Text("Only Active workouts appear on the Workouts tab.")
            }

            Section {
                Button("Delete Workout", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if workout.name.trimmingCharacters(in: .whitespaces).isEmpty {
                workout.name = originalName
            }
            try? context.save()
        }
        .confirmationDialog(
            "Delete Workout",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all workout history and cannot be undone.")
        }
    }
}

// MARK: - Sessions of one exercise

struct ExerciseSessionsEditView: View {
    @Query private var globalSettings: [GlobalProgressionSettings]

    let workoutExercise: WorkoutExercise

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var useMetric: Bool {
        globalSettings.first?.useMetric == true
    }

    private var sortedSessions: [ExerciseSession] {
        workoutExercise.sessions.sorted {
            ($0.weekNumber, $0.sessionNumber) < ($1.weekNumber, $1.sessionNumber)
        }
    }

    var body: some View {
        List(sortedSessions) { session in
            NavigationLink(value: session) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title(for: session))
                            .font(.headline)
                        Text(detail(for: session))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(statusText(for: session))
                        .font(.caption)
                        .foregroundColor(statusColor(for: session))
                }
            }
        }
        .navigationTitle(workoutExercise.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func title(for session: ExerciseSession) -> String {
        let sameWeek = workoutExercise.sessions.filter { $0.weekNumber == session.weekNumber }.count
        return sameWeek > 1
            ? "Week \(session.weekNumber) · Session \(session.sessionNumber)"
            : "Week \(session.weekNumber)"
    }

    private func detail(for session: ExerciseSession) -> String {
        if workoutExercise.isCardio {
            return session.completed
                ? WorkoutSummaryService.cardioDetail(session, useMetric: useMetric)
                : WorkoutSummaryService.cardioPlanDetail(session, useMetric: useMetric)
        }
        if workoutExercise.isFreeform {
            let logged = session.sets.filter { $0.completed }.count
            return "\(logged) set\(logged == 1 ? "" : "s") logged"
        }
        return "\(session.plannedSets) × \(session.plannedReps) @ \(Int(session.plannedWeight)) \(unitLabel)"
    }

    private func statusText(for session: ExerciseSession) -> String {
        if session.completed { return "Done" }
        if session.skipped { return "Skipped" }
        return "To do"
    }

    private func statusColor(for session: ExerciseSession) -> Color {
        if session.completed { return .green }
        if session.skipped { return .gray }
        return .secondary
    }
}

// MARK: - Edit one session

struct EditSessionView: View {
    @Environment(\.modelContext) private var context
    @Query private var globalSettings: [GlobalProgressionSettings]

    @Bindable var session: ExerciseSession

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var isFreeform: Bool {
        session.workoutExercise?.isFreeform ?? false
    }

    private var isCardio: Bool {
        session.workoutExercise?.isCardio ?? false
    }

    private var useMetric: Bool {
        globalSettings.first?.useMetric == true
    }

    // Distance is stored in meters, elevation in meters and duration in seconds (SI). The
    // editor shows the user's units: km or mi, m or ft, minutes.
    private var metersPerDistanceUnit: Double { useMetric ? 1000 : 1609.344 }
    private var metersPerElevationUnit: Double { useMetric ? 1 : 0.3048 }

    private func scaled(_ keyPath: ReferenceWritableKeyPath<ExerciseSession, Double?>, by factor: Double) -> Binding<Double?> {
        Binding(
            get: { session[keyPath: keyPath].map { $0 / factor } },
            set: { session[keyPath: keyPath] = $0.map { $0 * factor } }
        )
    }

    private var completedBinding: Binding<Bool> {
        Binding(
            get: { session.completed },
            set: { WorkoutEditService.setCompleted($0, session: session); try? context.save() }
        )
    }

    private var skippedBinding: Binding<Bool> {
        Binding(
            get: { session.skipped },
            set: { WorkoutEditService.setSkipped($0, session: session); try? context.save() }
        )
    }

    var body: some View {
        Form {
            if isCardio {
                Section("Planned") {
                    labeledField("Distance (\(useMetric ? "km" : "mi"))", value: scaled(\.plannedDistance, by: metersPerDistanceUnit))
                    labeledField("Duration (min)", value: scaled(\.plannedDuration, by: 60))
                }

                Section("Recorded") {
                    labeledField("Distance (\(useMetric ? "km" : "mi"))", value: scaled(\.distance, by: metersPerDistanceUnit))
                    labeledField("Duration (min)", value: scaled(\.duration, by: 60))
                    labeledField("Elevation gain (\(useMetric ? "m" : "ft"))", value: scaled(\.elevationGain, by: metersPerElevationUnit))
                }
            }

            Section {
                labeledField("Average heart rate (bpm)", value: $session.avgHeartRate)
                labeledField("Max heart rate (bpm)", value: $session.maxHeartRate)
                labeledField("Calories (kcal)", value: $session.caloriesBurned)
            } header: {
                Text("Heart rate and energy (optional)")
            } footer: {
                if let source = session.dataSource {
                    Text("Source: \(source.rawValue)")
                }
            }

            if session.startTime != nil || session.endTime != nil {
                Section("Time") {
                    if let start = session.startTime {
                        LabeledContent("Started", value: start.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let end = session.endTime {
                        LabeledContent("Ended", value: end.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            if !isFreeform && !isCardio {
                Section {
                    HStack {
                        Text("Weight (\(unitLabel))")
                        Spacer()
                        TextField("Weight", value: $session.plannedWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    Stepper("Sets: \(session.plannedSets)", value: $session.plannedSets, in: 1...20)
                    Stepper("Reps: \(session.plannedReps)", value: $session.plannedReps, in: 1...100)
                } header: {
                    Text("Planned")
                } footer: {
                    Text("Changes this session only. Other weeks are not affected.")
                }
            }

            Section {
                Toggle("Completed", isOn: completedBinding)
                Toggle("Skipped", isOn: skippedBinding)
            } footer: {
                Text("Marking the last open session of a week advances the workout to the next week.")
            }
        }
        .navigationTitle("Week \(session.weekNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? context.save() }
    }

    private func labeledField(_ title: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
    }
}
