import SwiftUI
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Plan.startDate, order: .reverse) private var allPlans: [Plan]
    
    @State private var showingCreatePlan = false
    @State private var selectedStatus: PlanStatusFilter = .all
    
    enum PlanStatusFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case paused = "Paused"
        case completed = "Completed"
    }
    
    private var filteredPlans: [Plan] {
        switch selectedStatus {
        case .all:
            return allPlans
        case .active:
            return allPlans.filter { $0.status == .active }
        case .paused:
            return allPlans.filter { $0.status == .paused }
        case .completed:
            return allPlans.filter { $0.status == .completed }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredPlans.isEmpty {
                    EmptyPlansView(showingCreatePlan: $showingCreatePlan)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Status Filter
                            StatusFilterPicker(selectedStatus: $selectedStatus)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            // Plans List
                            ForEach(filteredPlans) { plan in
                                NavigationLink(destination: PlanDetailView(plan: plan)) {
                                    PlanCard(plan: plan)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePlan = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanView()
            }
        }
    }
}

// MARK: - Status Filter Picker

struct StatusFilterPicker: View {
    @Binding var selectedStatus: PlansView.PlanStatusFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PlansView.PlanStatusFilter.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        isSelected: selectedStatus == status
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedStatus = status
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: Plan
    
    private var completedWorkouts: Int {
        plan.scheduledWorkouts.filter { $0.completed }.count
    }
    
    private var totalWorkouts: Int {
        plan.scheduledWorkouts.count
    }
    
    private var nextWorkout: ScheduledWorkout? {
        plan.scheduledWorkouts
            .filter { !$0.completed && $0.scheduledDate >= Date() }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        PlanTypeLabel(type: plan.planType)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("\(plan.totalWeeks) weeks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: plan.status)
            }
            
            // Progress
            if plan.status != .completed {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week \(plan.currentWeek) of \(plan.totalWeeks)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(plan.progressPercentage))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                    
                    ProgressView(value: plan.progressPercentage, total: 100)
                        .tint(.accentColor)
                }
            }
            
            // Stats Row
            HStack(spacing: 20) {
                StatItem(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(plan.exercises.count)",
                    label: "Exercises"
                )
                
                StatItem(
                    icon: "calendar",
                    value: "\(completedWorkouts)/\(totalWorkouts)",
                    label: "Workouts"
                )
                
                if let next = nextWorkout {
                    Spacer()
                    NextWorkoutPreview(workout: next)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Plan Type Label

struct PlanTypeLabel: View {
    let type: PlanType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(type.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }
    
    private var icon: String {
        switch type {
        case .strength: return "dumbbell.fill"
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .powerlifting: return "figure.strengthtraining.functional"
        case .endurance: return "figure.run"
        case .custom: return "star.fill"
        }
    }
    
    private var color: Color {
        switch type {
        case .strength: return .blue
        case .hypertrophy: return .purple
        case .powerlifting: return .red
        case .endurance: return .green
        case .custom: return .orange
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: PlanStatus
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .gray
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Next Workout Preview

struct NextWorkoutPreview: View {
    let workout: ScheduledWorkout
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Next")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(relativeDateString)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }
    
    private var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(workout.scheduledDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(workout.scheduledDate) {
            return "Tomorrow"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: workout.scheduledDate, relativeTo: Date())
        }
    }
}

// MARK: - Empty Plans View

struct EmptyPlansView: View {
    @Binding var showingCreatePlan: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Text
            VStack(spacing: 8) {
                Text("No Training Plans")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first plan to start tracking your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Action Button
            Button {
                showingCreatePlan = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Plan")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// Actual views are in separate files:
// - PlanDetailView.swift
// - CreatePlanView.swift

// MARK: - Preview

#Preview {
    PlansView()
        .modelContainer(for: [Plan.self, ScheduledWorkout.self])
}
