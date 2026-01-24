import SwiftUI
import SwiftData

struct PerformanceSummaryView: View {
    let session: WorkoutSession
    
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
