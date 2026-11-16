import SwiftUI
import SwiftData

struct ExercisePerformanceSummaryView: View {
    @Query private var globalSettings: [GlobalProgressionSettings]
    let session: ExerciseSession

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Summary")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.totalCompletedReps) / \(session.totalPlannedReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(session.performancePercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                }
            }

            if session.plannedWeight > 0 {
                HStack {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(session.completedVolume)) / \(Int(session.plannedVolume)) \(unitLabel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ProgressView(value: session.performancePercentage, total: 100)
                .tint(performanceColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var performanceColor: Color {
        if session.performancePercentage >= 90 {
            return .green
        } else if session.performancePercentage >= 75 {
            return .orange
        } else {
            return .red
        }
    }
}
