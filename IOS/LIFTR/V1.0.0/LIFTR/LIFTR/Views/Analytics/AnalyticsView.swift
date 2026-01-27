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
    @Query(sort: \Progression.startDate) private var allProgressions: [Progression]
    @Query(sort: \CardioProgression.startDate) private var allCardioProgressions: [CardioProgression]
    
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedExercise: String = "All Exercises"
    @State private var selectedTab: AnalyticsTab = .overview
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case progress = "Progress"
        case goals = "Goals"
    }
    
    var availableExercises: [String] {
        var exercises = ["All Exercises"]
        exercises.append(contentsOf: allProgressions.map { $0.exerciseName })
        return exercises
    }
    
    var filteredProgressions: [Progression] {
        if selectedExercise == "All Exercises" {
            return allProgressions
        } else {
            return allProgressions.filter { $0.exerciseName == selectedExercise }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Time Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Exercise Filter
                if allProgressions.count > 1 {
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
                            progressions: filteredProgressions,
                            period: selectedPeriod
                        )
                    case .progress:
                        ProgressTab(
                            progressions: filteredProgressions,
                            period: selectedPeriod
                        )
                    case .goals:
                        GoalsTab(
                            progressions: filteredProgressions,
                            period: selectedPeriod
                        )
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let progressions: [Progression]
    let period: TimePeriod
    
    var completedSessions: [WorkoutSession] {
        let dateRange = period.dateRange()
        return progressions
            .flatMap { $0.sessions }
            .filter {
                $0.completed &&
                ($0.completedDate ?? $0.date) >= dateRange.start &&
                ($0.completedDate ?? $0.date) <= dateRange.end
            }
            .sorted { ($0.completedDate ?? $0.date) < ($1.completedDate ?? $1.date) }
    }
    
    var totalVolume: Int {
        completedSessions.reduce(0) { total, session in
            let sessionVolume = session.sets.reduce(0) { setTotal, set in
                setTotal + ((set.actualReps ?? 0) * Int(set.actualWeight ?? 0))
            }
            return total + sessionVolume
        }
    }
    
    var totalWorkouts: Int {
        completedSessions.count
    }
    
    var averagePerformance: Double {
        guard !completedSessions.isEmpty else { return 0 }
        let total = completedSessions.reduce(0.0) { $0 + $1.performancePercentage }
        return total / Double(completedSessions.count)
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
                    value: "\(countPRs())",
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
                        ForEach(volumeByDate(), id: \.date) { dataPoint in
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
    
    private func countPRs() -> Int {
        // Count sessions where actual weight exceeded previous max
        var prCount = 0
        var exerciseMaxes: [String: Double] = [:]
        
        for session in completedSessions {
            guard let exerciseName = session.progression?.exerciseName else { continue }
            
            let maxWeight = session.sets.compactMap { $0.actualWeight }.max() ?? 0
            
            if let previousMax = exerciseMaxes[exerciseName] {
                if maxWeight > previousMax {
                    prCount += 1
                    exerciseMaxes[exerciseName] = maxWeight
                }
            } else {
                exerciseMaxes[exerciseName] = maxWeight
            }
        }
        
        return prCount
    }
    
    private func volumeByDate() -> [(date: Date, volume: Int)] {
        let grouped = Dictionary(grouping: completedSessions) { session -> Date in
            let calendar = Calendar.current
            return calendar.startOfDay(for: session.completedDate ?? session.date)
        }
        
        return grouped.map { date, sessions in
            let volume = sessions.reduce(0) { total, session in
                let sessionVolume = session.sets.reduce(0) { setTotal, set in
                    setTotal + ((set.actualReps ?? 0) * Int(set.actualWeight ?? 0))
                }
                return total + sessionVolume
            }
            return (date: date, volume: volume)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Progress Tab

struct ProgressTab: View {
    let progressions: [Progression]
    let period: TimePeriod
    
    var completedSessions: [WorkoutSession] {
        let dateRange = period.dateRange()
        return progressions
            .flatMap { $0.sessions }
            .filter {
                $0.completed &&
                ($0.completedDate ?? $0.date) >= dateRange.start &&
                ($0.completedDate ?? $0.date) <= dateRange.end
            }
            .sorted { ($0.completedDate ?? $0.date) < ($1.completedDate ?? $1.date) }
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
                        ForEach(maxWeightByDate(), id: \.date) { dataPoint in
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
                        ForEach(completedSessions, id: \.id) { session in
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
                    
                    ForEach(exerciseStats(), id: \.name) { stat in
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
    
    private func maxWeightByDate() -> [(date: Date, weight: Double)] {
        let grouped = Dictionary(grouping: completedSessions) { session -> Date in
            let calendar = Calendar.current
            return calendar.startOfDay(for: session.completedDate ?? session.date)
        }
        
        return grouped.map { date, sessions in
            let maxWeight = sessions.compactMap { session in
                session.sets.compactMap { $0.actualWeight }.max()
            }.max() ?? 0
            return (date: date, weight: maxWeight)
        }.sorted { $0.date < $1.date }
    }
    
    private func performanceColor(_ percentage: Double) -> Color {
        if percentage >= 90 { return .green }
        else if percentage >= 75 { return .orange }
        else { return .red }
    }
    
    private func exerciseStats() -> [ExerciseStat] {
        let grouped = Dictionary(grouping: completedSessions) { $0.progression?.exerciseName ?? "Unknown" }
        
        return grouped.map { name, sessions in
            let totalVolume = sessions.reduce(0) { total, session in
                let sessionVolume = session.sets.reduce(0) { setTotal, set in
                    setTotal + ((set.actualReps ?? 0) * Int(set.actualWeight ?? 0))
                }
                return total + sessionVolume
            }
            
            let maxWeight = sessions.compactMap { session in
                session.sets.compactMap { $0.actualWeight }.max()
            }.max() ?? 0
            
            let avgPerformance = sessions.reduce(0.0) { $0 + $1.performancePercentage } / Double(sessions.count)
            
            return ExerciseStat(
                name: name,
                sessions: sessions.count,
                totalVolume: totalVolume,
                maxWeight: maxWeight,
                avgPerformance: avgPerformance
            )
        }.sorted { $0.totalVolume > $1.totalVolume }
    }
}

// MARK: - Goals Tab

struct GoalsTab: View {
    let progressions: [Progression]
    let period: TimePeriod
    
    var activeProgressions: [Progression] {
        progressions.filter { $0.status == .active }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if activeProgressions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No active progressions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Create a progression to track your goals")
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
                
                ForEach(activeProgressions, id: \.id) { progression in
                    GoalCard(progression: progression)
                }
                
                // Milestones
                Text("Upcoming Milestones")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(upcomingMilestones(), id: \.title) { milestone in
                    MilestoneRow(milestone: milestone)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func upcomingMilestones() -> [Milestone] {
        var milestones: [Milestone] = []
        
        for progression in activeProgressions {
            // Halfway milestone
            if progression.currentWeek < progression.totalWeeks / 2 {
                milestones.append(Milestone(
                    title: "\(progression.exerciseName) - Halfway Point",
                    description: "Week \(progression.totalWeeks / 2) of \(progression.totalWeeks)",
                    progress: Double(progression.currentWeek) / Double(progression.totalWeeks / 2),
                    icon: "flag.fill",
                    color: .orange
                ))
            }
            
            // Target weight milestone
            let progress = (progression.currentMax - progression.startingWeight) / (progression.targetMax - progression.startingWeight)
            if progress < 1.0 {
                milestones.append(Milestone(
                    title: "\(progression.exerciseName) - Target Weight",
                    description: "\(Int(progression.targetMax)) lbs goal",
                    progress: progress,
                    icon: "target",
                    color: .blue
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
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.progression?.exerciseName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.performancePercentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(performanceColor(session.performancePercentage))
                
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
    let progression: Progression
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progression.exerciseName)
                        .font(.headline)
                    Text("\(progression.templateType.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Week \(progression.currentWeek)/\(progression.totalWeeks)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(Int(progression.progressPercentage))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            ProgressView(value: Double(progression.currentWeek), total: Double(progression.totalWeeks))
                .tint(.blue)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(progression.currentMax)) lbs")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(progression.targetMax)) lbs")
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
