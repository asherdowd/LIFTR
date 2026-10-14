import SwiftUI
import SwiftData

// MARK: - Day Definition (in-memory only, not a SwiftData model)

struct CustomDayDefinition: Identifiable {
    let id: UUID = UUID()
    var name: String
    var exercises: [CustomExerciseDefinition]
}

struct CustomExerciseDefinition: Identifiable {
    let id: UUID = UUID()
    var exercise: Exercise?
    var newExerciseName: String = ""
    var isAddingNew: Bool = false
    var startingWeight: String = ""
    var targetWeight: String = ""
    var increment: String = "5"
    var sets: Int = 3
    var reps: Int = 5
    var progressionStyle: ProgressionStyle = .linear
}

// MARK: - Setup View

struct CustomProgramSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var allExercises: [Exercise]
    var onComplete: () -> Void = {}

    @State private var programName: String = ""
    @State private var totalWeeks: Int = 12
    @State private var sessionsPerWeek: Int = 3
    @State private var days: [CustomDayDefinition] = []

    @State private var showError = false
    @State private var errorMessage = ""

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var isValidInput: Bool {
        guard !programName.trimmingCharacters(in: .whitespaces).isEmpty,
              !days.isEmpty,
              days.allSatisfy({ !$0.exercises.isEmpty })
        else { return false }

        for day in days {
            for ex in day.exercises {
                let name = ex.isAddingNew
                    ? ex.newExerciseName.trimmingCharacters(in: .whitespaces)
                    : ex.exercise?.name ?? ""
                guard !name.isEmpty,
                      Double(ex.startingWeight) != nil,
                      Double(ex.targetWeight) != nil,
                      Double(ex.increment) != nil
                else { return false }
            }
        }
        return true
    }

    var body: some View {
        Form {
            // Program Info
            Section {
                TextField("Program Name", text: $programName)
                    .autocapitalization(.words)

                HStack {
                    Text("Total Weeks")
                    Spacer()
                    Stepper("\(totalWeeks) weeks", value: $totalWeeks, in: 1...52)
                }

                HStack {
                    Text("Days per Week")
                    Spacer()
                    Stepper("\(sessionsPerWeek) days", value: $sessionsPerWeek, in: 1...7)
                        .onChange(of: sessionsPerWeek) { _, newValue in
                            syncDayCount(to: newValue)
                        }
                }
            } header: {
                Text("Program Details")
            }

            // Days
            ForEach($days) { $day in
                Section {
                    TextField("Day Name", text: $day.name)
                        .autocapitalization(.words)

                    ForEach($day.exercises) { $ex in
                        CustomExerciseRow(
                            ex: $ex,
                            allExercises: allExercises,
                            unitLabel: unitLabel
                        )
                    }
                    .onDelete { indexSet in
                        day.exercises.remove(atOffsets: indexSet)
                    }

                    Button("+ Add Exercise") {
                        day.exercises.append(CustomExerciseDefinition())
                    }
                    .font(.subheadline)
                } header: {
                    Text(day.name.isEmpty ? "Day \(dayIndex(day) + 1)" : day.name)
                }
            }

            // Create
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
        .navigationTitle("Custom Program")
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
        .onAppear {
            if days.isEmpty { syncDayCount(to: sessionsPerWeek) }
        }
    }

    // MARK: - Helpers

    private func dayIndex(_ day: CustomDayDefinition) -> Int {
        days.firstIndex(where: { $0.id == day.id }) ?? 0
    }

    private func syncDayCount(to count: Int) {
        let current = days.count
        if count > current {
            for i in current..<count {
                days.append(CustomDayDefinition(name: "Day \(i + 1)", exercises: []))
            }
        } else if count < current {
            days = Array(days.prefix(count))
        }
    }

    // MARK: - Create

    private func createProgram() {
        let useMetric      = globalSettings.first?.useMetric ?? false
        let normalizedDate = Calendar.current.startOfDay(for: Date())
        let calendar       = Calendar.current

        let workout = Workout(
            name: programName.trimmingCharacters(in: .whitespaces),
            templateType: .custom,
            totalWeeks: totalWeeks,
            startDate: normalizedDate
        )
        context.insert(workout)

        for (dayIndex, dayDef) in days.enumerated() {
            let workoutDay = WorkoutDay(name: dayDef.name, dayNumber: dayIndex + 1)
            workoutDay.workout = workout
            workout.days.append(workoutDay)
            context.insert(workoutDay)

            for (exIndex, exDef) in dayDef.exercises.enumerated() {
                let exName = exDef.isAddingNew
                    ? exDef.newExerciseName.trimmingCharacters(in: .whitespaces)
                    : exDef.exercise?.name ?? ""

                guard let startW  = Double(exDef.startingWeight),
                      let targetW = Double(exDef.targetWeight),
                      let inc     = Double(exDef.increment)
                else { continue }

                let exercise = findOrCreateExercise(name: exName)

                let workoutExercise = WorkoutExercise(
                    exercise: exercise,
                    orderIndex: exIndex,
                    progressionStyle: exDef.progressionStyle,
                    startingWeight: startW,
                    targetSets: exDef.sets,
                    targetReps: exDef.reps,
                    increment: inc
                )
                workoutExercise.day = workoutDay
                workoutDay.exercises.append(workoutExercise)
                context.insert(workoutExercise)

                // Generate sessions — one per week per day slot
                var sessionNumber = 1
                for week in 1...totalWeeks {
                    let daysFromStart = (week - 1) * 7 + dayIndex
                    let sessionDate   = calendar.date(byAdding: .day, value: daysFromStart, to: normalizedDate) ?? normalizedDate

                    let weekWeight: Double
                    switch exDef.progressionStyle {
                    case .linear:
                        weekWeight = (startW + inc * Double(week - 1)).roundedToNearestFive(useMetric: useMetric)
                    case .periodization:
                        let cycleWeek = (week - 1) % 3
                        let baseCycle = (week - 1) / 3
                        let cycleStart = startW + inc * 3 * Double(baseCycle)
                        switch cycleWeek {
                        case 0: weekWeight = (cycleStart * 0.9).roundedToNearestFive(useMetric: useMetric)
                        case 1: weekWeight = (cycleStart * 0.95).roundedToNearestFive(useMetric: useMetric)
                        default: weekWeight = cycleStart.roundedToNearestFive(useMetric: useMetric)
                        }
                    }

                    // Cap at target weight
                    let plannedWeight = min(weekWeight, targetW)

                    let session = ExerciseSession(
                        date: sessionDate,
                        weekNumber: week,
                        sessionNumber: sessionNumber,
                        plannedWeight: plannedWeight,
                        plannedSets: exDef.sets,
                        plannedReps: exDef.reps
                    )
                    session.workoutExercise = workoutExercise
                    workoutExercise.sessions.append(session)
                    context.insert(session)

                    for setNumber in 1...exDef.sets {
                        let workoutSet = WorkoutSet(
                            setNumber: setNumber,
                            targetReps: exDef.reps,
                            targetWeight: plannedWeight
                        )
                        workoutSet.exerciseSession = session
                        session.sets.append(workoutSet)
                        context.insert(workoutSet)
                    }

                    sessionNumber += 1
                }
            }
        }

        do {
            try context.save()
            onComplete()
        } catch {
            showErrorMessage("Failed to save program: \(error.localizedDescription)")
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

// MARK: - Exercise Row

struct CustomExerciseRow: View {
    @Binding var ex: CustomExerciseDefinition
    let allExercises: [Exercise]
    let unitLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise picker
            if !ex.isAddingNew {
                if allExercises.isEmpty {
                    Button("+ New Exercise") { ex.isAddingNew = true }
                        .font(.subheadline)
                } else {
                    Picker("Exercise", selection: $ex.exercise) {
                        Text("Select...").tag(Optional<Exercise>.none)
                        ForEach(allExercises.sorted(by: { $0.name < $1.name })) { exercise in
                            Text(exercise.name).tag(Optional(exercise))
                        }
                    }
                    Button("+ New Exercise") {
                        ex.exercise = nil
                        ex.isAddingNew = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    TextField("Exercise Name", text: $ex.newExerciseName)
                        .autocapitalization(.words)
                    Button("Cancel") {
                        ex.newExerciseName = ""
                        ex.isAddingNew = false
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // Style
            Picker("Style", selection: $ex.progressionStyle) {
                ForEach(ProgressionStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)

            // Weights
            HStack {
                Text("Start")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("0", text: $ex.startingWeight)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                Text(unitLabel)
                    .font(.caption)
                Spacer()
                Text("Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("0", text: $ex.targetWeight)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                Text(unitLabel)
                    .font(.caption)
            }

            // Sets / Reps / Increment
            HStack {
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Stepper("\(ex.sets)", value: $ex.sets, in: 1...20)
                    .labelsHidden()
                Text("\(ex.sets)")
                    .frame(width: 24)
                Spacer()
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Stepper("\(ex.reps)", value: $ex.reps, in: 1...100)
                    .labelsHidden()
                Text("\(ex.reps)")
                    .frame(width: 24)
            }

            HStack {
                Text("Increment")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("5", text: $ex.increment)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                Text("\(unitLabel)/week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        CustomProgramSetupView()
    }
}
