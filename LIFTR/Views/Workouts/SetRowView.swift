import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    let trackRPE: Bool
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Set Number
                ZStack {
                    Circle()
                        .fill(set.completed ? Color.green : Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    
                    if set.completed {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    } else {
                        Text("\(set.setNumber)")
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Target Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let actualReps = set.actualReps, let actualWeight = set.actualWeight {
                        HStack(spacing: 4) {
                            Text("\(actualReps) reps @ \(Int(actualWeight)) lbs")
                                .font(.caption)
                            if let rpe = set.rpe, trackRPE {
                                Text("• RPE \(rpe)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .foregroundColor(set.wasSuccessful ? .green : .orange)
                    } else {
                        Text("Target: \(set.targetReps) reps @ \(Int(set.targetWeight)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
