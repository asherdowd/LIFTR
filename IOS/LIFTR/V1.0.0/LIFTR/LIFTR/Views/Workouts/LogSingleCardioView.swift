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

        let today = Calendar.current.startOfDay(for: Date())
        let useMetric = globalSettings.first?.useMetric ?? false

        // Create a CardioProgression with 1 week / 1 session, already completed
        let name: String
        switch selectedType {
        case .running:   name = "Run"
        case .swimming:  name = "Swim"
        case .calisthenics: name = "Calisthenics"
        case .crossfit:  name = "CrossFit"
        case .freeCardio: name = activityType.trimmingCharacters(in: .whitespaces)
        }

        let progression = CardioProgression(
            name: name,
            cardioType: selectedType,
            totalWeeks: 1,
            startDate: today,
            useMetric: useMetric
        )
        context.insert(progression)

        let session = CardioSession(
            date: today,
            weekNumber: 1,
            dayNumber: 1
        )
        session.duration = durationMinutes * 60
        session.actualDistance = Double(distance)
        if selectedType == .freeCardio {
            session.activityType = activityType.trimmingCharacters(in: .whitespaces)
        }
        session.completed = true
        session.completedDate = Date()
        session.notes = notes.isEmpty ? nil : notes
        session.progression = progression
        progression.sessions.append(session)
        context.insert(session)

        do {
            try context.save()
            onComplete()
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
