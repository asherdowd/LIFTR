import SwiftUI
import SwiftData

struct MadcowSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var allExercises: [Exercise]
    var onComplete: () -> Void = {}

    @State private var squatStartingWeight: String = ""
    @State private var benchStartingWeight: String = ""
    @State private var rowStartingWeight: String = ""
    @State private var ohpStartingWeight: String = ""
    @State private var deadliftStartingWeight: String = ""
    @State private var totalWeeks: String = "12"
    @State private var weeklyIncrementPct: String = "2.5"

    @State private var showError = false
    @State private var errorMessage = ""

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var isValidInput: Bool {
        guard Double(squatStartingWeight) != nil,
              Double(benchStartingWeight) != nil,
              Double(rowStartingWeight) != nil,
              Double(ohpStartingWeight) != nil,
              Double(deadliftStartingWeight) != nil,
              let weeks = Int(totalWeeks), weeks > 0,
              let pct = Double(weeklyIncrementPct), pct > 0
        else { return false }
        return true
    }

    var body: some View {
        Form {
            Section {
                Text("Madcow 5×5 uses ramping sets building up to a working weight across three days per week. Monday is heavy, Wednesday is lighter, Friday is the heaviest day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text("About This Program")
            }

            Section {
                MadcowWeightInputRow(label: "Squat",          weight: $squatStartingWeight,    unit: unitLabel)
                MadcowWeightInputRow(label: "Bench Press",    weight: $benchStartingWeight,    unit: unitLabel)
                MadcowWeightInputRow(label: "Barbell Row",    weight: $rowStartingWeight,      unit: unitLabel)
                MadcowWeightInputRow(label: "Overhead Press", weight: $ohpStartingWeight,      unit: unitLabel)
                MadcowWeightInputRow(label: "Deadlift",       weight: $deadliftStartingWeight, unit: unitLabel)
            } header: {
                Text("Starting Working Weights")
            } footer: {
                Text("Enter your current 5-rep working weight for each lift. This is the top set on Monday.")
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
                HStack {
                    Text("Weekly Increase")
                    Spacer()
                    TextField("", text: $weeklyIncrementPct)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
            } header: {
                Text("Program Settings")
            } footer: {
                Text("Working weight increases by this percentage each week. 2.5–5% is typical for Madcow.")
            }

            if isValidInput {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        MadcowPreviewRow(label: "Monday",    value: "Squat · Bench · Row (5×5 ramping)")
                        MadcowPreviewRow(label: "Wednesday", value: "Squat · OHP · Deadlift (lighter)")
                        MadcowPreviewRow(label: "Friday",    value: "Squat · Bench · Row (PR sets)")
                        MadcowPreviewRow(label: "Sessions",  value: "\((Int(totalWeeks) ?? 0) * 3) total")
                        if let squatStart = Double(squatStartingWeight),
                           let pct = Double(weeklyIncrementPct),
                           let weeks = Int(totalWeeks) {
                            MadcowPreviewRow(
                                label: "Final Squat (Mon)",
                                value: "\(Int(squatStart * pow(1.0 + pct / 100.0, Double(weeks)))) \(unitLabel)"
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
        .navigationTitle("Madcow 5×5")
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
              let rowStart   = Double(rowStartingWeight),
              let ohpStart   = Double(ohpStartingWeight),
              let deadStart  = Double(deadliftStartingWeight),
              let weeks      = Int(totalWeeks),
              let pct        = Double(weeklyIncrementPct)
        else {
            showErrorMessage("Please fill in all fields with valid values.")
            return
        }

        let useMetric      = globalSettings.first?.useMetric ?? false
        let multiplier     = 1.0 + pct / 100.0
        let normalizedDate = Calendar.current.startOfDay(for: Date())

        let workout = Workout(
            name: "Madcow 5×5",
            templateType: .madcow,
            totalWeeks: weeks,
            startDate: normalizedDate
        )
        context.insert(workout)

        let squat = findOrCreateExercise(name: "Squat",          coreType: .squat)
        let bench = findOrCreateExercise(name: "Bench Press",    coreType: .benchPress)
        let row   = findOrCreateExercise(name: "Barbell Row",    coreType: nil)
        let ohp   = findOrCreateExercise(name: "Overhead Press", coreType: .overheadPress)
        let dead  = findOrCreateExercise(name: "Deadlift",       coreType: .deadlift)

        let monday = WorkoutDay(name: "Monday", dayNumber: 1)
        monday.workout = workout; workout.days.append(monday); context.insert(monday)
        let mon_squat = makeWorkoutExercise(exercise: squat, order: 0, sets: 5, reps: 5, startingWeight: squatStart)
        let mon_bench = makeWorkoutExercise(exercise: bench, order: 1, sets: 5, reps: 5, startingWeight: benchStart)
        let mon_row   = makeWorkoutExercise(exercise: row,   order: 2, sets: 5, reps: 5, startingWeight: rowStart)
        for we in [mon_squat, mon_bench, mon_row] {
            we.day = monday; monday.exercises.append(we); context.insert(we)
        }

        let wednesday = WorkoutDay(name: "Wednesday", dayNumber: 2)
        wednesday.workout = workout; workout.days.append(wednesday); context.insert(wednesday)
        let wed_squat = makeWorkoutExercise(exercise: squat, order: 0, sets: 5, reps: 5, startingWeight: squatStart * 0.8)
        let wed_ohp   = makeWorkoutExercise(exercise: ohp,   order: 1, sets: 5, reps: 5, startingWeight: ohpStart * 0.8)
        let wed_dead  = makeWorkoutExercise(exercise: dead,  order: 2, sets: 5, reps: 5, startingWeight: deadStart * 0.8)
        for we in [wed_squat, wed_ohp, wed_dead] {
            we.day = wednesday; wednesday.exercises.append(we); context.insert(we)
        }

        let friday = WorkoutDay(name: "Friday", dayNumber: 3)
        friday.workout = workout; workout.days.append(friday); context.insert(friday)
        let fri_squat = makeWorkoutExercise(exercise: squat, order: 0, sets: 5, reps: 5, startingWeight: squatStart)
        let fri_bench = makeWorkoutExercise(exercise: bench, order: 1, sets: 5, reps: 5, startingWeight: benchStart)
        let fri_row   = makeWorkoutExercise(exercise: row,   order: 2, sets: 5, reps: 5, startingWeight: rowStart)
        for we in [fri_squat, fri_bench, fri_row] {
            we.day = friday; friday.exercises.append(we); context.insert(we)
        }

        let calendar    = Calendar.current
        let dayOffsets  = [0, 2, 4]
        let days        = [monday, wednesday, friday]
        let rampPcts: [Double] = [0.55, 0.68, 0.79, 0.90, 1.00]
        var sessionNumber = 1

        for week in 1...weeks {
            let weekMultiplier = pow(multiplier, Double(week - 1))
            for (slotIndex, day) in days.enumerated() {
                let daysFromStart = (week - 1) * 7 + dayOffsets[slotIndex]
                let sessionDate   = calendar.date(byAdding: .day, value: daysFromStart, to: normalizedDate) ?? normalizedDate
                for workoutExercise in day.exercises {
                    let topWeight = (workoutExercise.startingWeight * weekMultiplier)
                        .roundedToNearestFive(useMetric: useMetric)
                    let session = ExerciseSession(
                        date: sessionDate, weekNumber: week, sessionNumber: sessionNumber,
                        plannedWeight: topWeight, plannedSets: workoutExercise.targetSets,
                        plannedReps: workoutExercise.targetReps
                    )
                    session.workoutExercise = workoutExercise
                    workoutExercise.sessions.append(session)
                    context.insert(session)
                    for (setIndex, rampPct) in rampPcts.enumerated() {
                        let setWeight = (topWeight * rampPct).roundedToNearestFive(useMetric: useMetric)
                        let workoutSet = WorkoutSet(setNumber: setIndex + 1,
                                                    targetReps: workoutExercise.targetReps,
                                                    targetWeight: setWeight)
                        workoutSet.exerciseSession = session
                        session.sets.append(workoutSet)
                        context.insert(workoutSet)
                    }
                }
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

    private func findOrCreateExercise(name: String, coreType: ExerciseCoreType?) -> Exercise {
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

struct MadcowWeightInputRow: View {
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

struct MadcowPreviewRow: View {
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
    NavigationView { MadcowSetupView() }
}
