import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [User]
    @Query(sort: \Progression.startDate) private var allProgressions: [Progression]
    @Query(sort: \CardioProgression.startDate) private var allCardioProgressions: [CardioProgression]
    @Query(sort: \Program.startDate) private var allPrograms: [Program]
    @Query private var globalSettings: [GlobalProgressionSettings]
    
    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }
    
    var activeProgressions: [Progression] {
        allProgressions.filter { $0.status == .active }
    }
    
    var activeCardioProgressions: [CardioProgression] {
        allCardioProgressions.filter { $0.status == .active }
    }
    
    var activePrograms: [Program] {
        allPrograms.filter { $0.status == .active }
    }
    
    var recentStrengthSessions: [WorkoutSession] {
        let allSessions = activeProgressions.flatMap { $0.sessions }
        return allSessions
            .filter { $0.completed }
            .sorted { $0.completedDate ?? $0.date > $1.completedDate ?? $1.date }
            .prefix(5)
            .map { $0 }
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
    
    var upcomingProgramWorkouts: [(program: Program, trainingDay: TrainingDay, weekNumber: Int, sessionNumber: Int, date: Date)] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: currentSettings.upcomingWorkoutsDays, to: now) ?? now
        
        var upcomingWorkouts: [(program: Program, trainingDay: TrainingDay, weekNumber: Int, sessionNumber: Int, date: Date)] = []
        
        for program in activePrograms {
            for trainingDay in program.trainingDays {
                // Group sessions by sessionNumber (each workout instance)
                let sessionsByWorkout = Dictionary(grouping: trainingDay.sessions) { $0.sessionNumber }
                
                for (sessionNum, sessions) in sessionsByWorkout {
                    // Check if any session in this workout is uncompleted
                    let hasUncompleted = sessions.contains { !$0.completed }
                    
                    // Get the date and week from the first session
                    if let firstSession = sessions.first,
                       hasUncompleted,
                       firstSession.date >= now,
                       firstSession.date <= futureDate {
                        upcomingWorkouts.append((program: program, trainingDay: trainingDay, weekNumber: firstSession.weekNumber, sessionNumber: sessionNum, date: firstSession.date))
                    }
                }
            }
        }
        
        return upcomingWorkouts.sorted { workout1, workout2 in
            workout1.date < workout2.date
        }
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(users.first?.firstName ?? "Guest")!")
                        .font(.largeTitle)
                        .bold()
                    
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // PR Totals Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Current PR Totals")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    VStack(spacing: 0) {
                        PRRow(exercise: "Deadlift", weight: getMaxWeight(for: "Deadlift"))
                        Divider()
                        PRRow(exercise: "Squat", weight: getMaxWeight(for: "Squat"))
                        Divider()
                        PRRow(exercise: "Bench", weight: getMaxWeight(for: "Bench"))
                        Divider()
                        PRRow(exercise: "Overhead", weight: getMaxWeight(for: "Overhead"))
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Upcoming Workouts Section
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
                    if !upcomingStrengthSessions.isEmpty {
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
                            
                            ForEach(upcomingStrengthSessions, id: \.id) { session in
                                UpcomingStrengthSessionRow(session: session)
                            }
                        }
                    }
                    
                    // Program subsection
                    if !upcomingProgramWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                Text("Programs")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, upcomingStrengthSessions.isEmpty ? 0 : 8)
                            
                            ForEach(upcomingProgramWorkouts, id: \.sessionNumber) { workout in
                                UpcomingProgramWorkoutRow(
                                    program: workout.program,
                                    trainingDay: workout.trainingDay,
                                    weekNumber: workout.weekNumber,
                                    sessionNumber: workout.sessionNumber,
                                    date: workout.date
                                )
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
                            .padding(.top, (upcomingStrengthSessions.isEmpty && upcomingProgramWorkouts.isEmpty) ? 0 : 8)
                            
                            ForEach(upcomingCardioSessions, id: \.id) { session in
                                UpcomingCardioSessionRow(session: session)
                            }
                        }
                    }
                    
                    // Empty state
                    if upcomingStrengthSessions.isEmpty && upcomingCardioSessions.isEmpty && upcomingProgramWorkouts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No upcoming workouts scheduled")
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: WorkoutsView()) {
                                Text("Create a Progression")
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
                
                // Recent Workouts Section
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
                    if !recentStrengthSessions.isEmpty {
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
                            
                            ForEach(recentStrengthSessions, id: \.id) { session in
                                RecentStrengthSessionRow(session: session)
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
                    if recentStrengthSessions.isEmpty && recentCardioSessions.isEmpty {
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
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.progression?.exerciseName ?? "Unknown Exercise")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text("\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(session.performancePercentage))% complete")
                        .font(.caption)
                        .foregroundColor(performanceColor(session.performancePercentage))
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
            // Completion indicator
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
                // Day indicator with Week/Day
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
                        
                        // Date
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
                WorkoutSessionView(session: session, progression: progression)
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
                // Day indicator
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
                        
                        // Date
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
                CardioSessionView(session: session, progression: progression)
            }
        }
    }
}

struct UpcomingProgramWorkoutRow: View {
    let program: Program
    let trainingDay: TrainingDay
    let weekNumber: Int
    let sessionNumber: Int
    let date: Date
    @State private var showProgramWorkout = false
    
    var body: some View {
        Button(action: { showProgramWorkout = true }) {
            HStack(spacing: 12) {
                // Day indicator
                VStack(spacing: 2) {
                    Text("W\(weekNumber)")
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("#\(sessionNumber)")
                        .font(.caption2)
                }
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.1))
                .foregroundColor(.purple)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(program.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(trainingDay.name)
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        // Date
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(trainingDay.exercises.count) exercises")
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
        .sheet(isPresented: $showProgramWorkout) {
            ProgramWorkoutView(program: program, trainingDay: trainingDay)
        }
    }
}
