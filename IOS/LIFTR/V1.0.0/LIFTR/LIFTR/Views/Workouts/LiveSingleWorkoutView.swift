import SwiftUI
import SwiftData

struct LiveSingleWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]

    @Bindable var session: ExerciseSession
    @Bindable var workoutExercise: WorkoutExercise
    var onComplete: () -> Void = {}

    @State private var selectedSet: WorkoutSet?
    @State private var showCalculator = false
    @State private var showComplete = false
    @StateObject private var rest = RestTimerController()
    @StateObject private var activity = SessionActivityController()

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var completedSetsCount: Int {
        session.sets.filter { $0.completed }.count
    }

    private var needsStart: Bool { LiveSessionClock.needsStart(session) }

    private var progressText: String {
        return "\(completedSetsCount) sets"
    }

    private func beginActivity() {
        activity.begin(
            workoutType: RestTimerAttributes.strengthType,
            name: workoutExercise.exercise.name,
            progress: progressText,
            session: session
        )
    }

    private func startSession() {
        LiveSessionClock.start(session)
        try? context.save()
        beginActivity()
    }

    private var lastCompletedWeight: Double? {
        session.sets
            .filter { $0.completed }
            .sorted { $0.setNumber < $1.setNumber }
            .last?
            .actualWeight
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 8) {
                    Text(workoutExercise.exercise.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(Int(session.plannedWeight)) \(unitLabel)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Calculator button
                Button(action: { showCalculator = true }) {
                    HStack {
                        Image(systemName: "function")
                        Text("Plate Calculator")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Sets list
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sets")
                            .font(.headline)
                        Spacer()
                        Text("\(completedSetsCount) completed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    if session.sets.isEmpty {
                        Text("Tap 'Add Set' to log your first set.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                            SetRowView(
                                set: set,
                                trackRPE: globalSettings.first?.trackRPE ?? false,
                                onEdit: { selectedSet = set }
                            )
                        }
                    }
                }

                // Add Set button
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(needsStart)

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if LiveSessionClock.isRunningSession(session) {
                LiveSessionHeader(session: session, rest: rest)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if needsStart {
                LiveSessionStartBar(action: startSession)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            rest.attach(activity)
            // Back on the screen: the session is no longer "away" (see onDisappear).
            if session.paused {
                session.paused = false
                try? context.save()
            }
            // Returning to a session that is still running: bring the Lock Screen activity back.
            if LiveSessionClock.isRunningSession(session) { beginActivity() }
        }
        .onChange(of: session.pausedAt) { _, _ in
            activity.sync(session: session)
        }
        .onDisappear {
            // The rest timer and the Lock Screen activity belong to this screen.
            rest.stop()
            activity.end()
            // Left a started session without finishing it: mark it in progress so the
            // Resume card and the day screen show it. The clock keeps running.
            if LiveSessionClock.isRunningSession(session) {
                session.paused = true
                try? context.save()
            }
        }
        .stalePrompt(for: session) { seconds in
            LiveSessionClock.setEnd(session, durationSeconds: seconds)
            completeWorkout()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if session.startTime != nil {
                    Button("Complete") {
                        completeWorkout()
                    }
                    .disabled(completedSetsCount == 0)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $selectedSet) { set in
            LogSetView(
                set: set,
                trackRPE: globalSettings.first?.trackRPE ?? false,
                onSaved: { savedSet in
                    activity.setProgress(progressText)
                    rest.startAfterSet(
                        settings: globalSettings.first ?? GlobalProgressionSettings(),
                        exerciseName: workoutExercise.exercise.name,
                        setInfo: "Set \(savedSet.setNumber)"
                    )
                }
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
                lines: WorkoutSummaryService.completionLines(for: session, useMetric: globalSettings.first?.useMetric == true),
                onDone: { showComplete = false }
            )
        }
    }

    private func addSet() {
        let setNumber = session.sets.count + 1
        let prefillWeight = lastCompletedWeight ?? session.plannedWeight

        let workoutSet = WorkoutSet(
            setNumber: setNumber,
            targetReps: 5,
            targetWeight: prefillWeight
        )
        workoutSet.exerciseSession = session
        session.sets.append(workoutSet)
        context.insert(workoutSet)

        try? context.save()

        selectedSet = workoutSet
    }

    private func completeWorkout() {
        session.completed = true
        session.completedDate = Date()
        session.plannedSets = completedSetsCount
        DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
        try? context.save()
        rest.stop()
        activity.end()
        showComplete = true
    }
}
