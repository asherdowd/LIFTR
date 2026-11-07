import SwiftUI
import SwiftData

// MARK: - History Tab
// All finished sessions of the new Workout model (strength and cardio), newest first,
// grouped by month. Rows are the same as Home > Recent: a tap opens the read-only session
// detail. Editing past sessions stays on the Workouts tab.

struct HistoryTab: View {
    @Query private var allWorkouts: [Workout]
    @Query private var globalSettings: [GlobalProgressionSettings]

    @State private var kind: HistoryKind = .all

    private var months: [HistoryMonth] {
        WorkoutSummaryService.historyMonths(
            workouts: allWorkouts,
            kind: kind,
            useMetric: globalSettings.first?.useMetric == true
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Show", selection: $kind) {
                ForEach(HistoryKind.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if months.isEmpty {
                Text("No finished workouts yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(months) { month in
                        Text(month.monthStart.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(month.entries) { entry in
                            RecentStrengthSessionRow(entry: entry)
                        }
                    }
                }
            }
        }
    }
}
