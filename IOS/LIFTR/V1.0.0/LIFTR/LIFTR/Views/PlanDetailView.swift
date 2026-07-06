import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var plan: Plan
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    private var completedWorkouts: Int {
        plan.scheduledWorkouts.filter { $0.completed }.count
    }
    
    private var totalWorkouts: Int {
        plan.scheduledWorkouts.count
    }
    
    private var upcomingWorkouts: [ScheduledWorkout] {
        plan.scheduledWorkouts
            .filter { !$0.completed && $0.date >= Date() }
            .sorted { $0.date < $1.date }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                HeaderCard(plan: plan)
                    .padding(.horizontal)
                
                // Progress Card
                if plan.status != .completed {
                    ProgressCard(
                        currentWeek: plan.currentWeek,
                        totalWeeks: plan.totalWeeks,
                        completedWorkouts: completedWorkouts,
                        totalWorkouts: totalWorkouts
                    )
                    .padding(.horizontal)
                }
                
                // Exercises Section
                ExercisesSection(exercises: plan.exercises.sorted { $0.orderIndex < $1.orderIndex })
                    .padding(.horizontal)
                
                // Upcoming Workouts
                if !upcomingWorkouts.isEmpty {
                    UpcomingWorkoutsSection(workouts: upcomingWorkouts)
                        .padding(.horizontal)
                }
                
                // Actions
                ActionsSection(
                    plan: plan,
                    showingEditSheet: $showingEditSheet,
                    showingDeleteAlert: $showingDeleteAlert
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditPlanView(plan: plan)
        }
        .alert("Delete Plan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePlan()
            }
        } message: {
            Text("This will permanently delete '\(plan.name)' and all associated workouts. This cannot be undone.")
        }
    }
    
    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }
}

// MARK: - Header Card

struct HeaderCard: View {
    let plan: Plan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        PlanTypeLabel(type: plan.planType)
                        StatusBadge(status: plan.status)
                    }
                    
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 24) {
                InfoItem(
                    icon: "calendar",
                    label: "Duration",
                    value: "\(plan.totalWeeks) weeks"
                )
                
                InfoItem(
                    icon: "figure.strengthtraining.traditional",
                    label: "Exercises",
                    value: "\(plan.exercises.count)"
                )
                
                InfoItem(
                    icon: "calendar.badge.clock",
                    label: "Started",
                    value: plan.startDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Info Item

struct InfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let currentWeek: Int
    let totalWeeks: Int
    let completedWorkouts: Int
    let totalWorkouts: Int
    
    var weekProgress: Double {
        Double(currentWeek) / Double(totalWeeks)
    }
    
    var workoutProgress: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(totalWorkouts)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
            
            // Week Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Week \(currentWeek) of \(totalWeeks)")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(weekProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: weekProgress)
                    .tint(.blue)
            }
            
            // Workout Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Workouts")
                        .font(.subheadline)
                    Spacer()
                    Text("\(completedWorkouts) / \(totalWorkouts)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: workoutProgress)
                    .tint(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Exercises Section

struct ExercisesSection: View {
    let exercises: [PlannedExercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
            
            ForEach(exercises) { exercise in
                ExerciseRow(exercise: exercise)
            }
        }
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: PlannedExercise
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseDefinition.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let sets = exercise.targetSets,
                   let reps = exercise.targetReps,
                   let weight = exercise.currentWeight {
                    Text("\(sets) × \(reps) @ \(Int(weight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var categoryIcon: String {
        switch exercise.exerciseDefinition.category {
        case .squat, .deadlift: return "figure.walk"
        case .benchPress, .overheadPress, .chest, .shoulders, .triceps: return "arrow.up.circle.fill"
        case .row, .pullup, .back, .biceps: return "arrow.down.circle.fill"
        case .abs: return "figure.core.training"
        case .quads, .hamstrings, .glutes, .calves: return "figure.strengthtraining.traditional"
        case .running, .cycling, .swimming, .rowing, .other: return "figure.run"
        case .forearms: return "hand.raised.fill"
        }
    }
}

// MARK: - Upcoming Workouts Section

struct UpcomingWorkoutsSection: View {
    let workouts: [ScheduledWorkout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Workouts")
                .font(.headline)
            
            ForEach(workouts) { workout in
                UpcomingWorkoutRow(workout: workout)
            }
        }
    }
}

// MARK: - Actions Section

struct ActionsSection: View {
    let plan: Plan
    @Binding var showingEditSheet: Bool
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Edit Button
            Button {
                showingEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Plan")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            
            // Status Toggle
            if plan.status == .active {
                Button {
                    plan.status = .paused
                    try? plan.modelContext?.save()
                } label: {
                    HStack {
                        Image(systemName: "pause.circle")
                        Text("Pause Plan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
            } else if plan.status == .paused {
                Button {
                    plan.status = .active
                    try? plan.modelContext?.save()
                } label: {
                    HStack {
                        Image(systemName: "play.circle")
                        Text("Resume Plan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                }
            }
            
            // Delete Button
            Button {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Plan")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Edit Plan View (Placeholder)

struct EditPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: Plan
    
    @State private var planName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Details") {
                    TextField("Plan Name", text: $planName)
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        plan.name = planName
                        try? plan.modelContext?.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                planName = plan.name
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlanDetailView(plan: Plan(
            name: "Winter Bulk",
            planType: .program,
            totalWeeks: 12
        ))
    }
    .modelContainer(for: [Plan.self])
}
