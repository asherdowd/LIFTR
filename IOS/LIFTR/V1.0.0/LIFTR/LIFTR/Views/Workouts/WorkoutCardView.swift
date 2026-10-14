import SwiftUI
import SwiftData

// MARK: - Workout Card (new Workout model)
// Shown in the Strength section of WorkoutsView, next to the legacy ProgressionCard.

struct WorkoutCardView: View {
    @Environment(\.modelContext) private var context
    let workout: Workout

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if !isDeleting {
                if workout.totalWeeks > 1 {
                    Divider()
                    progressSection
                }
                nextDaySection
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .confirmationDialog(
            "Delete Workout",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(isDeleting ? "" : workout.name)'? This will remove all workout history and cannot be undone.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Label(workout.templateType.rawValue, systemImage: "book.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(workout.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(6)

            Button(action: { showDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Week \(workout.currentWeek) of \(workout.totalWeeks)")
                .font(.subheadline)
                .fontWeight(.semibold)

            ProgressView(value: Double(workout.currentWeek), total: Double(workout.totalWeeks))
                .tint(.blue)
        }
    }

    @ViewBuilder
    private var nextDaySection: some View {
        let week = workout.currentWeek
        if let day = workout.nextDay {
            let paused = workout.hasPausedSession(forWeek: week)
            let sessions = day.sessions(forWeek: week)
            let doneCount = sessions.filter { $0.isDone }.count

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(paused ? "Paused Workout" : "Next Workout")
                        .font(.caption)
                        .foregroundColor(paused ? .orange : .secondary)

                    Text(daySummary(day: day, week: week))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if doneCount > 0 {
                        Text("\(doneCount) of \(sessions.count) done")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                NavigationLink(destination: WorkoutDayView(workout: workout, day: day, week: week)) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text(paused || doneCount > 0 ? "Resume" : "Start")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(paused ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Helpers

    private func daySummary(day: WorkoutDay, week: Int) -> String {
        workout.totalWeeks > 1 ? "\(day.name) · Week \(week)" : day.name
    }

    private var statusColor: Color {
        switch workout.status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }

    private func deleteWorkout() {
        // Mark as deleting so the card stops reading children while SwiftUI updates.
        isDeleting = true

        withAnimation {
            context.delete(workout)
        }

        // Delay save to allow SwiftUI to update (same approach as ProgressionCard).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? context.save()
        }
    }
}
