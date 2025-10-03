import SwiftUI
import SwiftData

struct CreateCardioProgressionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    
    @State private var progressionName: String = ""
    @State private var selectedType: CardioType = .running
    @State private var totalWeeks: String = "12"
    @State private var sessionsPerWeek: String = "3"
    
    // Running fields
    @State private var targetDistance: String = ""
    @State private var startingWeeklyDistance: String = ""
    
    // Calisthenics fields
    @State private var exerciseName: String = ""
    @State private var targetReps: String = ""
    @State private var startingReps: String = ""
    @State private var setsPerWorkout: String = "3"
    
    // CrossFit fields
    @State private var workoutType: CrossFitWorkoutType = .forTime
    @State private var workoutDescription: String = ""
    
    // Free Cardio fields
    @State private var activityType: String = ""
    @State private var targetDuration: String = "" // minutes
    
    // Swimming fields
    @State private var targetSwimDistance: String = ""
    
    // Unit preference
    @State private var useMetric: Bool = false
    
    // Validation
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info
                Section {
                    TextField("Progression Name", text: $progressionName)
                        .autocapitalization(.words)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(CardioType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                } header: {
                    Text("Basic Information")
                }
                
                // Type-specific fields
                switch selectedType {
                case .running:
                    RunningFields(
                        targetDistance: $targetDistance,
                        startingWeeklyDistance: $startingWeeklyDistance,
                        useMetric: $useMetric
                    )
                    
                case .calisthenics:
                    CalisthenicsFields(
                        exerciseName: $exerciseName,
                        targetReps: $targetReps,
                        startingReps: $startingReps,
                        setsPerWorkout: $setsPerWorkout
                    )
                    
                case .crossfit:
                    CrossFitFields(
                        workoutType: $workoutType,
                        workoutDescription: $workoutDescription
                    )
                    
                case .swimming:
                    SwimmingFields(
                        targetDistance: $targetSwimDistance,
                        useMetric: $useMetric
                    )
                    
                case .freeCardio:
                    FreeCardioFields(
                        activityType: $activityType,
                        targetDuration: $targetDuration
                    )
                }
                
                // Duration
                Section {
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
                } header: {
                    Text("Program Duration")
                }
                
                // Preview
                if isValidInput {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(previewText)
                                .font(.subheadline)
                        }
                    } header: {
                        Text("Preview")
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
            .navigationTitle("New Cardio Progression")
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
    
    private var isValidInput: Bool {
        guard !progressionName.trimmingCharacters(in: .whitespaces).isEmpty,
              let weeks = Int(totalWeeks), weeks > 0,
              let sessions = Int(sessionsPerWeek), sessions > 0
        else { return false }
        
        switch selectedType {
        case .running:
            return Double(targetDistance) != nil && Double(startingWeeklyDistance) != nil
        case .calisthenics:
            return !exerciseName.isEmpty && Int(targetReps) != nil && Int(startingReps) != nil
        case .crossfit:
            return !workoutDescription.isEmpty
        case .swimming:
            return Double(targetSwimDistance) != nil
        case .freeCardio:
            return !activityType.isEmpty
        }
    }
    
    private var previewText: String {
        let weeks = Int(totalWeeks) ?? 0
        let sessions = Int(sessionsPerWeek) ?? 0
        let totalSessions = weeks * sessions
        
        switch selectedType {
        case .running:
            let target = Double(targetDistance) ?? 0
            let unit = useMetric ? "km" : "miles"
            return "Build up to \(String(format: "%.1f", target)) \(unit) over \(weeks) weeks with \(totalSessions) total runs"
        case .calisthenics:
            let target = Int(targetReps) ?? 0
            return "Progress to \(target) \(exerciseName) over \(weeks) weeks"
        case .crossfit:
            return "\(workoutType.rawValue) workouts over \(weeks) weeks"
        case .swimming:
            let target = Double(targetSwimDistance) ?? 0
            let unit = useMetric ? "meters" : "yards"
            return "Build to \(String(format: "%.1f", target)) \(unit) swimming over \(weeks) weeks"
        case .freeCardio:
            return "\(activityType) sessions over \(weeks) weeks"
        }
    }
    
    private func createProgression() {
        guard let weeksValue = Int(totalWeeks),
              let sessionsValue = Int(sessionsPerWeek)
        else {
            showErrorMessage(message: "Please fill in all fields with valid values")
            return
        }
        
        let progression = CardioProgression(
            name: progressionName.trimmingCharacters(in: .whitespaces),
            cardioType: selectedType,
            totalWeeks: weeksValue,
            targetDistance: selectedType == .running ? Double(targetDistance) : nil,
            startingWeeklyDistance: selectedType == .running ? Double(startingWeeklyDistance) : nil,
            exerciseName: selectedType == .calisthenics ? exerciseName : nil,
            targetReps: selectedType == .calisthenics ? Int(targetReps) : nil,
            startingReps: selectedType == .calisthenics ? Int(startingReps) : nil,
            workoutType: selectedType == .crossfit ? workoutType : nil,
            workoutDescription: selectedType == .crossfit ? workoutDescription : nil,
            useMetric: useMetric
        )
        
        context.insert(progression)
        
        // Generate sessions
        generateSessions(for: progression, weeks: weeksValue, sessionsPerWeek: sessionsValue)
        
        do {
            try context.save()
            dismiss()
        } catch {
            showErrorMessage(message: "Failed to save progression: \(error.localizedDescription)")
        }
    }
    
    private func generateSessions(for progression: CardioProgression, weeks: Int, sessionsPerWeek: Int) {
        let useMetric = progression.useMetric
        let calendar = Calendar.current
        let startDate = progression.startDate
        
        for week in 1...weeks {
            for day in 1...sessionsPerWeek {
                // Calculate the date for this session
                // Week 1, Day 1 = startDate
                // Week 1, Day 2 = startDate + 2 days (spacing sessions throughout the week)
                let daysFromStart = (week - 1) * 7 + (day - 1) * (7 / sessionsPerWeek)
                let sessionDate = calendar.date(byAdding: .day, value: daysFromStart, to: startDate) ?? startDate
                
                let session = CardioSession(
                    date: sessionDate,
                    weekNumber: week,
                    dayNumber: day
                )
                
                // Set type-specific planned values
                switch selectedType {
                case .running:
                    let weeklyDistance = calculateRunningDistance(week: week, totalWeeks: weeks, useMetric: useMetric)
                    session.plannedDistance = weeklyDistance / Double(sessionsPerWeek)
                    
                case .calisthenics:
                    let weekReps = calculateCalisthenicsReps(week: week, totalWeeks: weeks)
                    session.plannedReps = weekReps
                    session.plannedSets = Int(setsPerWorkout) ?? 3
                    
                case .crossfit:
                    // WOD details stored in progression, sessions track completion
                    break
                    
                case .swimming:
                    let weekDistance = calculateSwimmingDistance(week: week, totalWeeks: weeks, useMetric: useMetric)
                    session.plannedDistance = weekDistance / Double(sessionsPerWeek)
                    
                case .freeCardio:
                    session.activityType = activityType
                    if let duration = Double(targetDuration) {
                        session.duration = duration * 60 // convert to seconds
                    }
                }
                
                session.progression = progression
                context.insert(session)
            }
        }
    }
    
    private func calculateRunningDistance(week: Int, totalWeeks: Int, useMetric: Bool) -> Double {
        guard let starting = Double(startingWeeklyDistance),
              let target = Double(targetDistance)
        else { return 0 }
        
        // Linear progression from starting weekly mileage to target distance prep
        let weeklyIncrease = (target - starting) / Double(totalWeeks)
        return (starting + (weeklyIncrease * Double(week - 1))).roundedToNearestFive(useMetric: useMetric)
    }
    
    private func calculateCalisthenicsReps(week: Int, totalWeeks: Int) -> Int {
        guard let starting = Int(startingReps),
              let target = Int(targetReps)
        else { return 0 }
        
        let totalIncrease = target - starting
        let weeklyIncrease = Double(totalIncrease) / Double(totalWeeks)
        return starting + Int(weeklyIncrease * Double(week - 1))
    }
    
    private func calculateSwimmingDistance(week: Int, totalWeeks: Int, useMetric: Bool) -> Double {
        guard let target = Double(targetSwimDistance)
        else { return 0 }
        
        // Progressive build up to target distance
        let percentage = Double(week) / Double(totalWeeks)
        return target * percentage
    }
    
    private func showErrorMessage(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Type-Specific Field Views

struct RunningFields: View {
    @Binding var targetDistance: String
    @Binding var startingWeeklyDistance: String
    @Binding var useMetric: Bool
    
    var body: some View {
        Section {
            Toggle("Use Kilometers", isOn: $useMetric)
            
            HStack {
                Text("Target Distance")
                Spacer()
                TextField("", text: $targetDistance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text(useMetric ? "km" : "miles")
            }
            
            HStack {
                Text("Starting Weekly Distance")
                Spacer()
                TextField("", text: $startingWeeklyDistance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text(useMetric ? "km" : "miles")
            }
        } header: {
            Text("Running Goals")
        } footer: {
            Text("Target distance is your race goal (e.g., 26.2 for marathon). Starting weekly is your current mileage.")
        }
    }
}

struct CalisthenicsFields: View {
    @Binding var exerciseName: String
    @Binding var targetReps: String
    @Binding var startingReps: String
    @Binding var setsPerWorkout: String
    
    var body: some View {
        Section {
            TextField("Exercise Name (e.g., Pull-ups)", text: $exerciseName)
                .autocapitalization(.words)
            
            HStack {
                Text("Current Max Reps")
                Spacer()
                TextField("", text: $startingReps)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("reps")
            }
            
            HStack {
                Text("Target Max Reps")
                Spacer()
                TextField("", text: $targetReps)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("reps")
            }
            
            HStack {
                Text("Sets per Session")
                Spacer()
                TextField("", text: $setsPerWorkout)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("sets")
            }
        } header: {
            Text("Calisthenics Details")
        }
    }
}

struct CrossFitFields: View {
    @Binding var workoutType: CrossFitWorkoutType
    @Binding var workoutDescription: String
    
    var body: some View {
        Section {
            Picker("Workout Type", selection: $workoutType) {
                ForEach(CrossFitWorkoutType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("WOD Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $workoutDescription)
                    .frame(height: 100)
            }
        } header: {
            Text("CrossFit WOD")
        } footer: {
            Text(workoutType.description)
        }
    }
}

struct SwimmingFields: View {
    @Binding var targetDistance: String
    @Binding var useMetric: Bool
    
    var body: some View {
        Section {
            Toggle("Use Meters", isOn: $useMetric)
            
            HStack {
                Text("Target Distance")
                Spacer()
                TextField("", text: $targetDistance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text(useMetric ? "meters" : "yards")
            }
        } header: {
            Text("Swimming Goals")
        }
    }
}

struct FreeCardioFields: View {
    @Binding var activityType: String
    @Binding var targetDuration: String
    
    var body: some View {
        Section {
            TextField("Activity Type (e.g., Elliptical, Bike)", text: $activityType)
                .autocapitalization(.words)
            
            HStack {
                Text("Target Duration")
                Spacer()
                TextField("", text: $targetDuration)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("minutes")
            }
        } header: {
            Text("Free Cardio Details")
        }
    }
}
