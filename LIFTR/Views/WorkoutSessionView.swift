import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    
    @Bindable var session: WorkoutSession
    @Bindable var progression: Progression
    
    @State private var showCalculator = false
    @State private var showAdjustmentPrompt = false
    @State private var adjustmentRecommendation: ProgressionAdjustment?
    @State private var selectedSet: WorkoutSet?
    
    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 8) {
                        Text(progression.exerciseName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Week \(session.weekNumber), Day \(session.dayNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(progression.templateType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    // Target Info Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Weight")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(session.plannedWeight)) lbs")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Target Volume")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(session.plannedSets) × \(session.plannedReps)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        // Load This Weight Button
                        Button(action: { showCalculator = true }) {
                            HStack {
                                Image(systemName: "function")
                                Text("Load This Weight in Calculator")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Sets Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sets")
                                .font(.headline)
                            Spacer()
                            Text("\(completedSetsCount)/\(session.sets.count) completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                            SetRowView(
                                set: set,
                                trackRPE: currentSettings.trackRPE,
                                onEdit: { selectedSet = set }
                            )
                        }
                    }
                    
                    // Performance Summary (if any sets completed)
                    if completedSetsCount > 0 {
                        PerformanceSummaryView(session: session)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeWorkout()
                    }
                    .disabled(completedSetsCount == 0)
                }
            }
            .sheet(item: $selectedSet) { set in
                LogSetView(set: set, trackRPE: currentSettings.trackRPE)
            }
            .sheet(isPresented: $showCalculator) {
                CalculatorViewWrapper(targetWeight: session.plannedWeight)
            }
            .alert("Workout Performance", isPresented: $showAdjustmentPrompt) {
                if let adjustment = adjustmentRecommendation {
                    Button("Accept Recommendation") {
                        applyAdjustment(adjustment)
                    }
                    Button("Keep Original Plan") {
                        dismiss()
                    }
                    Button("Manual Adjustment") {
                        // TODO: Navigate to edit progression
                        dismiss()
                    }
                }
            } message: {
                if let adjustment = adjustmentRecommendation {
                    Text(adjustment.message)
                }
            }
        }
    }
    
    private var completedSetsCount: Int {
        session.sets.filter { $0.completed }.count
    }
    
    private func completeWorkout() {
        session.completed = true
        session.completedDate = Date()
        
        // Analyze performance
        let performance = analyzePerformance()
        
        // Check if adjustment is needed based on settings
        if currentSettings.adjustmentMode != .never && performance != .continueAsPlanned {
            adjustmentRecommendation = performance
            showAdjustmentPrompt = true
        } else {
            // Auto-adjust if enabled
            if currentSettings.adjustmentMode == .autoAdjust && performance != .continueAsPlanned {
                applyAdjustment(performance)
            }
            try? context.save()
            dismiss()
        }
    }
    
    private func analyzePerformance() -> ProgressionAdjustment {
        let totalPlanned = session.totalPlannedReps
        let totalCompleted = session.totalCompletedReps
        
        guard totalPlanned > 0 else { return .continueAsPlanned }
        
        let percentage = (Double(totalCompleted) / Double(totalPlanned)) * 100
        
        if percentage >= Double(currentSettings.excellentThreshold) {
            return .continueAsPlanned
        } else if percentage >= Double(currentSettings.goodThreshold) {
            return .repeatWeight
        } else if percentage >= Double(currentSettings.adjustmentThreshold) {
            return .reduceBy(percent: currentSettings.reductionPercent)
        } else {
            return .deload(percent: currentSettings.deloadPercent)
        }
    }
    
    private func applyAdjustment(_ adjustment: ProgressionAdjustment) {
        let useMetric = currentSettings.useMetric
        
        switch adjustment {
        case .continueAsPlanned:
            break
            
        case .repeatWeight:
            // Find next week's sessions and set them to same weight (rounded)
            let nextWeekSessions = progression.sessions.filter { $0.weekNumber == session.weekNumber + 1 }
            let roundedWeight = session.plannedWeight.roundedToNearestFive(useMetric: useMetric)
            for nextSession in nextWeekSessions {
                nextSession.plannedWeight = roundedWeight
                for set in nextSession.sets {
                    set.targetWeight = roundedWeight
                }
            }
            
        case .reduceBy(let percent):
            adjustFutureWeights(reductionPercent: percent)
            
        case .deload(let percent):
            insertDeloadWeek(reductionPercent: percent)
        }
        
        try? context.save()
        dismiss()
    }
    
    private func adjustFutureWeights(reductionPercent: Double) {
        let useMetric = currentSettings.useMetric
        let multiplier = 1.0 - (reductionPercent / 100.0)
        
        // Adjust all future sessions
        let futureSessions = progression.sessions.filter { $0.weekNumber > session.weekNumber }
        for futureSession in futureSessions {
            let adjustedWeight = (futureSession.plannedWeight * multiplier).roundedToNearestFive(useMetric: useMetric)
            futureSession.plannedWeight = adjustedWeight
            for set in futureSession.sets {
                set.targetWeight = adjustedWeight
            }
        }
    }
    
    private func insertDeloadWeek(reductionPercent: Double) {
        let useMetric = currentSettings.useMetric
        let deloadWeight = (session.plannedWeight * (1.0 - (reductionPercent / 100.0))).roundedToNearestFive(useMetric: useMetric)
        
        // Set next week as deload
        let nextWeekSessions = progression.sessions.filter { $0.weekNumber == session.weekNumber + 1 }
        for nextSession in nextWeekSessions {
            nextSession.plannedWeight = deloadWeight
            for set in nextSession.sets {
                set.targetWeight = deloadWeight
            }
        }
    }
}

// MARK: - Set Row View

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    let trackRPE: Bool
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Set Number
                ZStack {
                    Circle()
                        .fill(set.completed ? Color.green : Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    
                    if set.completed {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    } else {
                        Text("\(set.setNumber)")
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Target Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let actualReps = set.actualReps, let actualWeight = set.actualWeight {
                        HStack(spacing: 4) {
                            Text("\(actualReps) reps @ \(Int(actualWeight)) lbs")
                                .font(.caption)
                            if let rpe = set.rpe, trackRPE {
                                Text("• RPE \(rpe)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .foregroundColor(set.wasSuccessful ? .green : .orange)
                    } else {
                        Text("Target: \(set.targetReps) reps @ \(Int(set.targetWeight)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// MARK: - Log Set View

struct LogSetView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var set: WorkoutSet
    let trackRPE: Bool
    
    @State private var repsCompleted: String = ""
    @State private var weightUsed: String = ""
    @State private var rpeValue: Double = 7
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Target")) {
                    HStack {
                        Text("Reps")
                        Spacer()
                        Text("\(set.targetReps)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(Int(set.targetWeight)) lbs")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Actual Performance")) {
                    HStack {
                        Text("Reps Completed")
                        Spacer()
                        TextField("", text: $repsCompleted)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Weight Used")
                        Spacer()
                        TextField("", text: $weightUsed)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                }
                
                if trackRPE {
                    Section(header: Text("Rate of Perceived Exertion (RPE)"),
                            footer: Text("1 = Very Easy, 10 = Maximum Effort")) {
                        HStack {
                            Text("RPE: \(Int(rpeValue))")
                                .fontWeight(.semibold)
                            Slider(value: $rpeValue, in: 1...10, step: 1)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Button(action: saveSet) {
                        HStack {
                            Spacer()
                            Text("Save Set")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(repsCompleted.isEmpty || weightUsed.isEmpty)
                }
            }
            .navigationTitle("Log Set \(set.setNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let actualReps = set.actualReps {
                    repsCompleted = String(actualReps)
                }
                if let actualWeight = set.actualWeight {
                    weightUsed = String(format: "%.1f", actualWeight)
                }
                if let rpe = set.rpe {
                    rpeValue = Double(rpe)
                }
                notes = set.notes ?? ""
            }
        }
    }
    
    private func saveSet() {
        guard let reps = Int(repsCompleted),
              let weight = Double(weightUsed) else { return }
        
        set.actualReps = reps
        set.actualWeight = weight
        set.rpe = trackRPE ? Int(rpeValue) : nil
        set.notes = notes.isEmpty ? nil : notes
        set.completed = true
        
        dismiss()
    }
}

// MARK: - Performance Summary View

struct PerformanceSummaryView: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.totalCompletedReps) / \(session.totalPlannedReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(session.performancePercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                }
            }
            
            ProgressView(value: session.performancePercentage, total: 100)
                .tint(performanceColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var performanceColor: Color {
        if session.performancePercentage >= 90 {
            return .green
        } else if session.performancePercentage >= 75 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Calculator Wrapper

struct CalculatorViewWrapper: View {
    let targetWeight: Double
    
    var body: some View {
        CalculatorView(initialWeight: targetWeight)
    }
}

