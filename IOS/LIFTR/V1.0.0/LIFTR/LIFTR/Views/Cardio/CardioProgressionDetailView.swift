import SwiftUI
import SwiftData
import Charts

struct CardioProgressionDetailView: View {
    @Bindable var progression: CardioProgression
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
                    CardioOverviewTab(progression: progression)
                case .history:
                    CardioHistoryTab(progression: progression)
                case .chart:
                    CardioChartTab(progression: progression)
                }
            }
        }
        .navigationTitle(progression.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Overview Tab

struct CardioOverviewTab: View {
    @Bindable var progression: CardioProgression
    
    var completedSessions: [CardioSession] {
        progression.sessions.filter { $0.completed }.sorted { $0.date < $1.date }
    }
    
    var totalDistance: Double {
        completedSessions.compactMap { $0.actualDistance }.reduce(0, +)
    }
    
    var totalDuration: TimeInterval {
        completedSessions.compactMap { $0.duration }.reduce(0, +)
    }
    
    var averagePace: Double? {
        let sessionsWithPace = completedSessions.filter {
            $0.actualDistance != nil && $0.duration != nil && $0.actualDistance! > 0
        }
        guard !sessionsWithPace.isEmpty else { return nil }
        
        let totalPace = sessionsWithPace.compactMap { session -> Double? in
            guard let distance = session.actualDistance, let duration = session.duration else { return nil }
            return (duration / 60.0) / distance // minutes per mile/km
        }.reduce(0, +)
        
        return totalPace / Double(sessionsWithPace.count)
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
                            .tint(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(progression.progressPercentage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
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
                    CardioStatCard(title: "Sessions", value: "\(completedSessions.count)", subtitle: "completed")
                    
                    if progression.cardioType == .running || progression.cardioType == .swimming {
                        CardioStatCard(
                            title: "Distance",
                            value: String(format: "%.1f", totalDistance),
                            subtitle: progression.useMetric ? "km" : "mi"
                        )
                        
                        CardioStatCard(
                            title: "Time",
                            value: formatTotalDuration(totalDuration),
                            subtitle: "total"
                        )
                        
                        if let pace = averagePace {
                            CardioStatCard(
                                title: "Avg Pace",
                                value: formatPace(pace),
                                subtitle: "min/\(progression.useMetric ? "km" : "mi")"
                            )
                        }
                    } else if progression.cardioType == .calisthenics {
                        let totalReps = completedSessions.compactMap { $0.actualReps }.reduce(0, +)
                        CardioStatCard(title: "Total Reps", value: "\(totalReps)", subtitle: "completed")
                        
                        if let maxReps = completedSessions.compactMap({ $0.actualReps }).max() {
                            CardioStatCard(title: "Max Reps", value: "\(maxReps)", subtitle: "best set")
                        }
                    } else {
                        CardioStatCard(
                            title: "Time",
                            value: formatTotalDuration(totalDuration),
                            subtitle: "total"
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Program Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Program Details")
                    .font(.headline)
                
                HStack {
                    Label(progression.cardioType.rawValue, systemImage: progression.cardioType.icon)
                    Spacer()
                }
                
                // Type-specific goals
                switch progression.cardioType {
                case .running, .swimming:
                    if let target = progression.targetDistance {
                        HStack {
                            Text("Target Distance:")
                            Spacer()
                            Text(String(format: "%.1f %@", target, progression.useMetric ? "km" : "mi"))
                                .fontWeight(.semibold)
                        }
                    }
                    
                case .calisthenics:
                    if let exercise = progression.exerciseName, let target = progression.targetReps {
                        HStack {
                            Text("Goal:")
                            Spacer()
                            Text("\(target) \(exercise)")
                                .fontWeight(.semibold)
                        }
                    }
                    
                case .crossfit:
                    if let workoutType = progression.workoutType {
                        HStack {
                            Text("Type:")
                            Spacer()
                            Text(workoutType.rawValue)
                                .fontWeight(.semibold)
                        }
                    }
                    
                case .freeCardio:
                    EmptyView()
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
    
    private func formatTotalDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - History Tab

struct CardioHistoryTab: View {
    @Bindable var progression: CardioProgression
    
    var completedSessions: [CardioSession] {
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
                    CardioSessionHistoryCard(session: session, progression: progression)
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Chart Tab

struct CardioChartTab: View {
    @Bindable var progression: CardioProgression
    
    var completedSessions: [CardioSession] {
        progression.sessions.filter { $0.completed }.sorted { $0.date < $1.date }
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
                // Distance/Reps Progress Chart
                if progression.cardioType == .running || progression.cardioType == .swimming {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(Array(completedSessions.enumerated()), id: \.offset) { index, session in
                                if let distance = session.actualDistance {
                                    LineMark(
                                        x: .value("Date", session.completedDate ?? session.date),
                                        y: .value("Distance", distance)
                                    )
                                    .foregroundStyle(.green)
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Date", session.completedDate ?? session.date),
                                        y: .value("Distance", distance)
                                    )
                                    .foregroundStyle(.green)
                                }
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
                    
                    // Pace Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pace Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(Array(completedSessions.enumerated()), id: \.offset) { index, session in
                                if let pace = session.calculatePace(useMetric: progression.useMetric) {
                                    LineMark(
                                        x: .value("Date", session.completedDate ?? session.date),
                                        y: .value("Pace", pace)
                                    )
                                    .foregroundStyle(.blue)
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Date", session.completedDate ?? session.date),
                                        y: .value("Pace", pace)
                                    )
                                    .foregroundStyle(.blue)
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartYScale(domain: .automatic(includesZero: false, reversed: true))
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                } else if progression.cardioType == .calisthenics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reps Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(Array(completedSessions.enumerated()), id: \.offset) { index, session in
                                if let reps = session.actualReps {
                                    BarMark(
                                        x: .value("Week", "W\(session.weekNumber)"),
                                        y: .value("Reps", reps)
                                    )
                                    .foregroundStyle(.green.gradient)
                                }
                            }
                        }
                        .frame(height: 250)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                // Duration Chart (for all types)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration Over Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(Array(completedSessions.enumerated()), id: \.offset) { index, session in
                            if let duration = session.duration {
                                BarMark(
                                    x: .value("Date", session.completedDate ?? session.date, unit: .day),
                                    y: .value("Minutes", duration / 60.0)
                                )
                                .foregroundStyle(.orange.gradient)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Supporting Views

struct CardioStatCard: View {
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

struct CardioSessionHistoryCard: View {
    let session: CardioSession
    let progression: CardioProgression
    
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
                
                Image(systemName: progression.cardioType.icon)
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            Divider()
            
            // Session details based on type
            switch progression.cardioType {
            case .running, .swimming:
                if let distance = session.actualDistance {
                    HStack {
                        Text("Distance:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f %@", distance, progression.useMetric ? "km" : "mi"))
                            .fontWeight(.semibold)
                    }
                }
                
                if let duration = session.duration {
                    HStack {
                        Text("Duration:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(duration))
                            .fontWeight(.semibold)
                    }
                }
                
                if let pace = session.calculatePace(useMetric: progression.useMetric) {
                    HStack {
                        Text("Pace:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatPace(pace))
                            .fontWeight(.semibold)
                    }
                }
                
            case .calisthenics:
                if let reps = session.actualReps, let sets = session.actualSets {
                    HStack {
                        Text("Performance:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(sets) sets × \(reps) reps")
                            .fontWeight(.semibold)
                    }
                }
                
            case .crossfit:
                if let rounds = session.rounds {
                    HStack {
                        Text("Rounds:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(rounds)")
                            .fontWeight(.semibold)
                    }
                }
                
                if let duration = session.duration {
                    HStack {
                        Text("Duration:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(duration))
                            .fontWeight(.semibold)
                    }
                }
                
            case .freeCardio:
                if let duration = session.duration {
                    HStack {
                        Text("Duration:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(duration))
                            .fontWeight(.semibold)
                    }
                }
            }
            
            if let notes = session.notes, !notes.isEmpty {
                Divider()
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let rpe = session.rpe {
                Divider()
                HStack {
                    Text("RPE:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(rpe)/10")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d min/%@", minutes, seconds, progression.useMetric ? "km" : "mi")
    }
}
