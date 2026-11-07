import SwiftUI
import SwiftData
import Charts

// MARK: - Time Period Filter

enum TimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case ytd = "YTD"
    case allTime = "All Time"
    
    func dateRange(from referenceDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = referenceDate
        var start: Date
        
        switch self {
        case .day:
            start = calendar.startOfDay(for: referenceDate)
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        case .ytd:
            let year = calendar.component(.year, from: referenceDate)
            start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? referenceDate
        case .allTime:
            start = calendar.date(byAdding: .year, value: -10, to: referenceDate) ?? referenceDate
        }
        
        return (start, end)
    }
}

// MARK: - Main Analytics View

struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.startDate) private var allWorkouts: [Workout]
    
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedExercise: String = "All Exercises"
    @State private var selectedTab: AnalyticsTab = .overview
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case progress = "Progress"
        case goals = "Goals"
        case history = "History"
    }
    
    var availableExercises: [String] {
        ["All Exercises"] + AnalyticsService.strengthExerciseNames(in: allWorkouts)
    }

    /// The exercise the filter is set to; nil means all exercises.
    var exerciseFilter: String? {
        selectedExercise == "All Exercises" ? nil : selectedExercise
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Time Period Picker (History shows everything, grouped by month)
                if selectedTab != .history {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }
                
                // Exercise Filter
                if availableExercises.count > 2 && selectedTab != .history {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(availableExercises, id: \.self) { exercise in
                            Text(exercise).tag(exercise)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }
                
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case .overview:
                        OverviewTab(
                            workouts: allWorkouts,
                            exerciseName: exerciseFilter,
                            period: selectedPeriod
                        )
                    case .progress:
                        ProgressTab(
                            workouts: allWorkouts,
                            exerciseName: exerciseFilter,
                            period: selectedPeriod
                        )
                    case .goals:
                        GoalsTab(workouts: allWorkouts)
                    case .history:
                        HistoryTab()
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let workouts: [Workout]
    let exerciseName: String?
    let period: TimePeriod
    
    var completedSessions: [ExerciseSession] {
        AnalyticsService.completedStrengthSessions(workouts: workouts, period: period, exerciseName: exerciseName)
    }
    
    var totalVolume: Int {
        AnalyticsService.totalVolume(completedSessions)
    }
    
    var totalWorkouts: Int {
        completedSessions.count
    }
    
    var averagePerformance: Double {
        AnalyticsService.averagePerformance(completedSessions)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Total Volume",
                    value: formatVolume(totalVolume),
                    icon: "cube.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Workouts",
                    value: "\(totalWorkouts)",
                    icon: "calendar.badge.checkmark",
                    color: .green
                )
                
                MetricCard(
                    title: "Avg Performance",
                    value: "\(Int(averagePerformance))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                MetricCard(
                    title: "PRs Hit",
                    value: "\(AnalyticsService.prCount(completedSessions))",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal)
            
            // Volume Over Time Chart
            if !completedSessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume Over Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(AnalyticsService.volumeByDay(completedSessions), id: \.date) { dataPoint in
                            BarMark(
                                x: .value("Date", dataPoint.date, unit: .day),
                                y: .value("Volume", dataPoint.volume)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Activity")
                    .font(.headline)
                    .padding(.horizontal)
                
                if completedSessions.isEmpty {
                    Text("No workouts completed in this period")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(completedSessions.suffix(5).reversed(), id: \.id) { session in
                        RecentActivityRow(session: session)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk lbs", Double(volume) / 1000.0)
        } else {
            return "\(volume) lbs"
        }
    }
}

// MARK: - Progress Tab

struct ProgressTab: View {
    let workouts: [Workout]
    let exerciseName: String?
    let period: TimePeriod
    
    var completedSessions: [ExerciseSession] {
        AnalyticsService.completedStrengthSessions(workouts: workouts, period: period, exerciseName: exerciseName)
    }
    
    /// Quick workouts have no plan, so they are left out of the performance chart.
    var performanceSessions: [ExerciseSession] {
        AnalyticsService.performanceSessions(completedSessions)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Weight Progression Chart
            if !completedSessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max Weight Progression")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(AnalyticsService.maxWeightByDay(completedSessions), id: \.date) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date, unit: .day),
                                y: .value("Weight", dataPoint.weight)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", dataPoint.date, unit: .day),
                                y: .value("Weight", dataPoint.weight)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 250)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Performance Percentage Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Percentage")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(performanceSessions, id: \.id) { session in
                            BarMark(
                                x: .value("Date", session.completedDate ?? session.date, unit: .day),
                                y: .value("Performance", session.performancePercentage)
                            )
                            .foregroundStyle(performanceColor(session.performancePercentage).gradient)
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...100)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Exercise Breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Breakdown")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(AnalyticsService.exerciseStats(completedSessions), id: \.name) { stat in
                        ExerciseStatRow(stat: stat)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No workout data for this period")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            }
        }
        .padding(.vertical)
    }
    
    private func performanceColor(_ percentage: Double) -> Color {
        if percentage >= 90 { return .green }
        else if percentage >= 75 { return .orange }
        else { return .red }
    }
}

// MARK: - Goals Tab

struct GoalsTab: View {
    let workouts: [Workout]
    
    var activeWorkouts: [Workout] {
        AnalyticsService.goalWorkouts(workouts)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if activeWorkouts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No active programs")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Start a program to track your goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                Text("Active Goals")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ForEach(activeWorkouts, id: \.id) { workout in
                    GoalCard(workout: workout)
                }
                
                // Milestones
                let milestones = upcomingMilestones()
                if !milestones.isEmpty {
                    Text("Upcoming Milestones")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(milestones, id: \.title) { milestone in
                        MilestoneRow(milestone: milestone)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func upcomingMilestones() -> [Milestone] {
        var milestones: [Milestone] = []
        
        for workout in activeWorkouts {
            // Halfway milestone
            if workout.currentWeek < workout.totalWeeks / 2 {
                milestones.append(Milestone(
                    title: "\(workout.name) - Halfway Point",
                    description: "Week \(workout.totalWeeks / 2) of \(workout.totalWeeks)",
                    progress: Double(workout.currentWeek) / Double(workout.totalWeeks / 2),
                    icon: "flag.fill",
                    color: .orange
                ))
            }
        }
        
        return milestones.sorted { $0.progress > $1.progress }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentActivityRow: View {
    let session: ExerciseSession
    
    private var isQuick: Bool {
        session.workoutExercise?.isFreeform ?? false
    }
    
    private var detail: String {
        if isQuick {
            let count = session.sets.filter { $0.completed }.count
            return "\(count) set\(count == 1 ? "" : "s")"
        }
        return "\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutExercise?.exercise.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if !isQuick {
                    Text("\(Int(session.performancePercentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(performanceColor(session.performancePercentage))
                }
                
                if let date = session.completedDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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

struct ExerciseStatRow: View {
    let stat: ExerciseStat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.name)
                    .font(.headline)
                Spacer()
                Text("\(stat.sessions) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                StatItem(label: "Volume", value: "\(stat.totalVolume) lbs")
                StatItem(label: "Max", value: "\(Int(stat.maxWeight)) lbs")
                StatItem(label: "Avg", value: "\(Int(stat.avgPerformance))%")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct GoalCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                    Text("\(workout.templateType.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Week \(workout.currentWeek)/\(workout.totalWeeks)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(Int(workout.progressPercentage))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            ProgressView(value: Double(workout.currentWeek), total: Double(workout.totalWeeks))
                .tint(.blue)
            
            ForEach(AnalyticsService.goalExercises(of: workout), id: \.id) { exercise in
                HStack {
                    Text(exercise.exercise.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(exercise.startingWeight))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(exercise.currentWeight)) lbs")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: milestone.icon)
                .font(.title3)
                .foregroundColor(milestone.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: milestone.progress, total: 1.0)
                    .tint(milestone.color)
            }
            
            Spacer()
            
            Text("\(Int(milestone.progress * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(milestone.color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Data Models

struct ExerciseStat {
    let name: String
    let sessions: Int
    let totalVolume: Int
    let maxWeight: Double
    let avgPerformance: Double
}

struct Milestone {
    let title: String
    let description: String
    let progress: Double
    let icon: String
    let color: Color
}
