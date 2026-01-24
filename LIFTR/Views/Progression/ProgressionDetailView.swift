import SwiftUI
import SwiftData
import Charts

struct ProgressionDetailView: View {
    @Bindable var progression: Progression
    @State private var selectedTab: DetailTab = .overview
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case history = "History"
        case chart = "Chart"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on selected tab
            ScrollView {
                switch selectedTab {
                case .overview:
                    OverviewTabView(progression: progression)
                case .history:
                    HistoryTabView(progression: progression)
                case .chart:
                    ChartTabView(progression: progression)
                }
            }
        }
        .navigationTitle(progression.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    @Bindable var progression: Progression
    
    var completedSessions: [WorkoutSession] {
        progression.sessions.filter { $0.completed }.sorted { $0.date < $1.date }
    }
    
    var totalVolume: Int {
        completedSessions.reduce(0) { total, session in
            let sessionVolume = session.sets.reduce(0) { setTotal, set in
                setTotal + ((set.actualReps ?? 0) * Int(set.actualWeight ?? 0))
            }
            return total + sessionVolume
        }
    }
    
    var averagePerformance: Double {
        guard !completedSessions.isEmpty else { return 0 }
        let total = completedSessions.reduce(0.0) { $0 + $1.performancePercentage }
        return total / Double(completedSessions.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Progression Status")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(progression.currentWeek) of \(progression.totalWeeks)")
                            .font(.title3)
                            .fontWeight(.bold)
                        ProgressView(value: Double(progression.currentWeek), total: Double(progression.totalWeeks))
                            .tint(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(progression.progressPercentage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Stats Grid
            VStack(alignment: .leading, spacing: 12) {
                Text("Statistics")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Sessions", value: "\(completedSessions.count)", subtitle: "completed")
                    StatCard(title: "Current", value: "\(Int(progression.currentMax)) lbs", subtitle: "max")
                    StatCard(title: "Target", value: "\(Int(progression.targetMax)) lbs", subtitle: "goal")
                    StatCard(title: "Performance", value: "\(Int(averagePerformance))%", subtitle: "average")
                }
                .padding(.horizontal)
            }
            
            // Template & Style Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Program Details")
                    .font(.headline)
                
                HStack {
                    Label(progression.templateType.rawValue, systemImage: "book.fill")
                    Spacer()
                }
                
                HStack {
                    Label(progression.progressionStyle.rawValue, systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                }
                
                if let notes = progression.notes, !notes.isEmpty {
                    Divider()
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

// MARK: - History Tab

struct HistoryTabView: View {
    @Bindable var progression: Progression
    
    var completedSessions: [WorkoutSession] {
        progression.sessions.filter { $0.completed }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if completedSessions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No completed workouts yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Start a workout to see your history here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                Text("Workout History")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(completedSessions) { session in
                    SessionHistoryCard(session: session)
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Chart Tab

struct ChartTabView: View {
    @Bindable var progression: Progression
    
    var completedSessions: [WorkoutSession] {
        progression.sessions.filter { $0.completed }.sorted { $0.date < $1.date }
    }
    
    var chartData: [(date: Date, weight: Double)] {
        completedSessions.map { session in
            // Use the actual weight from the first set (or planned if not logged)
            let weight = session.sets.first?.actualWeight ?? session.plannedWeight
            return (date: session.completedDate ?? session.date, weight: weight)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if completedSessions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No data to display")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Complete workouts to see your progress chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                Text("Weight Progression")
                    .font(.headline)
                    .padding(.horizontal)
                
                // Simple chart view
                VStack(alignment: .leading, spacing: 8) {
                    Chart {
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Weight", data.weight)
                            )
                            .foregroundStyle(.blue)
                            
                            PointMark(
                                x: .value("Date", data.date),
                                y: .value("Weight", data.weight)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 250)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Performance Chart
                Text("Performance Percentage")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Chart {
                        ForEach(Array(completedSessions.enumerated()), id: \.offset) { index, session in
                            BarMark(
                                x: .value("Week", "W\(session.weekNumber)"),
                                y: .value("Performance", session.performancePercentage)
                            )
                            .foregroundStyle(performanceColor(for: session.performancePercentage))
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...100)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func performanceColor(for percentage: Double) -> Color {
        if percentage >= 90 { return .green }
        else if percentage >= 75 { return .orange }
        else { return .red }
    }
}

// MARK: - Session History Card

struct SessionHistoryCard: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(session.weekNumber), Day \(session.dayNumber)")
                        .font(.headline)
                    
                    if let completedDate = session.completedDate {
                        Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(session.performancePercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor)
                    Text("completion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Target vs Actual
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.totalCompletedReps) / \(session.totalPlannedReps) reps")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            // Sets breakdown
            VStack(spacing: 4) {
                ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    HStack(spacing: 8) {
                        Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set.completed ? .green : .secondary)
                            .font(.caption)
                        
                        Text("Set \(set.setNumber):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let actualReps = set.actualReps, let actualWeight = set.actualWeight {
                            Text("\(actualReps) reps @ \(Int(actualWeight)) lbs")
                                .font(.caption)
                                .foregroundColor(set.wasSuccessful ? .primary : .orange)
                            
                            if let rpe = set.rpe {
                                Text("• RPE \(rpe)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Not logged")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            if let notes = session.notes, !notes.isEmpty {
                Divider()
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var performanceColor: Color {
        if session.performancePercentage >= 90 { return .green }
        else if session.performancePercentage >= 75 { return .orange }
        else { return .red }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
