import SwiftUI
import SwiftData

struct CreateProgressionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var exerciseSettings: [ExerciseProgressionSettings]
    
    // Form state
    @State private var exerciseName: String = ""
    @State private var selectedTemplate: TemplateType = .startingStrength
    @State private var selectedStyle: ProgressionStyle = .linear
    @State private var currentMax: String = ""
    @State private var targetMax: String = ""
    @State private var totalWeeks: String = "12"
    @State private var setsPerWorkout: String = "3"
    @State private var repsPerSet: String = "5"
    @State private var sessionsPerWeek: String = "1"
    
    // Validation
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Exercise Information
                Section(header: Text("Exercise Information")) {
                    TextField("Exercise Name (e.g., Squat, Deadlift)", text: $exerciseName)
                        .autocapitalization(.words)
                }
                
                // Template Selection
                Section(header: Text("Template"),
                        footer: Text(selectedTemplate.description)) {
                    Picker("Template Type", selection: $selectedTemplate) {
                        ForEach(TemplateType.allCases, id: \.self) { template in
                            Text(template.rawValue).tag(template)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Progression Style
                Section(header: Text("Progression Style"),
                        footer: Text(selectedStyle.description)) {
                    Picker("Style", selection: $selectedStyle) {
                        ForEach(ProgressionStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Weight Parameters
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
                
                // Program Duration
                Section(header: Text("Program Duration")) {
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
                
                // Workout Structure
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
                
                // Preview
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
                
                // Create Button
                Section {
                    Button(action: createProgression) {
                        HStack {
                            Spacer()
                            Text("Create Progression")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("New Progression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }
    
    private var isValidInput: Bool {
        guard !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty,
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
        // Start at 85% of current max for most programs, rounded
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
        
        // Round weekly increase to nearest 5 (or 2.5 for metric)
        return rawIncrease.roundedToNearestFive(useMetric: useMetric)
    }
    
    private var calculatedTotalSessions: Int {
        guard let weeks = Int(totalWeeks),
              let sessions = Int(sessionsPerWeek)
        else { return 0 }
        
        return weeks * sessions
    }
    
    // MARK: - Create Progression
    
    private func createProgression() {
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
        
        // Validate target is higher than current
        if targetMaxValue <= currentMaxValue {
            showError(message: "Target max must be higher than current max")
            return
        }
        
        // Create the progression
        let normalizedStartDate = Calendar.current.startOfDay(for: Date())

        let progression = Progression(
            exerciseName: exerciseName.trimmingCharacters(in: .whitespaces),
            templateType: selectedTemplate,
            progressionStyle: selectedStyle,
            currentMax: currentMaxValue,
            targetMax: targetMaxValue,
            startingWeight: calculatedStartingWeight,
            totalWeeks: weeksValue,
            startDate: normalizedStartDate  // ADD THIS
        )
        
        context.insert(progression)
        
        // Generate workout sessions based on template and style
        generateWorkoutSessions(
            for: progression,
            weeks: weeksValue,
            sessionsPerWeek: sessionsValue,
            sets: setsValue,
            reps: repsValue
        )
        
        // Create exercise-specific settings if they don't exist
        if !exerciseSettings.contains(where: { $0.exerciseName == progression.exerciseName }) {
            let exerciseSetting = ExerciseProgressionSettings(exerciseName: progression.exerciseName)
            context.insert(exerciseSetting)
        }
        
        // Save context
        do {
            try context.save()
            dismiss()
        } catch {
            showError(message: "Failed to save progression: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generate Workout Sessions
    
    private func generateWorkoutSessions(
        for progression: Progression,
        weeks: Int,
        sessionsPerWeek: Int,
        sets: Int,
        reps: Int
    ) {
        let startingWeight = calculatedStartingWeight
        let weeklyIncrease = calculatedWeeklyIncrease
        let calendar = Calendar.current
        let startDate = progression.startDate
        
        for week in 1...weeks {
            // Calculate weight for this week based on progression style
            let weekWeight = calculateWeekWeight(
                week: week,
                startingWeight: startingWeight,
                weeklyIncrease: weeklyIncrease,
                style: selectedStyle,
                totalWeeks: weeks
            )
            
            // Create sessions for this week
            for day in 1...sessionsPerWeek {
                // Calculate session spacing based on sessions per week
                // 1/week = every 7 days, 2/week = every 3-4 days, 3/week = every 2 days, etc.
                let daysBetweenSessions = sessionsPerWeek > 1 ? (7 / sessionsPerWeek) : 7
                let daysFromStart = (week - 1) * 7 + (day - 1) * daysBetweenSessions
                let sessionDate = calendar.date(byAdding: .day, value: daysFromStart, to: startDate) ?? startDate
                
                let session = WorkoutSession(
                    date: sessionDate,
                    weekNumber: week,
                    dayNumber: day,
                    plannedWeight: weekWeight,
                    plannedSets: sets,
                    plannedReps: reps
                )
                
                session.progression = progression
                context.insert(session)
                progression.sessions.append(session)
                
                // Create sets for this session
                for setNumber in 1...sets {
                    let workoutSet = WorkoutSet(
                        setNumber: setNumber,
                        targetReps: reps,
                        targetWeight: weekWeight
                    )
                    workoutSet.session = session
                    session.sets.append(workoutSet)
                    context.insert(workoutSet)
                }
            }
        }
    }
    // MARK: - Calculate Week Weight
    
    private func calculateWeekWeight(
        week: Int,
        startingWeight: Double,
        weeklyIncrease: Double,
        style: ProgressionStyle,
        totalWeeks: Int
    ) -> Double {
        let useMetric = globalSettings.first?.useMetric ?? false
        var calculatedWeight: Double
        
        switch style {
        case .linear:
            // Simple linear progression
            calculatedWeight = startingWeight + (weeklyIncrease * Double(week - 1))
            
        case .periodization:
            // Wave loading: light, medium, heavy weeks
            let cycleWeek = (week - 1) % 3
            let baseCycle = (week - 1) / 3
            let cycleStartWeight = startingWeight + (weeklyIncrease * 3 * Double(baseCycle))
            
            switch cycleWeek {
            case 0: // Light week (90% of cycle weight)
                calculatedWeight = cycleStartWeight * 0.9
            case 1: // Medium week (95% of cycle weight)
                calculatedWeight = cycleStartWeight * 0.95
            case 2: // Heavy week (100% of cycle weight)
                calculatedWeight = cycleStartWeight
            default:
                calculatedWeight = cycleStartWeight
            }
            
        case .percentage:
            // Percentage-based progression (similar to linear for now)
            calculatedWeight = startingWeight + (weeklyIncrease * Double(week - 1))
            
        case .rpe:
            // RPE-based (similar to linear for planning, actual will be tracked during workout)
            calculatedWeight = startingWeight + (weeklyIncrease * Double(week - 1))
        }
        
        // Round to nearest 5 lbs (or 2.5 kg)
        return calculatedWeight.roundedToNearestFive(useMetric: useMetric)
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
