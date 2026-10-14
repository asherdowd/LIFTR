import SwiftUI
import SwiftData

struct StartingStrengthSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var allExercises: [Exercise]
    var onComplete: () -> Void = {}

    @State private var squatStartingWeight: String = ""
    @State private var benchStartingWeight: String = ""
    @State private var ohpStartingWeight: String = ""
    @State private var deadliftStartingWeight: String = ""
    @State private var totalWeeks: String = "12"
    @State private var lowerBodyIncrement: String = "5"
    @State private var upperBodyIncrement: String = "2.5"

    @State private var showError = false
    @State private var errorMessage = ""

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var isValidInput: Bool {
        guard Double(squatStartingWeight) != nil,
              Double(benchStartingWeight) != nil,
              Double(ohpStartingWeight) != nil,
              Double(deadliftStartingWeight) != nil,
              let weeks = Int(totalWeeks), weeks > 0,
              Double(lowerBodyIncrement) != nil,
              Double(upperBodyIncrement) != nil
        else { return false }
        return true
    }

    private var calculatedTotalSessions: Int {
        (Int(totalWeeks) ?? 0) * 3
    }

    var body: some View {
        Form {
            Section {
                Text("Starting Strength uses two alternating workouts (A and B) performed 3 days per week. Squat and Deadlift appear in every session. Bench Press and Overhead Press alternate.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text("About This Program")
            }

            Section {
                SSWeightInputRow(label: "Squat", weight: $squatStartingWeight, unit: unitLabel)
                SSWeightInputRow(label: "Bench Press", weight: $benchStartingWeight, unit: unitLabel)
                SSWeightInputRow(label: "Overhead Press", weight: $ohpStartingWeight, unit: unitLabel)
                SSWeightInputRow(label: "Deadlift", weight: $deadliftStartingWeight, unit: unitLabel)
            } header: {
                Text("Starting Weights")
            } footer: {
                Text("Enter your current working weight for each lift.")
            }

            Section {
                HStack {
                    Text("Total Weeks")
                    Spacer()
                    TextField("", text: $totalWeeks)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("weeks")
                }
            } header: {
                Text("Program Length")
            }

            Section {
                HStack {
                    Text("Squat / Deadlift")
                    Spacer()
                    TextField("", text: $lowerBodyIncrement)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text(unitLabel)
                }
                HStack {
                    Text("Bench / OHP")
                    Spacer()
                    TextField("", text: $upperBodyIncrement)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text(unitLabel)
                }
            } header: {
                Text("Weight Increment Per Session")
            } footer: {
                Text("Starting Strength adds weight every session. Typical: 5 \(unitLabel) lower body, 2.5 \(unitLabel) upper body.")
            }

            if isValidInput {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        SSPreviewRow(label: "Workout A", value: "Squat · Bench · Deadlift")
                        SSPreviewRow(label: "Workout B", value: "Squat · OHP · Deadlift")
                        SSPreviewRow(label: "Sessions", value: "\(calculatedTotalSessions) total (\(totalWeeks) weeks × 3/week)")
                        if let squatStart = Double(squatStartingWeight),
                           let lbInc = Double(lowerBodyIncrement) {
                            SSPreviewRow(
                                label: "Final Squat",
                                value: "\(Int((squatStart + lbInc * Double(calculatedTotalSessions)).roundedToNearestFive(useMetric: globalSettings.first?.useMetric ?? false))) \(unitLabel)"
                            )
                        }
                    }
                    .font(.subheadline)
                } header: {
                    Text("Preview")
                }
            }

            Section {
                Button(action: createProgram) {
                    HStack {
                        Spacer()
                        Text("Create Program")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValidInput)
            }
        }
        .navigationTitle("Starting Strength")
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

    private func createProgram() {
        guard let squatStart = Double(squatStartingWeight),
              let benchStart = Double(benchStartingWeight),
              let ohpStart   = Double(ohpStartingWeight),
              let deadStart  = Double(deadliftStartingWeight),
              let weeks      = Int(totalWeeks),
              let lbInc      = Double(lowerBodyIncrement),
              let ubInc      = Double(upperBodyIncrement)
        else {
            showErrorMessage("Please fill in all fields with valid values.")
            return
        }

        let useMetric      = globalSettings.first?.useMetric ?? false
        let normalizedDate = Calendar.current.startOfDay(for: Date())

        let workout = Workout(
            name: "Starting Strength",
            templateType: .startingStrength,
            totalWeeks: weeks,
            startDate: normalizedDate
        )
        context.insert(workout)

        let squat = findOrCreateExercise(name: "Squat",          coreType: .squat)
        let bench = findOrCreateExercise(name: "Bench Press",    coreType: .benchPress)
        let ohp   = findOrCreateExercise(name: "Overhead Press", coreType: .overheadPress)
        let dead  = findOrCreateExercise(name: "Deadlift",       coreType: .deadlift)

        let dayA = WorkoutDay(name: "Workout A", dayNumber: 1)
        dayA.workout = workout
        workout.days.append(dayA)
        context.insert(dayA)

        let weA_squat = makeWorkoutExercise(exercise: squat, order: 0, sets: 3, reps: 5, startingWeight: squatStart)
        let weA_bench = makeWorkoutExercise(exercise: bench, order: 1, sets: 3, reps: 5, startingWeight: benchStart)
        let weA_dead  = makeWorkoutExercise(exercise: dead,  order: 2, sets: 1, reps: 5, startingWeight: deadStart)
        for we in [weA_squat, weA_bench, weA_dead] {
            we.day = dayA; dayA.exercises.append(we); context.insert(we)
        }

        let dayB = WorkoutDay(name: "Workout B", dayNumber: 2)
        dayB.workout = workout
        workout.days.append(dayB)
        context.insert(dayB)

        let weB_squat = makeWorkoutExercise(exercise: squat, order: 0, sets: 3, reps: 5, startingWeight: squatStart)
        let weB_ohp   = makeWorkoutExercise(exercise: ohp,   order: 1, sets: 3, reps: 5, startingWeight: ohpStart)
        let weB_dead  = makeWorkoutExercise(exercise: dead,  order: 2, sets: 1, reps: 5, startingWeight: deadStart)
        for we in [weB_squat, weB_ohp, weB_dead] {
            we.day = dayB; dayB.exercises.append(we); context.insert(we)
        }

        let calendar   = Calendar.current
        let dayOffsets = [0, 2, 4]
        var sessionNumber = 1
        var isADay = true

        for week in 1...weeks {
            for slotIndex in 0..<3 {
                let daysFromStart = (week - 1) * 7 + dayOffsets[slotIndex]
                let sessionDate   = calendar.date(byAdding: .day, value: daysFromStart, to: normalizedDate) ?? normalizedDate
                let day           = isADay ? dayA : dayB

                for workoutExercise in day.exercises {
                    let isLowerBody = workoutExercise.exercise.coreType == .squat ||
                                      workoutExercise.exercise.coreType == .deadlift
                    let increment   = isLowerBody ? lbInc : ubInc
                    let weight      = (workoutExercise.startingWeight + increment * Double(sessionNumber - 1))
                        .roundedToNearestFive(useMetric: useMetric)

                    let session = ExerciseSession(
                        date: sessionDate,
                        weekNumber: week,
                        sessionNumber: sessionNumber,
                        plannedWeight: weight,
                        plannedSets: workoutExercise.targetSets,
                        plannedReps: workoutExercise.targetReps
                    )
                    session.workoutExercise = workoutExercise
                    workoutExercise.sessions.append(session)
                    context.insert(session)

                    for setNumber in 1...workoutExercise.targetSets {
                        let workoutSet = WorkoutSet(
                            setNumber: setNumber,
                            targetReps: workoutExercise.targetReps,
                            targetWeight: weight
                        )
                        workoutSet.exerciseSession = session
                        session.sets.append(workoutSet)
                        context.insert(workoutSet)
                    }
                }
                isADay = !isADay
                sessionNumber += 1
            }
        }

        do {
            try context.save()
            onComplete()
        } catch {
            showErrorMessage("Failed to save program: \(error.localizedDescription)")
        }
    }

    private func findOrCreateExercise(name: String, coreType: ExerciseCoreType) -> Exercise {
        if let existing = allExercises.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) { return existing }
        let exercise = Exercise(name: name, coreType: coreType)
        context.insert(exercise)
        return exercise
    }

    private func makeWorkoutExercise(exercise: Exercise, order: Int, sets: Int, reps: Int, startingWeight: Double) -> WorkoutExercise {
        WorkoutExercise(exercise: exercise, orderIndex: order, progressionStyle: .linear,
                        startingWeight: startingWeight, targetSets: sets, targetReps: reps, increment: 0)
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message; showError = true
    }
}

struct SSWeightInputRow: View {
    let label: String
    @Binding var weight: String
    let unit: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
            Text(unit)
        }
    }
}

struct SSPreviewRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationView { StartingStrengthSetupView() }
}
