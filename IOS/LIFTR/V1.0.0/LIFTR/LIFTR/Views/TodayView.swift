import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var allPlans: [Plan]
    @Query private var allWorkouts: [ScheduledWorkout]
    @Query private var settings: [GlobalWorkoutSettings]
    
    @State private var selectedWorkout: ScheduledWorkout?
    @State private var showingAllWorkouts = false
    
    private var currentSettings: GlobalWorkoutSettings {
        settings.first ?? GlobalWorkoutSettings()
    }
    
    private var activePlans: [Plan] {
        allPlans.filter { $0.status == .active }
    }
    
    private var todaysWorkouts: [ScheduledWorkout] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return allWorkouts.filter { workout in
            !workout.completed &&
            calendar.isDate(workout.scheduledDate, inSameDayAs: today)
        }
        .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    private var upcomingWorkouts: [ScheduledWorkout] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return allWorkouts.filter { workout in
            !workout.completed &&
            workout.scheduledDate > today &&
            workout.scheduledDate <= nextWeek
        }
        .sorted { $0.scheduledDate < $1.scheduledDate }
        .prefix(3)
        .map { $0 }
    }
    
    private var recentCompletedWorkouts: [ScheduledWorkout] {
        allWorkouts
            .filter { $0.completed }
            .sorted { ($0.completedDate ?? $0.scheduledDate) > ($1.completedDate ?? $1.scheduledDate) }
            .prefix(3)
            .map { $0 }
    }
    
    private var currentStreak: Int {
        // Calculate consecutive days with completed workouts
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let hasWorkout = allWorkouts.contains { workout in
                workout.completed &&
                calendar.isDate(workout.completedDate ?? workout.scheduledDate, inSameDayAs: dayStart)
            }
            
            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if streak > 0 {
                break
            } else {
                break
            }
            
            // Safety: max 365 day streak check
            if streak > 365 { break }
        }
        
        return streak
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderSection(streak: currentStreak)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Today's Workout Hero Card
                    if let workout = todaysWorkouts.first {
                        TodayWorkoutCard(workout: workout)
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                    } else {
                        NoWorkoutCard(activePlans: activePlans.count)
                            .padding(.horizontal)
                    }
                    
                    // Quick Stats
                    QuickStatsSection(
                        streak: currentStreak,
                        completedThisWeek: weeklyCompletedCount(),
                        totalThisWeek: weeklyTotalCount()
                    )
                    .padding(.horizontal)
                    
                    // Upcoming Workouts
                    if !upcomingWorkouts.isEmpty {
                        UpcomingSection(workouts: upcomingWorkouts)
                    }
                    
                    // Recent Activity
                    if !recentCompletedWorkouts.isEmpty {
                        RecentActivitySection(workouts: recentCompletedWorkouts)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedWorkout) { workout in
                ActiveWorkoutView(workout: workout)
            }
        }
    }
    
    private func weeklyCompletedCount() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return allWorkouts.filter { workout in
            workout.completed &&
            (workout.completedDate ?? workout.scheduledDate) >= weekAgo
        }.count
    }
    
    private func weeklyTotalCount() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let today = Date()
        
        return allWorkouts.filter { workout in
            workout.scheduledDate >= weekAgo &&
            workout.scheduledDate <= today
        }.count
    }
}

// MARK: - Header Section

struct HeaderSection: View {
    let streak: Int
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(dateText())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if streak > 0 {
                StreakBadge(streak: streak)
            }
        }
    }
    
    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private func dateText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("🔥")
                .font(.system(size: 28))
            Text("\(streak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Today Workout Card

struct TodayWorkoutCard: View {
    let workout: ScheduledWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S WORKOUT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    if let plan = workout.plan {
                        Text(plan.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                WorkoutTypeIcon(type: workout.workoutType)
            }
            
            // Exercise List
            VStack(alignment: .leading, spacing: 12) {
                ForEach(workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).prefix(4), id: \.id) { exercise in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Text(exercise.exerciseDefinition.name)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let weight = exercise.targetWeight, let sets = exercise.targetSets, let reps = exercise.targetReps {
                            Text("\(sets)×\(reps) @ \(Int(weight))lbs")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                if workout.exercises.count > 4 {
                    Text("+\(workout.exercises.count - 4) more exercises")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 20)
                }
            }
            
            // Action Button
            HStack {
                Image(systemName: "play.fill")
                Text("Start Workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: workoutGradient(workout.workoutType),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    private func workoutGradient(_ type: WorkoutType) -> [Color] {
        switch type {
        case .strength:
            return [Color(red: 0.3, green: 0.2, blue: 0.8), Color(red: 0.5, green: 0.3, blue: 0.9)]
        case .cardio:
            return [Color(red: 0.9, green: 0.3, blue: 0.4), Color(red: 1.0, green: 0.4, blue: 0.3)]
        case .mixed:
            return [Color(red: 0.2, green: 0.6, blue: 0.8), Color(red: 0.3, green: 0.7, blue: 0.9)]
        }
    }
}

// MARK: - No Workout Card

struct NoWorkoutCard: View {
    let activePlans: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Workout Scheduled")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(activePlans > 0 ? "Rest day! Your next workout is coming up." : "Create a plan to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Workout Type Icon

struct WorkoutTypeIcon: View {
    let type: WorkoutType
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 24))
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
            .background(Color.white.opacity(0.2))
            .clipShape(Circle())
    }
    
    private var iconName: String {
        switch type {
        case .strength: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .mixed: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Quick Stats Section

struct QuickStatsSection: View {
    let streak: Int
    let completedThisWeek: Int
    let totalThisWeek: Int
    
    var weekProgress: Double {
        guard totalThisWeek > 0 else { return 0 }
        return Double(completedThisWeek) / Double(totalThisWeek)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Streak",
                value: "\(streak)",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "This Week",
                value: "\(completedThisWeek)/\(totalThisWeek)",
                icon: "chart.bar.fill",
                color: .blue,
                progress: weekProgress
            )
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var progress: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            if let progress = progress {
                ProgressView(value: progress)
                    .tint(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Upcoming Section

struct UpcomingSection: View {
    let workouts: [ScheduledWorkout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(workouts) { workout in
                UpcomingWorkoutRow(workout: workout)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Upcoming Workout Row

struct UpcomingWorkoutRow: View {
    let workout: ScheduledWorkout
    
    var body: some View {
        HStack(spacing: 12) {
            // Date Badge
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(dayNumber)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(width: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                if let plan = workout.plan {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: workout.scheduledDate).uppercased()
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: workout.scheduledDate)
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let workouts: [ScheduledWorkout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(workouts) { workout in
                RecentActivityRow(workout: workout)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Recent Activity Row

struct RecentActivityRow: View {
    let workout: ScheduledWorkout
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                if let plan = workout.plan {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let duration = workout.totalDuration {
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var timeAgo: String {
        let date = workout.completedDate ?? workout.scheduledDate
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    TodayView()
        .modelContainer(for: [Plan.self, ScheduledWorkout.self, GlobalWorkoutSettings.self])
}
