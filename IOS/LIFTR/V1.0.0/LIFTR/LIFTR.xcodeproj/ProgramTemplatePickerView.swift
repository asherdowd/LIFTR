import SwiftUI

struct ProgramTemplatePickerView: View {
    var onComplete: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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

                NavigationLink(destination: CreateSingleWorkoutView(onComplete: onComplete)) {
                    ProgramTemplateRow(
                        title: "Simple Progression",
                        subtitle: "Single exercise, linear weight increase",
                        detail: "Pick one lift · set your starting and target weight · done",
                        color: .orange,
                        icon: "arrow.up.right"
                    )
                }
                .padding(.horizontal)

                NavigationLink(destination: CustomProgramSetupView(onComplete: onComplete)) {
                    ProgramTemplateRow(
                        title: "Custom Program",
                        subtitle: "Build your own multi-day program",
                        detail: "Any exercises · any days · your increments",
                        color: .green,
                        icon: "slider.horizontal.3"
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Template Row

struct ProgramTemplateRow: View {
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
