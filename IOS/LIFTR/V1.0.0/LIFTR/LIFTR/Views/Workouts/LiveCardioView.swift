import SwiftUI
import SwiftData

/// Live cardio screen: the pinned session clock with a single Pause, a Stop bar, and, after Stop,
/// a form for duration (filled from the clock, editable), distance, and notes. Reuses the
/// shared live-session pieces (clock, header, Lock Screen activity) and the Workout Complete sheet.
struct LiveCardioView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]

    @Bindable var session: ExerciseSession
    @Bindable var workoutExercise: WorkoutExercise
    var onComplete: () -> Void = {}

    @StateObject private var activity = SessionActivityController()

    @State private var isFinishing = false
    @State private var stoppedSeconds: TimeInterval = 0
    @State private var stoppedDurationText = ""
    @State private var durationText = ""
    @State private var distanceText = ""
    @State private var notes = ""

    @State private var showComplete = false
    @State private var completionTitle = ""
    @State private var completionLines: [String] = []

    @State private var showError = false
    @State private var errorMessage = ""

    private var useMetric: Bool { globalSettings.first?.useMetric ?? false }
    private var activityName: String { workoutExercise.exercise.name }
    private var cardioType: CardioType { CardioWorkoutService.cardioType(forExerciseName: activityName) }
    private var isRunning: Bool { LiveSessionClock.isRunningSession(session) }
    private var hasDistanceField: Bool { cardioType == .running || cardioType == .swimming }

    private var distanceUnit: String {
        if cardioType == .swimming { return useMetric ? "meters" : "yards" }
        return useMetric ? "km" : "miles"
    }

    private var isValidInput: Bool {
        guard Double(durationText) != nil else { return false }
        if hasDistanceField { return Double(distanceText) != nil }
        return true
    }

    var body: some View {
        Group {
            if isFinishing {
                finishForm
            } else {
                runningBody
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if isRunning && !isFinishing {
                LiveSessionHeader(session: session)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isRunning && !isFinishing {
                LiveSessionStopBar(action: stop)
            }
        }
        .navigationTitle("Cardio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Back on the screen: the session is no longer "away" (see onDisappear).
            if session.paused {
                session.paused = false
                try? context.save()
            }
            if isRunning { beginActivity() }
        }
        .onChange(of: session.pausedAt) { _, _ in
            activity.sync(session: session)
        }
        .onDisappear {
            // The Lock Screen activity belongs to this screen. A started, unfinished session is
            // marked in progress so the Cardio tab and Home show it. The clock keeps running.
            activity.end()
            if isRunning {
                session.paused = true
                try? context.save()
            }
        }
        .stalePrompt(for: session) { seconds in
            LiveSessionClock.setEnd(session, durationSeconds: seconds)
            prepareFinish(seconds: LiveSessionClock.elapsed(session))
        }
        .sheet(isPresented: $showComplete, onDismiss: {
            onComplete()
            dismiss()
        }) {
            WorkoutCompleteView(
                title: completionTitle,
                lines: completionLines,
                onDone: { showComplete = false }
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Running

    private var runningBody: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: cardioType.icon)
                .font(.system(size: 64))
                .foregroundColor(.blue)
            Text(activityName)
                .font(.title)
                .fontWeight(.bold)
            Text("Tap Stop when you are done.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stop and save

    private var finishForm: some View {
        Form {
            Section {
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("0", text: $durationText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("min")
                }

                if hasDistanceField {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(distanceUnit)
                    }
                }
            } header: {
                Text(activityName)
            } footer: {
                Text("Stopped at \(LiveSessionClock.format(stoppedSeconds)). Change the duration if the clock was off.")
            }

            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3)
            } header: {
                Text("Notes")
            }

            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        Text("Save Workout")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValidInput)

                Button(action: resume) {
                    HStack {
                        Spacer()
                        Text("Resume")
                        Spacer()
                    }
                }
            }
        }
    }

    private func stop() {
        LiveSessionClock.pause(session)
        try? context.save()
        prepareFinish(seconds: LiveSessionClock.elapsed(session))
    }

    private func prepareFinish(seconds: TimeInterval) {
        stoppedSeconds = seconds
        let minutesText = String(format: "%.1f", seconds / 60)
        stoppedDurationText = minutesText
        durationText = minutesText
        isFinishing = true
    }

    private func resume() {
        // Back to the running screen. An end time set by the "Still working out?" prompt is cleared.
        session.endTime = nil
        LiveSessionClock.resume(session)
        try? context.save()
        isFinishing = false
    }

    private func save() {
        guard let minutes = Double(durationText) else {
            showErrorMessage("Please enter a valid duration.")
            return
        }
        // Untouched duration keeps the exact clock seconds; an edited one uses the typed minutes.
        let seconds: TimeInterval = (durationText == stoppedDurationText) ? stoppedSeconds : minutes * 60

        var meters: Double? = nil
        if hasDistanceField, let entered = Double(distanceText) {
            meters = CardioWorkoutService.meters(fromEntered: entered, type: cardioType, useMetric: useMetric)
        }

        do {
            try CardioWorkoutService.finishLiveWorkout(
                session: session,
                workoutExercise: workoutExercise,
                durationSeconds: seconds,
                distanceMeters: meters,
                notes: notes,
                into: context
            )
            activity.end()
            completionTitle = activityName
            completionLines = WorkoutSummaryService.completionLines(for: session, useMetric: useMetric)
            showComplete = true
        } catch {
            showErrorMessage("Failed to save workout: \(error.localizedDescription)")
        }
    }

    private func beginActivity() {
        activity.begin(
            workoutType: RestTimerAttributes.cardioType,
            name: activityName,
            progress: "",
            session: session
        )
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
