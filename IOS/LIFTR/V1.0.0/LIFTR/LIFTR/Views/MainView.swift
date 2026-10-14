import SwiftUI
import SwiftData

// MARK: - Main View

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [User]
    @Query(sort: \Progression.startDate) private var allProgressions: [Progression]
    @Query(sort: \CardioProgression.startDate) private var allCardioProgressions: [CardioProgression]
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query(sort: \Workout.startDate) private var allWorkouts: [Workout]

    /// Called by the empty-state "Start a Workout" button. ContentView uses it to switch tabs.
    var onStartWorkout: (() -> Void)? = nil

    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }

    var activeProgressions: [Progression] {
        allProgressions.filter { $0.status == .active }
    }

    var activeCardioProgressions: [CardioProgression] {
        allCardioProgressions.filter { $0.status == .active }
    }


    /// New Workout sessions (any status) and legacy sessions mixed, newest first.
    var recentStrengthEntries: [RecentStrengthEntry] {
        WorkoutSummaryService.recentEntries(
            workouts: allWorkouts,
            legacySessions: activeProgressions.flatMap { $0.sessions },
            limit: 5
        )
    }

    var upcomingWorkoutDays: [UpcomingWorkoutDay] {
        WorkoutSummaryService.upcomingDays(
            in: allWorkouts,
            withinDays: currentSettings.upcomingWorkoutsDays
        )
    }

    var recentCardioSessions: [CardioSession] {
        let allSessions = activeCardioProgressions.flatMap { $0.sessions }
        return allSessions
            .filter { $0.completed }
            .sorted { $0.completedDate ?? $0.date > $1.completedDate ?? $1.date }
            .prefix(5)
            .map { $0 }
    }

    var upcomingStrengthSessions: [WorkoutSession] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: currentSettings.upcomingWorkoutsDays, to: now) ?? now

        let allSessions = activeProgressions.flatMap { $0.sessions }
        return allSessions
            .filter { !$0.completed && $0.date >= now && $0.date <= futureDate }
            .sorted { $0.date < $1.date }
    }

    var upcomingCardioSessions: [CardioSession] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: currentSettings.upcomingWorkoutsDays, to: now) ?? now

        let allSessions = activeCardioProgressions.flatMap { $0.sessions }
        return allSessions
            .filter { !$0.completed && $0.date >= now && $0.date <= futureDate }
            .sorted { $0.date < $1.date }
    }

    

    // PR tracking - find heaviest lifts from completed sessions
    func getMaxWeight(for exerciseName: String) -> Double {
        let matchingProgressions = activeProgressions.filter {
            $0.exerciseName.lowercased().contains(exerciseName.lowercased())
        }

        guard !matchingProgressions.isEmpty else { return 0 }

        let completedSessions = matchingProgressions
            .flatMap { $0.sessions }
            .filter { $0.completed }

        // Only count sets where actual weight was logged
        let maxWeight = completedSessions.compactMap { session -> Double? in
            let actualWeights = session.sets.compactMap { $0.actualWeight }
            return actualWeights.max()
        }.max()

        return maxWeight ?? 0
    }

    /// PR for a core lift: the larger of the legacy Progression number and the new Workout number.
    func prWeight(name: String, coreType: ExerciseCoreType) -> Double {
        max(getMaxWeight(for: name),
            WorkoutSummaryService.maxWeight(for: coreType, in: allWorkouts))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(users.first?.firstName ?? "Guest")!")
                        .font(.largeTitle)
                        .bold()

                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // MARK: PR Totals Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Current PR Totals")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    VStack(spacing: 0) {
                        PRRow(exercise: "Deadlift", weight: prWeight(name: "Deadlift", coreType: .deadlift))
                        Divider()
                        PRRow(exercise: "Squat", weight: prWeight(name: "Squat", coreType: .squat))
                        Divider()
                        PRRow(exercise: "Bench", weight: prWeight(name: "Bench", coreType: .benchPress))
                        Divider()
                        PRRow(exercise: "Overhead", weight: prWeight(name: "Overhead", coreType: .overheadPress))
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // MARK: Upcoming Workouts Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.green)
                        Text("Upcoming Workouts")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)

                    // Strength subsection
                    if !upcomingStrengthSessions.isEmpty || !upcomingWorkoutDays.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Strength")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            ForEach(upcomingWorkoutDays) { item in
                                UpcomingWorkoutDayRow(item: item)
                            }

                            ForEach(upcomingStrengthSessions, id: \.id) { session in
                                UpcomingStrengthSessionRow(session: session)
                            }
                        }
                    }

  
                    // Cardio subsection
                    if !upcomingCardioSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("Cardio")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, (upcomingStrengthSessions.isEmpty && upcomingWorkoutDays.isEmpty) ? 0 : 8)

                            ForEach(upcomingCardioSessions, id: \.id) { session in
                                UpcomingCardioSessionRow(session: session)
                            }
                        }
                    }

                    // Empty state
                    if upcomingStrengthSessions.isEmpty && upcomingWorkoutDays.isEmpty && upcomingCardioSessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No upcoming workouts scheduled")
                                .foregroundColor(.secondary)

                            Button(action: { onStartWorkout?() }) {
                                Text("Start a Workout")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                .padding(.vertical)

                Divider()
                    .padding(.horizontal)

                // MARK: Recent Workouts Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Recent Workouts")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)

                    // Strength subsection
                    if !recentStrengthEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Strength")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            ForEach(recentStrengthEntries) { entry in
                                RecentStrengthSessionRow(entry: entry)
                            }
                        }
                    }

                    // Cardio subsection
                    if !recentCardioSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("Cardio")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            ForEach(recentCardioSessions, id: \.id) { session in
                                RecentCardioSessionRow(session: session)
                            }
                        }
                    }

                    // Empty state
                    if recentStrengthEntries.isEmpty && recentCardioSessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No recent workouts")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                .padding(.vertical)

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Home")
    }
}

// MARK: - PR Row

struct PRRow: View {
    let exercise: String
    let weight: Double

    var body: some View {
        HStack {
            Text(exercise)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            if weight > 0 {
                Text("\(Int(weight)) lbs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            } else {
                Text("0 lbs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Recent Session Rows

struct RecentStrengthSessionRow: View {
    let entry: RecentStrengthEntry

    var body: some View {
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

// MARK: - Upcoming Session Rows

struct UpcomingStrengthSessionRow: View {
    let session: WorkoutSession
    @State private var showWorkoutSession = false

    var body: some View {
        Button(action: { showWorkoutSession = true }) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("W\(session.weekNumber)")
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("D\(session.dayNumber)")
                        .font(.caption2)
                }
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.progression?.exerciseName ?? "Unknown Exercise")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text("\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showWorkoutSession) {
            if let progression = session.progression {
                NavigationView {
                    WorkoutSessionView(session: session, progression: progression)
                }
            }
        }
    }
}

/// Upcoming day of a new-model Workout. Opens the day screen in a sheet with its own
/// NavigationStack (same pattern as WorkoutCardView).
struct UpcomingWorkoutDayRow: View {
    let item: UpcomingWorkoutDay
    @State private var showDay = false

    var body: some View {
        Button(action: { showDay = true }) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("W\(item.week)")
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("D\(item.day.dayNumber)")
                        .font(.caption2)
                }
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.workout.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text("\(item.day.name) · \(item.pendingCount) exercise\(item.pendingCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDay) {
            NavigationStack {
                WorkoutDayView(workout: item.workout, day: item.day, week: item.week)
            }
        }
    }
}

struct UpcomingCardioSessionRow: View {
    let session: CardioSession
    @State private var showCardioSession = false

    var body: some View {
        Button(action: { showCardioSession = true }) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("W\(session.weekNumber)")
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("D\(session.dayNumber)")
                        .font(.caption2)
                }
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.progression?.name ?? "Unknown Cardio")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let distance = session.plannedDistance {
                        Text(String(format: "%.1f mi planned", distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let activityType = session.activityType {
                        Text(activityType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCardioSession) {
            if let progression = session.progression {
                NavigationView {
                    CardioSessionView(session: session, progression: progression)
                }
            }
        }
    }
}



// MARK: - Preview

#Preview {
    NavigationView {
        MainView()
    }
}
