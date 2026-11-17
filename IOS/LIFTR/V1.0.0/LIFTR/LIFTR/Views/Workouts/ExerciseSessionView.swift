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
    @State private var showComplete = false

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

                    // Before Start the sets are a preview: visible but not loggable.
                    ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                        SetRowView(
                            set: set,
                            trackRPE: currentSettings.trackRPE,
                            onEdit: { selectedSet = set }
                        )
                    }
                    .opacity(needsStart ? 0.5 : 1)
                    .allowsHitTesting(!needsStart)
                }

                if completedSetsCount > 0 {
                    ExercisePerformanceSummaryView(session: session)
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if isRunning {
                LiveSessionHeader(session: session)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if needsStart {
                LiveSessionStartBar(action: startSession)
            }
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Back on the screen: the session is no longer "away" (see onDisappear).
            if session.paused {
                session.paused = false
                try? context.save()
            }
        }
        .onDisappear {
            // Left a started session without finishing it: mark it in progress so the
            // Resume card and the day screen show it. The clock keeps running.
            if isRunning {
                session.paused = true
                try? context.save()
            }
        }
        .stalePrompt(for: session) { seconds in
            LiveSessionClock.setEnd(session, durationSeconds: seconds)
            completeWorkout()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if session.startTime != nil {
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
        .sheet(isPresented: $showComplete, onDismiss: {
            onComplete()
            dismiss()
        }) {
            WorkoutCompleteView(
                title: workoutExercise.exercise.name,
                lines: WorkoutSummaryService.completionLines(for: session, useMetric: currentSettings.useMetric),
                onDone: { showComplete = false }
            )
        }
        .alert("Workout Performance", isPresented: $showAdjustmentPrompt) {
            if let adjustment = adjustmentRecommendation {
                Button("Accept Recommendation") {
                    finishSession(applying: adjustment)
                }
                Button("Keep Original Plan") {
                    finishSession(applying: nil)
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

    private var needsStart: Bool { LiveSessionClock.needsStart(session) }
    private var isRunning: Bool { LiveSessionClock.isRunningSession(session) }

    private func startSession() {
        LiveSessionClock.start(session)
        try? context.save()
    }

    private func completeWorkout() {
        let performance = DeloadAdjustmentService.analyzePerformance(session: session, settings: currentSettings)

        if currentSettings.adjustmentMode != .never && performance != .continueAsPlanned {
            adjustmentRecommendation = performance
            showAdjustmentPrompt = true
        } else {
            finishSession(applying: nil)
        }
    }

    /// The single exit for finishing a program session. Marks it complete, advances the week,
    /// optionally applies a progression adjustment, saves, then shows the Workout Complete sheet.
    private func finishSession(applying adjustment: ProgressionAdjustment?) {
        session.completed = true
        session.completedDate = Date()
        session.paused = false

        DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
        if let adjustment = adjustment {
            DeloadAdjustmentService.applyAdjustment(adjustment, session: session, workoutExercise: workoutExercise, settings: currentSettings)
        }
        try? context.save()
        showComplete = true
    }
}
