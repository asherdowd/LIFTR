import SwiftUI
import SwiftData

/// Start Workout > Single Workout > Cardio. Pick the activity and tap Start: the workout is
/// created with its clock running and the live screen opens (LiveCardioView). Distance, duration
/// and notes are entered when the activity is stopped.
struct LogSingleCardioView: View {
    @Environment(\.modelContext) private var context
    var onComplete: () -> Void = {}

    @State private var selectedType: CardioType = .running
    @State private var activityType: String = ""    // free cardio only

    @State private var navigateToLive = false
    @State private var liveStart: CardioWorkoutService.LiveStart?

    @State private var showError = false
    @State private var errorMessage = ""

    private var canStart: Bool {
        if selectedType == .freeCardio {
            return !activityType.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $selectedType) {
                    ForEach(CardioType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
            } header: {
                Text("Activity Type")
            }

            if selectedType == .freeCardio {
                Section {
                    TextField("Activity (e.g. Elliptical, Bike)", text: $activityType)
                        .autocapitalization(.words)
                } header: {
                    Text("Activity")
                }
            }

            Section {
                Button(action: startWorkout) {
                    HStack {
                        Spacer()
                        Text("Start")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!canStart)
            } footer: {
                Text("The clock starts when you tap Start. You enter distance and notes when you stop.")
            }
        }
        .navigationTitle("Cardio")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToLive) {
            if let live = liveStart {
                LiveCardioView(
                    session: live.session,
                    workoutExercise: live.workoutExercise,
                    onComplete: onComplete
                )
            }
        }
        .onChange(of: navigateToLive) { _, isShowing in
            // Leaving the live screen (finished, or back arrow while still running) closes the
            // Start Workout sheet, so a second workout cannot be started by accident. A running
            // workout stays on the Cardio tab as In Progress.
            if !isShowing {
                liveStart = nil
                onComplete()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func startWorkout() {
        do {
            liveStart = try CardioWorkoutService.startLiveWorkout(
                type: selectedType,
                customName: activityType,
                into: context
            )
            navigateToLive = true
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        LogSingleCardioView()
    }
}
