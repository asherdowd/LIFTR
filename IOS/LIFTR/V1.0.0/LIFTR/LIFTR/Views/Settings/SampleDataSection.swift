import SwiftUI
import SwiftData

#if DEBUG
// MARK: - Developer section (Debug builds only)
// Load or remove the sample history (see SampleDataService). Not compiled into Release builds.

struct SampleDataSection: View {
    @Environment(\.modelContext) private var context
    @State private var message: String?

    var body: some View {
        Section(
            header: Text("Developer"),
            footer: Text(message ?? "Debug builds only. Loads about 22 weeks of sample strength and cardio history. Removing deletes only the sample workouts.")
        ) {
            Button("Load sample history") { load() }
            Button("Remove sample data", role: .destructive) { remove() }
        }
    }

    private func load() {
        do {
            let created = try SampleDataService.load(into: context)
            message = created == 0 ? "Sample data is already loaded." : "Loaded \(created) sample workouts."
        } catch {
            message = "Could not load sample data: \(error.localizedDescription)"
        }
    }

    private func remove() {
        do {
            let removed = try SampleDataService.remove(from: context)
            message = removed == 0 ? "No sample data to remove." : "Removed \(removed) sample workouts."
        } catch {
            message = "Could not remove sample data: \(error.localizedDescription)"
        }
    }
}
#endif
