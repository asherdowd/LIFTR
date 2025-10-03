import SwiftUI
import SwiftData

// MARK: - Main Workouts View

struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Progression.startDate) private var allProgressions: [Progression]
    @Query(sort: \CardioProgression.startDate) private var allCardioProgressions: [CardioProgression]
    
    @State private var selectedCategory: WorkoutCategory = .strength
    @State private var showNewProgression = false
    @State private var showNewCardioProgression = false
    
    enum WorkoutCategory: String, CaseIterable {
        case strength = "Strength"
        case cardio = "Cardio"
        
        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .cardio: return "figure.run"
            }
        }
    }
    
    var activeProgressions: [Progression] {
        allProgressions.filter { $0.status == .active }
    }
    
    var activeCardioProgressions: [CardioProgression] {
        allCardioProgressions.filter { $0.status == .active }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WorkoutCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected category
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedCategory {
                        case .strength:
                            if activeProgressions.isEmpty {
                                EmptyProgressionsView(
                                    type: "Strength",
                                    onCreateNew: { showNewProgression = true }
                                )
                            } else {
                                ForEach(activeProgressions) { progression in
                                    ProgressionCard(progression: progression)
                                }
                            }
                            
                            // Create New Strength Progression Button
                            Button(action: { showNewProgression = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Create New Strength Progression")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                        case .cardio:
                            if activeCardioProgressions.isEmpty {
                                EmptyProgressionsView(
                                    type: "Cardio",
                                    onCreateNew: { showNewCardioProgression = true }
                                )
                            } else {
                                ForEach(activeCardioProgressions) { progression in
                                    CardioProgressionCard(progression: progression)
                                }
                            }
                            
                            // Create New Cardio Progression Button
                            Button(action: { showNewCardioProgression = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Create New Cardio Progression")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Workouts")
            .sheet(isPresented: $showNewProgression) {
                CreateProgressionView()
            }
            .sheet(isPresented: $showNewCardioProgression) {
                CreateCardioProgressionView()
            }
        }
    }
}

// MARK: - Cardio Progression Card

struct CardioProgressionCard: View {
    @Environment(\.modelContext) private var context
    @Bindable var progression: CardioProgression
    @State private var showSession = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progression.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(progression.cardioType.rawValue, systemImage: progression.cardioType.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Text(progression.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
                
                // Delete Button
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Divider()
            
            // Progress Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(progression.currentWeek) of \(progression.totalWeeks)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ProgressView(value: Double(progression.currentWeek), total: Double(progression.totalWeeks))
                        .tint(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goalText)
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Navigate to cardio progression detail
                }) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("View Progress")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    // TODO: Navigate to edit cardio progression
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .confirmationDialog(
            "Delete Progression",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProgression()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(progression.name)'? This will remove all workout history and cannot be undone.")
        }
    }
    
    private var statusColor: Color {
        switch progression.status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }
    
    private var goalText: String {
        switch progression.cardioType {
        case .running:
            if let distance = progression.targetDistance {
                return "\(String(format: "%.1f", distance)) mi"
            }
        case .calisthenics:
            if let reps = progression.targetReps, let exercise = progression.exerciseName {
                return "\(reps) \(exercise)"
            }
        case .swimming, .crossfit, .freeCardio:
            return "\(progression.totalWeeks) weeks"
        }
        return "In Progress"
    }
    
    private func deleteProgression() {
        context.delete(progression)
        try? context.save()
    }
}

// MARK: - Empty State View

struct EmptyProgressionsView: View {
    let type: String
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: type == "Strength" ? "dumbbell" : "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Active \(type) Progressions")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tap 'Create New \(type) Progression' below to start tracking your workouts")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(40)
    }
}

// MARK: - Progression Card

struct ProgressionCard: View {
    @Environment(\.modelContext) private var context
    @Bindable var progression: Progression
    @State private var showWorkoutSession = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progression.exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(progression.templateType.rawValue, systemImage: "book.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(progression.progressionStyle.rawValue, systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Text(progression.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
                
                // Delete Button
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Divider()
            
            // Progress Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(progression.currentWeek) of \(progression.totalWeeks)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ProgressView(value: Double(progression.currentWeek), total: Double(progression.totalWeeks))
                        .tint(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(progression.targetMax)) lbs")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            // Next Workout Info
            if let nextSession = getNextSession() {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Workout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(nextSession.plannedWeight)) lbs × \(nextSession.plannedSets) sets of \(nextSession.plannedReps)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Button(action: { showWorkoutSession = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                NavigationLink(destination: ProgressionDetailView(progression: progression)) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("View Progress")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                
                NavigationLink(destination: EditProgressionView(progression: progression)) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .sheet(isPresented: $showWorkoutSession) {
            if let session = getNextSession() {
                WorkoutSessionView(session: session, progression: progression)
            }
        }
        .confirmationDialog(
            "Delete Progression",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProgression()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(progression.exerciseName)'? This will remove all workout history and cannot be undone.")
        }
    }
    
    private var statusColor: Color {
        switch progression.status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }
    
    private func getNextSession() -> WorkoutSession? {
        // Get the first incomplete session for the current week
        return progression.sessions
            .filter { $0.weekNumber == progression.currentWeek && !$0.completed }
            .sorted { $0.dayNumber < $1.dayNumber }
            .first
    }
    
    private func deleteProgression() {
        context.delete(progression)
        try? context.save()
    }
}
