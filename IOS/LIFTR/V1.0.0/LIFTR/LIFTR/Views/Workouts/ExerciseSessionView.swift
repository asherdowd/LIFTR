import SwiftUI
import SwiftData

struct ExerciseSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]

    @Bindable var session: ExerciseSession
    @Bindable var workoutExercise: WorkoutExercise
    var onComplete: () -> Void = {}

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
                VStack(spacing: 8) {
                    Text(workoutExercise.exercise.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Week \(session.weekNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let templateType = workoutExercise.day?.workout?.templateType {
                        Text(templateType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()

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

                if completedSetsCount > 0 {
                    ExercisePerformanceSummaryView(session: session)
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Active Workout")
        .onAppear {
            // V5: opening a session starts its clock (first time only).
            if session.startTime == nil && !session.completed {
                session.startTime = Date()
            }
        }
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
                exerciseName: workoutExercise.exercise.name,
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
                    DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
                    DeloadAdjustmentService.applyAdjustment(adjustment, session: session, workoutExercise: workoutExercise, settings: currentSettings)
                    try? context.save()
                    onComplete()
                    dismiss()
                }
                Button("Keep Original Plan") {
                    session.completed = true
                    session.completedDate = Date()
                    session.paused = false
                    DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
                    try? context.save()
                    onComplete()
                    dismiss()
                }
                Button("Manual Adjustment") {
                    session.completed = true
                    session.completedDate = Date()
                    session.paused = false
                    DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
                    try? context.save()
                    onComplete()
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
        let performance = DeloadAdjustmentService.analyzePerformance(session: session, settings: currentSettings)

        if currentSettings.adjustmentMode != .never && performance != .continueAsPlanned {
            adjustmentRecommendation = performance
            showAdjustmentPrompt = true
        } else {
            session.completed = true
            session.completedDate = Date()
            session.paused = false

            DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)

            if currentSettings.adjustmentMode == .autoAdjust && performance != .continueAsPlanned {
                DeloadAdjustmentService.applyAdjustment(performance, session: session, workoutExercise: workoutExercise, settings: currentSettings)
            }
            try? context.save()
            onComplete()
            dismiss()
        }
    }

    private func pauseWorkout() {
        session.paused = true
        try? context.save()
        dismiss()
    }
}
