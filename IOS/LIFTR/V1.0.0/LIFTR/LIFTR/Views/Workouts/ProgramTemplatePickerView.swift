import SwiftUI

struct ProgramTemplatePickerView: View {
    var onComplete: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose a Program")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)

            NavigationLink(destination: StartingStrengthSetupView(onComplete: onComplete)) {
                ProgramTemplateRow(
                    title: "Starting Strength",
                    subtitle: "Mark Rippetoe's beginner linear progression",
                    detail: "Squat, Bench, Deadlift, OHP · 3 days/week · A/B alternating",
                    color: .blue,
                    icon: "figure.strengthtraining.traditional"
                )
            }
            .padding(.horizontal)

            NavigationLink(destination: MadcowSetupView(onComplete: onComplete)) {
                ProgramTemplateRow(
                    title: "Madcow 5×5",
                    subtitle: "Bill Starr's intermediate 5×5 program",
                    detail: "Squat, Bench, Row, OHP, Deadlift · 3 days/week · ramping sets",
                    color: .purple,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Template Row

private struct ProgramTemplateRow: View {
    let title: String
    let subtitle: String
    let detail: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        ProgramTemplatePickerView()
    }
}
