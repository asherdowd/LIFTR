import SwiftUI
import SwiftData

// Recent workout rows. They were on Home; Home no longer lists recent workouts, so the Strength
// and Cardio screens (WorkoutsView) show them through RecentWorkoutsSection.

/// "Recent" list under the Strength or Cardio screen: finished workouts, newest first.
struct RecentWorkoutsSection: View {
    let isCardio: Bool

    @Query(sort: \Workout.startDate) private var allWorkouts: [Workout]
    @Query(sort: \Progression.startDate) private var allProgressions: [Progression]
    @Query(sort: \CardioProgression.startDate) private var allCardioProgressions: [CardioProgression]
    @Query private var globalSettings: [GlobalProgressionSettings]

    private var useMetric: Bool { globalSettings.first?.useMetric ?? false }

    /// Strength: new Workouts mixed with legacy sessions. Cardio: cardio exercises of new Workouts.
    private var entries: [RecentStrengthEntry] {
        var legacy: [WorkoutSession] = []
        if !isCardio {
            for progression in allProgressions where progression.status == .active {
                legacy.append(contentsOf: progression.sessions)
            }
        }
        return WorkoutSummaryService.recentEntries(
            workouts: allWorkouts,
            legacySessions: legacy,
            limit: 5,
            cardio: isCardio,
            useMetric: useMetric
        )
    }

    /// Completed sessions of legacy cardio progressions, newest first.
    private var legacyCardioSessions: [CardioSession] {
        if !isCardio { return [] }
        var completed: [CardioSession] = []
        for progression in allCardioProgressions where progression.status == .active {
            for session in progression.sessions where session.completed {
                completed.append(session)
            }
        }
        completed.sort { ($0.completedDate ?? $0.date) > ($1.completedDate ?? $1.date) }
        return Array(completed.prefix(5))
    }

    var body: some View {
        let items: [RecentStrengthEntry] = entries
        let legacyCardio: [CardioSession] = legacyCardioSessions

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Recent")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            if items.isEmpty && legacyCardio.isEmpty {
                Text("No recent workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(items) { entry in
                    RecentStrengthSessionRow(entry: entry)
                }
                ForEach(legacyCardio, id: \.id) { session in
                    RecentCardioSessionRow(session: session)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct RecentStrengthSessionRow: View {
    let entry: RecentStrengthEntry
    @State private var showDetail = false

    var body: some View {
        if let session = entry.session {
            Button(action: { showDetail = true }) { rowContent(showChevron: true) }
                .buttonStyle(.plain)
                .sheet(isPresented: $showDetail) {
                    RecentSessionDetailSheet(session: session)
                }
        } else {
            rowContent(showChevron: false)
        }
    }

    private func rowContent(showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text(entry.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let percentage = entry.percentage {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(Int(percentage))% complete")
                            .font(.caption)
                            .foregroundColor(performanceColor(percentage))
                    }
                }
            }

            Spacer()

            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func performanceColor(_ percentage: Double) -> Color {
        if percentage >= 90 { return .green }
        else if percentage >= 75 { return .orange }
        else { return .red }
    }
}

/// View-only detail for a finished session opened from Home Recent. Sheet with its own
/// NavigationStack. Program sessions also link to the day screen for the whole day.
struct RecentSessionDetailSheet: View {
    let session: ExerciseSession
    @Environment(\.dismiss) private var dismiss

    private var day: WorkoutDay? { session.workoutExercise?.day }
    private var workout: Workout? { day?.workout }
    private var isProgramSession: Bool {
        guard let exercise = session.workoutExercise else { return false }
        return !exercise.isFreeform && !exercise.isCardio
    }

    var body: some View {
        NavigationStack {
            EditSessionView(session: session, readOnly: true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { dismiss() }
                    }
                    if isProgramSession, let day, let workout {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink("Whole day") {
                                WorkoutDayView(workout: workout, day: day, week: session.weekNumber)
                            }
                        }
                    }
                }
        }
    }
}

struct RecentCardioSessionRow: View {
    let session: CardioSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.progression?.name ?? "Unknown Cardio")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    if let distance = session.actualDistance {
                        Text(String(format: "%.1f mi", distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let duration = session.duration {
                        if session.actualDistance != nil {
                            Text("•")
                                .foregroundColor(.secondary)
                        }
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let date = session.completedDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
