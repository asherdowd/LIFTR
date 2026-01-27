import SwiftUI
import SwiftData
import Charts

struct ProgramDetailView: View {
    @Bindable var program: Program
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
                    ProgramOverviewTab(program: program)
                case .history:
                    ProgramHistoryTab(program: program)
                case .chart:
                    ProgramChartTab(program: program)
                }
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Overview Tab

struct ProgramOverviewTab: View {
    @Bindable var program: Program
    
    var completedSessions: [ExerciseSession] {
        program.trainingDays
            .flatMap { $0.sessions }
            .filter { $0.completed }
            .sorted { ($0.completedDate ?? $0.date) < ($1.completedDate ?? $1.date) }
    }
    
    var totalVolume: Int {
        completedSessions.reduce(0) { total, session in
            total + session.sets.reduce(0) { setTotal, set in
                setTotal + ((set.actualReps ?? 0) * Int(set.actualWeight ?? 0))
            }
        }
    }
    
    var uniqueCompletedWorkouts: Int {
        Set(completedSessions.map { $0.sessionNumber }).count
    }
    
    var averagePerformance: Double {
        guard !completedSessions.isEmpty else { return 0 }
        let totalSets = completedSessions.flatMap { $0.sets }
        let completedSets = totalSets.filter { $0.completed }
        guard !totalSets.isEmpty else { return 0 }
        return Double(completedSets.count) / Double(totalSets.count) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Program Status")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(program.currentWeek) of \(program.totalWeeks)")
                            .font(.title3)
                            .fontWeight(.bold)
                        ProgressView(value: Double(program.currentWeek), total: Double(program.totalWeeks))
                            .tint(.purple)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(program.progressPercentage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
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
                    ProgramStatCard(title: "Workouts", value: "\(uniqueCompletedWorkouts)", subtitle: "completed")
                    ProgramStatCard(title: "Volume", value: formatVolume(totalVolume), subtitle: "total lbs")
                    ProgramStatCard(title: "Sessions", value: "\(completedSessions.count)", subtitle: "total")
                    ProgramStatCard(title: "Performance", value: "\(Int(averagePerformance))%", subtitle: "average")
                }
                .padding(.horizontal)
            }
            
            // Template Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Program Details")
                    .font(.headline)
                
                HStack {
                    Label(program.templateType.rawValue, systemImage: "book.fill")
                    Spacer()
                }
                
                // Training Days
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Days")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(program.trainingDays.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                        HStack {
                            Text(day.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(day.exercises.count) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let notes = program.notes, !notes.isEmpty {
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
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", Double(volume) / 1000.0)
        } else {
            return "\(volume)"
        }
    }
}

// MARK: - History Tab

struct ProgramHistoryTab: View {
    @Bindable var program: Program
    
    var completedWorkouts: [(sessionNumber: Int, sessions: [ExerciseSession])] {
        let allCompleted = program.trainingDays
            .flatMap { $0.sessions }
            .filter { $0.completed }
        
        let grouped = Dictionary(grouping: allCompleted, by: { $0.sessionNumber })
        
        return grouped.map { (sessionNumber: $0.key, sessions: $0.value) }
            .sorted { $0.sessionNumber > $1.sessionNumber }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if completedWorkouts.isEmpty {
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
                
                ForEach(completedWorkouts, id: \.sessionNumber) { workout in
                    ProgramWorkoutHistoryCard(sessionNumber: workout.sessionNumber, sessions: workout.sessions)
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Chart Tab

struct ProgramChartTab: View {
    @Bindable var program: Program
    
    var completedSessions: [ExerciseSession] {
        program.trainingDays
            .flatMap { $0.sessions }
            .filter { $0.completed }
            .sorted { ($0.completedDate ?? $0.date) < ($1.completedDate ?? $1.date) }
    }
    
    var volumeByWorkout: [(sessionNumber: Int, volume: Int)] {
        let grouped = Dictionary(grouping: completedSessions, by: { $0.sessionNumber })
        
        return grouped.map { sessionNum, sessions in
            let volume = sessions.reduce(0) { total, session in
                total + session.sets.reduce(0) { setTotal, set in
                    setTotal + ((set.actualReps ?? 0) * Int(set.actualWeight ?? 0))
                }
            }
            return (sessionNumber: sessionNum, volume: volume)
        }.sorted { $0.sessionNumber < $1.sessionNumber }
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
                // Volume Over Time
                Text("Volume Per Workout")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Chart {
                        ForEach(volumeByWorkout, id: \.sessionNumber) { data in
                            BarMark(
                                x: .value("Workout", "#\(data.sessionNumber)"),
                                y: .value("Volume", data.volume)
                            )
                            .foregroundStyle(.purple.gradient)
                        }
                    }
                    .frame(height: 250)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Exercise-specific charts
                ForEach(program.trainingDays.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                    ForEach(day.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                        if let chartData = exerciseProgressData(for: exercise, in: day) {
                            ExerciseProgressChart(exerciseName: exercise.exerciseName, data: chartData)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func exerciseProgressData(for exercise: ProgramExercise, in trainingDay: TrainingDay) -> [(date: Date, weight: Double)]? {
        let sessions = trainingDay.sessions
            .filter { $0.exercise?.id == exercise.id && $0.completed }
            .sorted { ($0.completedDate ?? $0.date) < ($1.completedDate ?? $1.date) }
        
        guard !sessions.isEmpty else { return nil }
        
        return sessions.map { session in
            let weight = session.sets.first?.actualWeight ?? session.plannedWeight
            return (date: session.completedDate ?? session.date, weight: weight)
        }
    }
}

// MARK: - Supporting Views

struct ProgramStatCard: View {
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

struct ProgramWorkoutHistoryCard: View {
    let sessionNumber: Int
    let sessions: [ExerciseSession]
    
    var trainingDay: TrainingDay? {
        sessions.first?.trainingDay
    }
    
    var weekNumber: Int {
        sessions.first?.weekNumber ?? 0
    }
    
    var completedDate: Date? {
        sessions.first?.completedDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout #\(sessionNumber)")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        if let day = trainingDay {
                            Text(day.name)
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                        Text("• Week \(weekNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let date = completedDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Exercises
            ForEach(sessions.sorted(by: { ($0.exercise?.orderIndex ?? 0) < ($1.exercise?.orderIndex ?? 0) })) { session in
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.exercise?.exerciseName ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Target: \(session.plannedSets)×\(session.plannedReps) @ \(Int(session.plannedWeight)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let completedSets = session.sets.filter { $0.completed }.count
                        Text("\(completedSets)/\(session.sets.count) sets")
                            .font(.caption)
                            .foregroundColor(completedSets == session.sets.count ? .green : .orange)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct ExerciseProgressChart: View {
    let exerciseName: String
    let data: [(date: Date, weight: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(exerciseName) Progress")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.purple)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.purple)
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
