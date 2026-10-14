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
    @State private var weight: String = ""
    @State private var sets: String = "3"
    @State private var reps: String = "5"

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
        guard !effectiveExerciseName.isEmpty,
              Double(weight) != nil,
              let s = Int(sets), s > 0,
              let r = Int(reps), r > 0
        else { return false }
        return true
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if !isAddingNewExercise {
                        if allExercises.isEmpty {
                            Button("Add New Exercise") {
                                isAddingNewExercise = true
                            }
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
                        Text("Weight")
                        Spacer()
                        TextField("0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unitLabel)
                    }

                    HStack {
                        Text("Sets")
                        Spacer()
                        Stepper("\(sets)", value: Binding(
                            get: { Int(sets) ?? 3 },
                            set: { sets = String($0) }
                        ), in: 1...20)
                    }

                    HStack {
                        Text("Reps")
                        Spacer()
                        Stepper("\(reps)", value: Binding(
                            get: { Int(reps) ?? 5 },
                            set: { reps = String($0) }
                        ), in: 1...100)
                    }
                } header: {
                    Text("Details")
                }

                Section {
                    Button(action: logWorkout) {
                        HStack {
                            Spacer()
                            Text("Log Workout")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func logWorkout() {
        guard let weightValue = Double(weight),
              let setsValue = Int(sets),
              let repsValue = Int(reps)
        else {
            showErrorMessage("Please fill in all fields with valid values.")
            return
        }

        let exercise = findOrCreateExercise(name: effectiveExerciseName)
        let today = Calendar.current.startOfDay(for: Date())

        // Create a minimal Workout representing today's single session
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
            targetSets: setsValue,
            targetReps: repsValue
        )
        workoutExercise.day = day
        day.exercises.append(workoutExercise)
        context.insert(workoutExercise)

        // Single session, marked completed immediately
        let session = ExerciseSession(
            date: today,
            weekNumber: 1,
            sessionNumber: 1,
            plannedWeight: weightValue,
            plannedSets: setsValue,
            plannedReps: repsValue,
            completed: true,
            completedDate: Date()
        )
        session.workoutExercise = workoutExercise
        workoutExercise.sessions.append(session)
        context.insert(session)

        for setNumber in 1...setsValue {
            let workoutSet = WorkoutSet(
                setNumber: setNumber,
                targetReps: repsValue,
                targetWeight: weightValue,
                completed: true
            )
            workoutSet.exerciseSession = session
            session.sets.append(workoutSet)
            context.insert(workoutSet)
        }

        do {
            try context.save()
            onComplete()
        } catch {
            showErrorMessage("Failed to save workout: \(error.localizedDescription)")
        }
    }

    private func findOrCreateExercise(name: String) -> Exercise {
        if let existing = allExercises.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return existing
        }
        let exercise = Exercise(name: name, coreType: nil)
        context.insert(exercise)
        return exercise
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    NavigationView {
        LogSingleStrengthView()
    }
}
