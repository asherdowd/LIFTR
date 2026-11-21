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


    var upcomingWorkoutDays: [UpcomingWorkoutDay] {
        WorkoutSummaryService.upcomingDays(
            in: allWorkouts,
            withinDays: currentSettings.upcomingWorkoutsDays
        )
    }

    /// Strength days: in progress, overdue, and the next scheduled one.
    var upcomingStrengthDays: [UpcomingWorkoutDay] {
        var strength: [UpcomingWorkoutDay] = []
        for item in upcomingWorkoutDays where !item.isCardio {
            strength.append(item)
        }
        return WorkoutSummaryService.limitScheduled(strength, limit: WorkoutSummaryService.scheduledPerCategory)
    }

    /// Cardio days from the new model: in progress, overdue, and the next scheduled one.
    var upcomingCardioDays: [UpcomingWorkoutDay] {
        var cardio: [UpcomingWorkoutDay] = []
        for item in upcomingWorkoutDays where item.isCardio {
            cardio.append(item)
        }
        return WorkoutSummaryService.limitScheduled(cardio, limit: WorkoutSummaryService.scheduledPerCategory)
    }

    /// How many scheduled slots a category has left after its new-model scheduled days
    /// (legacy sessions share the same limit).
    private func scheduledSlotsLeft(_ days: [UpcomingWorkoutDay]) -> Int {
        var used: Int = 0
        for item in days where item.status == .scheduled {
            used += 1
        }
        let left: Int = WorkoutSummaryService.scheduledPerCategory - used
        return left > 0 ? left : 0
    }

    /// Legacy strength sessions, limited together with the new-model scheduled days.
    var shownLegacyStrengthSessions: [WorkoutSession] {
        return Array(upcomingStrengthSessions.prefix(scheduledSlotsLeft(upcomingStrengthDays)))
    }

    /// Legacy cardio sessions, limited together with the new-model scheduled days.
    var shownLegacyCardioSessions: [CardioSession] {
        return Array(upcomingCardioSessions.prefix(scheduledSlotsLeft(upcomingCardioDays)))
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
                    if !upcomingStrengthDays.isEmpty || !shownLegacyStrengthSessions.isEmpty {
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

                            ForEach(upcomingStrengthDays) { item in
                                UpcomingWorkoutDayRow(item: item)
                            }

                            ForEach(shownLegacyStrengthSessions, id: \.id) { session in
                                UpcomingStrengthSessionRow(session: session)
                            }
                        }
                    }

                    // Cardio subsection
                    if !upcomingCardioDays.isEmpty || !shownLegacyCardioSessions.isEmpty {
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
                            .padding(.top, (upcomingStrengthDays.isEmpty && shownLegacyStrengthSessions.isEmpty) ? 0 : 8)

                            ForEach(upcomingCardioDays) { item in
                                UpcomingWorkoutDayRow(item: item)
                            }

                            ForEach(shownLegacyCardioSessions, id: \.id) { session in
                                UpcomingCardioSessionRow(session: session)
                            }
                        }
                    }

                    // Empty state (the Start Workout button below is always shown)
                    if upcomingStrengthDays.isEmpty && shownLegacyStrengthSessions.isEmpty
                        && upcomingCardioDays.isEmpty && shownLegacyCardioSessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No upcoming workouts scheduled")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                .padding(.vertical)

                // MARK: Start Workout button (opens the Workouts tab)
                Button(action: { onStartWorkout?() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Start Workout")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal)

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

                        Text(dateText)
                            .font(.caption2)
                            .fontWeight(item.status == .scheduled ? .regular : .semibold)
                            .foregroundColor(dateColor)
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

    private var dateText: String {
        let date = item.date.formatted(date: .abbreviated, time: .omitted)
        switch item.status {
        case .inProgress: return "In progress"
        case .overdue: return "Overdue · \(date)"
        case .scheduled: return date
        }
    }

    private var dateColor: Color {
        switch item.status {
        case .inProgress: return .orange
        case .overdue: return .gray
        case .scheduled: return .secondary
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
