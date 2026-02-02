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
                HStack(spacing: 12) {
                    Button("Pause") {
                        pauseWorkout()
                    }
                    .disabled(completedSetsCount == 0)
                    
                    Button("Complete") {
                        completeWorkout()
                    }
                    .disabled(completedSetsCount == 0)
                }
            }
        }
        
        .sheet(item: $selectedSet) { set in
            LogSetView(
                set: set,
                trackRPE: currentSettings.trackRPE,
                exerciseName: progression.exerciseName,
                totalSets: session.plannedSets
            )
        }
        .sheet(isPresented: $showCalculator) {
            CalculatorViewWrapper(targetWeight: session.plannedWeight)
        }
        .alert("Workout Performance", isPresented: $showAdjustmentPrompt) {
            if let adjustment = adjustmentRecommendation {
                Button("Accept Recommendation") {
                    session.completed = true
                    session.completedDate = Date()
                    session.paused = false
                    checkAndAdvanceWeek()
                    applyAdjustment(adjustment)
                }
                Button("Keep Original Plan") {
                    session.completed = true
                    session.completedDate = Date()
                    session.paused = false
                    checkAndAdvanceWeek()  // ADDED
                    try? context.save()
                    dismiss()
                }
                Button("Manual Adjustment") {
                    session.completed = true
                    session.completedDate = Date()
                    session.paused = false
                    checkAndAdvanceWeek()  // ADDED
                    try? context.save()
                    dismiss()
                }
            }
        } message: {
            if let adjustment = adjustmentRecommendation {
                Text(adjustment.message)
            }
        }
    }
    
    private var completedSetsCount: Int {
        session.sets.filter { $0.completed }.count
    }
    
    private func completeWorkout() {
        // DON'T modify session yet - just analyze and show alert
        let performance = analyzePerformance()
        
        // Check if adjustment is needed based on settings
        if currentSettings.adjustmentMode != .never && performance != .continueAsPlanned {
            adjustmentRecommendation = performance
            showAdjustmentPrompt = true
        } else {
            // Only NOW mark as completed and save
            session.completed = true
            session.completedDate = Date()
            session.paused = false
            
            // ADDED: Check if we should advance the week
            checkAndAdvanceWeek()
            
            // Auto-adjust if enabled
            if currentSettings.adjustmentMode == .autoAdjust && performance != .continueAsPlanned {
                applyAdjustment(performance)
            }
            try? context.save()
            dismiss()
        }
    }
    
    private func checkAndAdvanceWeek() {
        // Count completed sessions in the current week
        let completedThisWeek = progression.sessions.filter {
            $0.weekNumber == session.weekNumber && $0.completed
        }.count
        
        // Get total sessions per week from the progression
        let sessionsThisWeek = progression.sessions.filter {
            $0.weekNumber == session.weekNumber
        }.count
        
        print("🔍 PROGRESSION Week advancement check:")
        print("   Progression: \(progression.exerciseName)")
        print("   progression.currentWeek BEFORE: \(progression.currentWeek)")
        print("   session.weekNumber: \(session.weekNumber)")
        print("   Completed this week: \(completedThisWeek)/\(sessionsThisWeek)")
        
        // If all sessions in the week are complete, advance to next week
        if completedThisWeek >= sessionsThisWeek && progression.currentWeek < progression.totalWeeks {
            print("   ✅ Advancing week: \(progression.currentWeek) → \(progression.currentWeek + 1)")
            progression.currentWeek += 1
            print("   progression.currentWeek AFTER: \(progression.currentWeek)")
        } else {
            print("   ❌ NOT advancing")
            print("      All sessions complete? \(completedThisWeek >= sessionsThisWeek)")
            print("      Can advance? currentWeek (\(progression.currentWeek)) < totalWeeks (\(progression.totalWeeks)): \(progression.currentWeek < progression.totalWeeks)")
        }
    }
    private func pauseWorkout() {
        // Simple pause - just mark as paused and save
        session.paused = true
        try? context.save()
        dismiss()
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
        // NOTE: Session already marked complete by caller
        
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
