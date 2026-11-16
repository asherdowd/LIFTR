import SwiftUI
import SwiftData

struct LogSingleCardioView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    var onComplete: () -> Void = {}

    @State private var selectedType: CardioType = .running
    @State private var duration: String = ""        // minutes
    @State private var distance: String = ""
    @State private var activityType: String = ""    // free cardio only
    @State private var notes: String = ""

    @State private var showComplete = false
    @State private var completionTitle = ""
    @State private var completionLines: [String] = []

    @State private var showError = false
    @State private var errorMessage = ""

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "km" : "miles"
    }

    private var isValidInput: Bool {
        switch selectedType {
        case .running, .swimming:
            return Double(distance) != nil && Double(duration) != nil
        case .calisthenics:
            return Double(duration) != nil
        case .crossfit:
            return Double(duration) != nil
        case .freeCardio:
            return !activityType.trimmingCharacters(in: .whitespaces).isEmpty && Double(duration) != nil
        }
    }

    var body: some View {
        NavigationView {
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

                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", text: $duration)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("min")
                    }

                    if selectedType == .running || selectedType == .swimming {
                        HStack {
                            Text("Distance")
                            Spacer()
                            TextField("0", text: $distance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(selectedType == .swimming
                                 ? (globalSettings.first?.useMetric == true ? "meters" : "yards")
                                 : unitLabel)
                        }
                    }

                    if selectedType == .freeCardio {
                        TextField("Activity (e.g. Elliptical, Bike)", text: $activityType)
                            .autocapitalization(.words)
                    }
                } header: {
                    Text("Details")
                }

                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                } header: {
                    Text("Notes")
                }

                Section {
                    Button(action: logWorkout) {
                        HStack {
                            Spacer()
                            Text("Log Workout")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("Log Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showComplete, onDismiss: { onComplete() }) {
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
    }

    private func logWorkout() {
        guard let durationMinutes = Double(duration) else {
            showErrorMessage("Please enter a valid duration.")
            return
        }

        let useMetric = globalSettings.first?.useMetric ?? false

        do {
            let workout = try CardioWorkoutService.logManualActivity(
                type: selectedType,
                customName: activityType,
                durationMinutes: durationMinutes,
                distanceEntered: Double(distance),
                notes: notes,
                useMetric: useMetric,
                into: context
            )
            completionTitle = workout.name
            if let session = workout.days.first?.exercises.first?.sessions.first {
                completionLines = WorkoutSummaryService.completionLines(for: session, useMetric: useMetric)
            }
            showComplete = true
        } catch {
            showErrorMessage("Failed to save workout: \(error.localizedDescription)")
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    NavigationView {
        LogSingleCardioView()
    }
}
