import SwiftUI
import SwiftData

struct LogSingleStrengthView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var allExercises: [Exercise]
    var onComplete: () -> Void = {}

    @State private var selectedExercise: Exercise?
    @State private var newExerciseName: String = ""
    @State private var isAddingNewExercise: Bool = false
    @State private var startingWeight: String = ""

    @State private var navigateToLiveWorkout = false
    @State private var createdSession: ExerciseSession?
    @State private var createdWorkoutExercise: WorkoutExercise?

    @State private var showError = false
    @State private var errorMessage = ""

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var effectiveExerciseName: String {
        isAddingNewExercise
            ? newExerciseName.trimmingCharacters(in: .whitespaces)
            : selectedExercise?.name ?? ""
    }

    private var isValidInput: Bool {
        !effectiveExerciseName.isEmpty && Double(startingWeight) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !isAddingNewExercise {
                        if allExercises.isEmpty {
                            Button("Add New Exercise") { isAddingNewExercise = true }
                        } else {
                            Picker("Exercise", selection: $selectedExercise) {
                                Text("Select...").tag(Optional<Exercise>.none)
                                ForEach(allExercises.sorted(by: { $0.name < $1.name })) { exercise in
                                    Text(exercise.name).tag(Optional(exercise))
                                }
                            }
                            Button("+ New Exercise") {
                                selectedExercise = nil
                                isAddingNewExercise = true
                            }
                            .font(.subheadline)
                        }
                    } else {
                        TextField("Exercise Name", text: $newExerciseName)
                            .autocapitalization(.words)
                        Button("Cancel") {
                            newExerciseName = ""
                            isAddingNewExercise = false
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Exercise")
                }

                Section {
                    HStack {
                        Text("Starting Weight")
                        Spacer()
                        TextField("0", text: $startingWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unitLabel)
                    }
                } header: {
                    Text("Weight")
                } footer: {
                    Text("You'll add sets on the next screen.")
                }

                Section {
                    Button(action: startWorkout) {
                        HStack {
                            Spacer()
                            Text("Start Workout")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("Single Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $navigateToLiveWorkout) {
                if let session = createdSession, let we = createdWorkoutExercise {
                    LiveSingleWorkoutView(
                        session: session,
                        workoutExercise: we,
                        onComplete: onComplete
                    )
                }
            }
            .onChange(of: navigateToLiveWorkout) { _, isShowing in
                if !isShowing { removeWorkoutIfNothingLogged() }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func startWorkout() {
        guard let weightValue = Double(startingWeight) else { return }

        let exercise = findOrCreateExercise(name: effectiveExerciseName)
        let today = Calendar.current.startOfDay(for: Date())

        let workout = Workout(
            name: effectiveExerciseName,
            templateType: .custom,
            totalWeeks: 1,
            startDate: today
        )
        context.insert(workout)

        let day = WorkoutDay(name: "Workout", dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            orderIndex: 0,
            progressionStyle: .linear,
            startingWeight: weightValue,
            targetSets: 0,
            targetReps: 0
        )
        workoutExercise.day = day
        day.exercises.append(workoutExercise)
        context.insert(workoutExercise)

        let session = ExerciseSession(
            date: today,
            weekNumber: 1,
            sessionNumber: 1,
            plannedWeight: weightValue,
            plannedSets: 0,
            plannedReps: 0
        )
        session.workoutExercise = workoutExercise
        workoutExercise.sessions.append(session)
        context.insert(session)

        do {
            try context.save()
            createdSession = session
            createdWorkoutExercise = workoutExercise
            navigateToLiveWorkout = true
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Runs when the live workout screen is left (Cancel or Back). If no set was completed,
    /// the empty Workout created for it is deleted. A workout with logged sets is kept.
    /// Deletion is delayed until the pop animation has finished so the leaving screen never
    /// reads a deleted object.
    private func removeWorkoutIfNothingLogged() {
        guard let session = createdSession, let workoutExercise = createdWorkoutExercise else { return }
        guard !session.completed, !session.hasLoggedSets else {
            createdSession = nil
            createdWorkoutExercise = nil
            return
        }
        let workout = workoutExercise.day?.workout
        let modelContext = context
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if let workout {
                modelContext.delete(workout)
                try? modelContext.save()
            }
            createdSession = nil
            createdWorkoutExercise = nil
        }
    }

    private func findOrCreateExercise(name: String) -> Exercise {
        if let existing = allExercises.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) { return existing }
        let exercise = Exercise(name: name, coreType: nil)
        context.insert(exercise)
        return exercise
    }
}

#Preview {
    NavigationStack { LogSingleStrengthView() }
}
