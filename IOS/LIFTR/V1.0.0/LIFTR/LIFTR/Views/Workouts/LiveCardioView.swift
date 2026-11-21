import SwiftUI
import SwiftData
import MapKit

/// Live cardio screen: the pinned session clock with a single Pause, a Stop bar, and, after Stop,
/// a form for duration (filled from the clock, editable), distance, and notes. Reuses the
/// shared live-session pieces (clock, header, Lock Screen activity) and the Workout Complete sheet.
/// Running and Free Cardio also record GPS distance, elevation and a route (LiveRouteRecorder),
/// shown on a live map; the numbers fill the Stop form and stay editable.
struct LiveCardioView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]

    @Bindable var session: ExerciseSession
    @Bindable var workoutExercise: WorkoutExercise
    var onComplete: () -> Void = {}

    @StateObject private var activity = SessionActivityController()
    @ObservedObject private var recorder = LiveRouteRecorder.shared

    @State private var mapPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    @State private var isFinishing = false
    @State private var stoppedSeconds: TimeInterval = 0
    @State private var stoppedDurationText = ""
    @State private var durationText = ""
    @State private var stoppedDistanceText = ""
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

    /// Running and Free Cardio record GPS distance, elevation and a route.
    private var tracksRoute: Bool { cardioType == .running || cardioType == .freeCardio }
    private var hasDistanceField: Bool { cardioType == .running || cardioType == .swimming || cardioType == .freeCardio }
    private var requiresDistance: Bool { cardioType == .running || cardioType == .swimming }

    /// The recorder is recording THIS session.
    private var isRecordingThis: Bool { recorder.sessionID == session.id }

    private var distanceUnit: String {
        if cardioType == .swimming { return useMetric ? "meters" : "yards" }
        return useMetric ? "km" : "miles"
    }

    private var isValidInput: Bool {
        guard Double(durationText) != nil else { return false }
        if requiresDistance { return Double(distanceText) != nil }
        if hasDistanceField && !distanceText.isEmpty { return Double(distanceText) != nil }
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
            if isRunning {
                beginActivity()
                if tracksRoute {
                    recorder.begin(sessionID: session.id)
                    recorder.setPaused(LiveSessionClock.isPaused(session))
                }
            }
        }
        .onChange(of: session.pausedAt) { _, newValue in
            activity.sync(session: session)
            // Recording follows the clock: nothing is recorded while paused.
            if tracksRoute && isRecordingThis {
                recorder.setPaused(newValue != nil)
            }
        }
        .onDisappear {
            // The Lock Screen activity belongs to this screen. Route recording does not: it keeps
            // going with the clock (see LiveRouteRecorder). A started, unfinished session is
            // marked in progress so the Cardio tab and Home show it.
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

    @ViewBuilder
    private var runningBody: some View {
        if tracksRoute {
            trackedBody
        } else {
            plainBody
        }
    }

    private var plainBody: some View {
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

    private var trackedBody: some View {
        VStack(spacing: 0) {
            Map(position: $mapPosition) {
                if recorder.coordinates.count >= 2 && isRecordingThis {
                    MapPolyline(coordinates: recorder.coordinates)
                        .stroke(.blue, lineWidth: 5)
                }
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
            }
            .overlay(alignment: .top) {
                gpsBanner
            }

            statsBar
        }
    }

    @ViewBuilder
    private var gpsBanner: some View {
        if recorder.isDenied {
            bannerText("Location is off for this app. Enter the distance when you stop.")
        } else if recorder.isAuthorized && !recorder.hasFix {
            bannerText("Waiting for GPS...")
        }
    }

    private func bannerText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .cornerRadius(8)
            .padding(.top, 8)
    }

    private var statsBar: some View {
        HStack {
            statBlock(
                title: "Distance",
                value: RouteFormat.distance(isRecordingThis ? recorder.distanceMeters : 0, useMetric: useMetric)
            )
            Spacer()
            if LiveRouteRecorder.hasBarometer {
                statBlock(
                    title: "Climb",
                    value: RouteFormat.elevation(isRecordingThis ? recorder.elevationGain : 0, useMetric: useMetric)
                )
            }
        }
        .padding()
        .background(.bar)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
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
                Text(finishFooter)
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

    private var finishFooter: String {
        var text = "Stopped at \(LiveSessionClock.format(stoppedSeconds)). Change the duration if the clock was off."
        if !stoppedDistanceText.isEmpty {
            text += " Distance is from GPS: change it if it looks wrong."
        }
        return text
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

        // GPS distance, when it was recorded, fills the distance field (still editable).
        stoppedDistanceText = ""
        distanceText = ""
        if tracksRoute && isRecordingThis && recorder.distanceMeters > 0 {
            let gpsText = RouteFormat.distanceNumber(recorder.distanceMeters, useMetric: useMetric)
            stoppedDistanceText = gpsText
            distanceText = gpsText
        }
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

        var snapshot: RouteSnapshot? = nil
        if tracksRoute && isRecordingThis {
            snapshot = recorder.snapshot()
        }

        var meters: Double? = nil
        if hasDistanceField, let entered = Double(distanceText) {
            if let snap = snapshot, distanceText == stoppedDistanceText, snap.route.distance > 0 {
                // Untouched GPS distance keeps the exact meters.
                meters = snap.route.distance
            } else {
                meters = CardioWorkoutService.meters(fromEntered: entered, type: cardioType, useMetric: useMetric)
            }
        }

        var gain: Double? = nil
        var loss: Double? = nil
        var routeData: Data? = nil
        if let snap = snapshot {
            if snap.hasElevation {
                gain = snap.elevation.gain
                loss = snap.elevation.loss
            }
            routeData = RouteCodec.encode(snap.route.thinned(maxPoints: RouteCodec.maxStoredPoints))
        }

        do {
            try CardioWorkoutService.finishLiveWorkout(
                session: session,
                workoutExercise: workoutExercise,
                durationSeconds: seconds,
                distanceMeters: meters,
                elevationGain: gain,
                elevationLoss: loss,
                routeData: routeData,
                notes: notes,
                into: context
            )
            if snapshot != nil {
                _ = recorder.finish()
            }
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
