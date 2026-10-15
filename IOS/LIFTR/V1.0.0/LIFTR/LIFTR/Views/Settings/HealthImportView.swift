import SwiftUI
import SwiftData

// MARK: - Apple Health Import (Settings > Integrations > Apple Health)
// Read-only: pulls finished cardio workouts from Apple Health into LIFTR as completed
// quick Workouts. Running it again only adds activities that are not in LIFTR yet.

struct HealthImportView: View {
    @Environment(\.modelContext) private var context

    @State private var days = 30
    @State private var isWorking = false
    @State private var message: String?

    private let dayOptions = [7, 30, 90, 365]

    var body: some View {
        Form {
            Section {
                Text("LIFTR can read runs, walks, hikes, rides and similar workouts from Apple Health, including those written by your Garmin or Apple Watch. LIFTR does not change anything in Health.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Section {
                Picker("Import the last", selection: $days) {
                    ForEach(dayOptions, id: \.self) { value in
                        Text(label(for: value)).tag(value)
                    }
                }

                Button(action: runImport) {
                    HStack {
                        Text("Import from Apple Health")
                        Spacer()
                        if isWorking { ProgressView() }
                    }
                }
                .disabled(isWorking)
            } footer: {
                Text("The first time, iOS asks which data LIFTR may read. Anything already imported is skipped.")
            }

            if let message {
                Section {
                    Text(message)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func label(for value: Int) -> String {
        value == 365 ? "year" : "\(value) days"
    }

    @MainActor
    private func runImport() {
        isWorking = true
        message = nil

        Task {
            do {
                let service = HealthKitService.shared
                try await service.requestAuthorization()

                let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                let activities = try await service.fetchActivities(since: since)

                let created = try HealthImportService.importActivities(activities, into: context)
                try context.save()

                await MainActor.run {
                    if activities.isEmpty {
                        message = "No workouts found. If you expected some, check Settings > Health > Data Access & Devices > LIFTR and allow Workouts, Heart Rate, Distance and Active Energy."
                    } else {
                        let skipped = activities.count - created
                        message = "Imported \(created) new activit\(created == 1 ? "y" : "ies")" + (skipped > 0 ? " (\(skipped) already in LIFTR)." : ".")
                    }
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }
}
