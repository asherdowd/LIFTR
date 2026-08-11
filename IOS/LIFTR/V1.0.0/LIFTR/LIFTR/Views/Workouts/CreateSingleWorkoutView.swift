import SwiftUI
import SwiftData

enum PresetExercise: String, CaseIterable, Identifiable {
    case squat = "Squat"
    case benchPress = "Bench Press"
    case deadlift = "Deadlift"
    case overheadPress = "Overhead Press"
    case custom = "Custom"

    var id: String { rawValue }

    var coreType: ExerciseCoreType? {
        switch self {
        case .squat: return .squat
        case .benchPress: return .benchPress
        case .deadlift: return .deadlift
        case .overheadPress: return .overheadPress
        case .custom: return nil
        }
    }
}

struct CreateSingleWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var allExercises: [Exercise]
    var onComplete: () -> Void = {}
    @State private var selectedPreset: PresetExercise = .squat
    @State private var customExerciseName: String = ""
    @State private var selectedStyle: ProgressionStyle = .linear
    @State private var currentMax: String = ""
    @State private var targetMax: String = ""
    @State private var totalWeeks: String = "12"
    @State private var setsPerWorkout: String = "3"
    @State private var repsPerSet: String = "5"
    @State private var sessionsPerWeek: String = "1"

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise")) {
                    Picker("Exercise", selection: $selectedPreset) {
                        ForEach(PresetExercise.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedPreset == .custom {
                        TextField("Exercise Name", text: $customExerciseName)
                            .autocapitalization(.words)
                    }
                }

                Section(header: Text("Progression Style"),
                        footer: Text(selectedStyle.description)) {
                    Picker("Style", selection: $selectedStyle) {
                        ForEach(ProgressionStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Weight Parameters")) {
                    HStack {
                        Text("Current Max")
                        Spacer()
                        TextField("", text: $currentMax)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unitLabel)
                    }

                    HStack {
                        Text("Target Max")
                        Spacer()
                        TextField("", text: $targetMax)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unitLabel)
                    }
                }

                Section(header: Text("Duration")) {
                    HStack {
                        Text("Total Weeks")
                        Spacer()
                        TextField("", text: $totalWeeks)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("weeks")
                    }

                    HStack {
                        Text("Sessions per Week")
                        Spacer()
                        TextField("", text: $sessionsPerWeek)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("sessions")
                    }
                }

                Section(header: Text("Workout Structure")) {
                    HStack {
                        Text("Sets per Session")
                        Spacer()
                        TextField("", text: $setsPerWorkout)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("sets")
                    }

                    HStack {
                        Text("Reps per Set")
                        Spacer()
                        TextField("", text: $repsPerSet)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("reps")
                    }
                }

                if isValidInput {
                    Section(header: Text("Preview")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Starting Weight:")
                                Spacer()
                                Text("\(Int(calculatedStartingWeight)) \(unitLabel)")
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("Weekly Increase:")
                                Spacer()
                                Text("\(String(format: "%.1f", calculatedWeeklyIncrease)) \(unitLabel)")
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("Total Sessions:")
                                Spacer()
                                Text("\(calculatedTotalSessions)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.subheadline)
                    }
                }

                Section {
                    Button(action: createWorkout) {
                        HStack {
                            Spacer()
                            Text("Create Workout")
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var effectiveExerciseName: String {
        selectedPreset == .custom
            ? customExerciseName.trimmingCharacters(in: .whitespaces)
            : selectedPreset.rawValue
    }

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var isValidInput: Bool {
        guard !effectiveExerciseName.isEmpty,
              let _ = Double(currentMax),
              let _ = Double(targetMax),
              let weeks = Int(totalWeeks), weeks > 0,
              let sets = Int(setsPerWorkout), sets > 0,
              let reps = Int(repsPerSet), reps > 0,
              let sessions = Int(sessionsPerWeek), sessions > 0
        else { return false }
        return true
    }

    private var calculatedStartingWeight: Double {
        guard let current = Double(currentMax) else { return 0 }
        let useMetric = globalSettings.first?.useMetric ?? false
        return (current * 0.85).roundedToNearestFive(useMetric: useMetric)
    }

    private var calculatedWeeklyIncrease: Double {
        guard let current = Double(currentMax),
              let target = Double(targetMax),
              let weeks = Int(totalWeeks), weeks > 0
        else { return 0 }
        let useMetric = globalSettings.first?.useMetric ?? false
        let totalIncrease = target - current
        let rawIncrease = totalIncrease / Double(weeks)
        return rawIncrease.roundedToNearestFive(useMetric: useMetric)
    }

    private var calculatedTotalSessions: Int {
        guard let weeks = Int(totalWeeks), let sessions = Int(sessionsPerWeek) else { return 0 }
        return weeks * sessions
    }

    private func findOrCreateExercise() -> Exercise {
        if let existing = allExercises.first(where: {
            $0.name.caseInsensitiveCompare(effectiveExerciseName) == .orderedSame
        }) {
            return existing
        }
        let newExercise = Exercise(name: effectiveExerciseName, coreType: selectedPreset.coreType)
        context.insert(newExercise)
        return newExercise
    }

    private func createWorkout() {
        guard let currentMaxValue = Double(currentMax),
              let targetMaxValue = Double(targetMax),
              let weeksValue = Int(totalWeeks),
              let setsValue = Int(setsPerWorkout),
              let repsValue = Int(repsPerSet),
              let sessionsValue = Int(sessionsPerWeek)
        else {
            showError(message: "Please fill in all fields with valid values")
            return
        }

        if targetMaxValue <= currentMaxValue {
            showError(message: "Target max must be higher than current max")
            return
        }

        let exercise = findOrCreateExercise()
        let normalizedStartDate = Calendar.current.startOfDay(for: Date())

        let workout = Workout(
            name: effectiveExerciseName,
            templateType: .custom,
            totalWeeks: weeksValue,
            startDate: normalizedStartDate
        )
        context.insert(workout)

        let day = WorkoutDay(name: effectiveExerciseName, dayNumber: 1)
        day.workout = workout
        workout.days.append(day)
        context.insert(day)

        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            orderIndex: 0,
            progressionStyle: selectedStyle,
            startingWeight: calculatedStartingWeight,
            targetSets: setsValue,
            targetReps: repsValue
        )
        workoutExercise.day = day
        day.exercises.append(workoutExercise)
        context.insert(workoutExercise)

        generateSessions(
            for: workoutExercise,
            weeks: weeksValue,
            sessionsPerWeek: sessionsValue,
            sets: setsValue,
            reps: repsValue,
            startDate: normalizedStartDate
        )

        do {
            try context.save()
            onComplete()
        } catch {
            showError(message: "Failed to save workout: \(error.localizedDescription)")
        }
    }

    private func generateSessions(
        for workoutExercise: WorkoutExercise,
        weeks: Int,
        sessionsPerWeek: Int,
        sets: Int,
        reps: Int,
        startDate: Date
    ) {
        let startingWeight = calculatedStartingWeight
        let weeklyIncrease = calculatedWeeklyIncrease
        let calendar = Calendar.current
        var sessionNumber = 1

        for week in 1...weeks {
            let weekWeight = calculateWeekWeight(
                week: week,
                startingWeight: startingWeight,
                weeklyIncrease: weeklyIncrease,
                style: selectedStyle
            )

            for day in 1...sessionsPerWeek {
                let daysBetweenSessions = sessionsPerWeek > 1 ? (7 / sessionsPerWeek) : 7
                let daysFromStart = (week - 1) * 7 + (day - 1) * daysBetweenSessions
                let sessionDate = calendar.date(byAdding: .day, value: daysFromStart, to: startDate) ?? startDate

                let session = ExerciseSession(
                    date: sessionDate,
                    weekNumber: week,
                    sessionNumber: sessionNumber,
                    plannedWeight: weekWeight,
                    plannedSets: sets,
                    plannedReps: reps
                )
                session.workoutExercise = workoutExercise
                workoutExercise.sessions.append(session)
                context.insert(session)

                for setNumber in 1...sets {
                    let workoutSet = WorkoutSet(
                        setNumber: setNumber,
                        targetReps: reps,
                        targetWeight: weekWeight
                    )
                    session.sets.append(workoutSet)
                    context.insert(workoutSet)
                }

                sessionNumber += 1
            }
        }
    }

    private func calculateWeekWeight(
        week: Int,
        startingWeight: Double,
        weeklyIncrease: Double,
        style: ProgressionStyle
    ) -> Double {
        let useMetric = globalSettings.first?.useMetric ?? false
        var calculatedWeight: Double

        switch style {
        case .linear:
            calculatedWeight = startingWeight + (weeklyIncrease * Double(week - 1))
        case .periodization:
            let cycleWeek = (week - 1) % 3
            let baseCycle = (week - 1) / 3
            let cycleStartWeight = startingWeight + (weeklyIncrease * 3 * Double(baseCycle))
            switch cycleWeek {
            case 0: calculatedWeight = cycleStartWeight * 0.9
            case 1: calculatedWeight = cycleStartWeight * 0.95
            case 2: calculatedWeight = cycleStartWeight
            default: calculatedWeight = cycleStartWeight
            }
        }

        return calculatedWeight.roundedToNearestFive(useMetric: useMetric)
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    CreateSingleWorkoutView()
}
