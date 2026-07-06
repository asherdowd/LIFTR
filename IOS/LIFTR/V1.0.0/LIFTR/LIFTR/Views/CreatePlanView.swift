import SwiftUI
import SwiftData

struct CreatePlanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: CreateStep = .basicInfo
    @State private var planName: String = ""
    @State private var selectedType: PlanType = .strength
    @State private var totalWeeks: Int = 8
    @State private var selectedExercises: [ExerciseDefinition] = []
    @State private var exerciseConfigs: [UUID: ExerciseConfig] = [:]
    @State private var useMetric: Bool = false
    
    enum CreateStep: Int, CaseIterable {
        case basicInfo = 0
        case selectExercises = 1
        case configure = 2
        case review = 3
        
        var title: String {
            switch self {
            case .basicInfo: return "Plan Details"
            case .selectExercises: return "Select Exercises"
            case .configure: return "Configure"
            case .review: return "Review"
            }
        }
        
        var icon: String {
            switch self {
            case .basicInfo: return "doc.text.fill"
            case .selectExercises: return "list.bullet"
            case .configure: return "slider.horizontal.3"
            case .review: return "checkmark.circle.fill"
            }
        }
    }
    
    struct ExerciseConfig {
        var sets: Int = 5
        var reps: Int = 5
        var startingWeight: Double = 135
        var increment: Double = 5
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .basicInfo:
            return !planName.trimmingCharacters(in: .whitespaces).isEmpty
        case .selectExercises:
            return !selectedExercises.isEmpty
        case .configure:
            return !selectedExercises.isEmpty
        case .review:
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator
                StepProgressIndicator(
                    currentStep: currentStep.rawValue,
                    totalSteps: CreateStep.allCases.count,
                    stepTitles: CreateStep.allCases.map { $0.title }
                )
                .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    BasicInfoStep(
                        planName: $planName,
                        selectedType: $selectedType,
                        totalWeeks: $totalWeeks,
                        useMetric: $useMetric
                    )
                    .tag(CreateStep.basicInfo)
                    
                    SelectExercisesStep(
                        selectedExercises: $selectedExercises
                    )
                    .tag(CreateStep.selectExercises)
                    
                    ConfigureExercisesStep(
                        selectedExercises: $selectedExercises,
                        exerciseConfigs: $exerciseConfigs,
                        useMetric: useMetric
                    )
                    .tag(CreateStep.configure)
                    
                    ReviewStep(
                        planName: planName,
                        selectedType: selectedType,
                        totalWeeks: totalWeeks,
                        selectedExercises: selectedExercises,
                        exerciseConfigs: exerciseConfigs,
                        useMetric: useMetric
                    )
                    .tag(CreateStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(true) // Disable swipe, use buttons only
                
                // Navigation Buttons
                NavigationButtons(
                    currentStep: currentStep,
                    canProceed: canProceed,
                    onBack: goBack,
                    onNext: goNext,
                    onCancel: { dismiss() },
                    onCreate: createPlan
                )
                .padding()
            }
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    private func goBack() {
        guard let currentIndex = CreateStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        
        withAnimation(.spring()) {
            currentStep = CreateStep.allCases[currentIndex - 1]
        }
    }
    
    private func goNext() {
        guard canProceed,
              let currentIndex = CreateStep.allCases.firstIndex(of: currentStep),
              currentIndex < CreateStep.allCases.count - 1 else { return }
        
        withAnimation(.spring()) {
            currentStep = CreateStep.allCases[currentIndex + 1]
        }
    }
    
    // MARK: - Create Plan
    
    private func createPlan() {
        // Create plan
        let plan = Plan(
            name: planName,
            planType: selectedType,
            totalWeeks: totalWeeks,
            useMetric: useMetric
        )
        
        // Add exercises
        for (index, exercise) in selectedExercises.enumerated() {
            let config = exerciseConfigs[exercise.id] ?? ExerciseConfig()
            
            let plannedExercise = PlannedExercise(
                exerciseDefinition: exercise,
                orderIndex: index,
                startingWeight: config.startingWeight,
                currentWeight: config.startingWeight,
                targetSets: config.sets,
                targetReps: config.reps,
                increment: config.increment
            )
            
            plan.exercises.append(plannedExercise)
            context.insert(plannedExercise)
        }
        
        // Generate workouts (simplified - 3 per week)
        let workoutsPerWeek = 3
        var workoutDate = plan.startDate
        
        for week in 1...plan.totalWeeks {
            for day in 1...workoutsPerWeek {
                let workout = ScheduledWorkout(
                    scheduledDate: workoutDate,
                    workoutType: selectedType == .cardio ? .cardio : .strength
                )
                workout.plan = plan
                
                // Add exercises to workout
                for (index, exercise) in selectedExercises.enumerated() {
                    let config = exerciseConfigs[exercise.id] ?? ExerciseConfig()
                    
                    let workoutExercise = WorkoutExercise(
                        exerciseDefinition: exercise,
                        orderIndex: index,
                        targetWeight: config.startingWeight,
                        targetSets: config.sets,
                        targetReps: config.reps
                    )
                    
                    // Create sets
                    for setNum in 1...config.sets {
                        let set = WorkoutSet(
                            setNumber: setNum,
                            targetReps: config.reps,
                            targetWeight: config.startingWeight
                        )
                        workoutExercise.sets.append(set)
                        context.insert(set)
                    }
                    
                    workout.exercises.append(workoutExercise)
                    context.insert(workoutExercise)
                }
                
                plan.scheduledWorkouts.append(workout)
                context.insert(workout)
                
                // Move to next workout day (every other day)
                workoutDate = Calendar.current.date(byAdding: .day, value: 2, to: workoutDate) ?? workoutDate
            }
        }
        
        context.insert(plan)
        try? context.save()
        
        dismiss()
    }
}

// MARK: - Step Progress Indicator

struct StepProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                            height: 8
                        )
                        .animation(.spring(), value: currentStep)
                }
            }
            .frame(height: 8)
            
            // Step Title
            Text(stepTitles[currentStep])
                .font(.headline)
                .animation(.none, value: currentStep)
        }
    }
}

// MARK: - Step 1: Basic Info

struct BasicInfoStep: View {
    @Binding var planName: String
    @Binding var selectedType: PlanType
    @Binding var totalWeeks: Int
    @Binding var useMetric: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Plan Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plan Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Winter Bulk 2026", text: $planName)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Plan Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan Type")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(PlanType.allCases, id: \.self) { type in
                        PlanTypeCard(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Duration")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(totalWeeks) weeks")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(totalWeeks) },
                        set: { totalWeeks = Int($0) }
                    ), in: 4...16, step: 1)
                    .tint(.accentColor)
                }
                
                // Settings
                Toggle("Use Metric (kg)", isOn: $useMetric)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Plan Type Card

struct PlanTypeCard: View {
    let type: PlanType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? color : color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? color : Color(.systemGray6))
            .cornerRadius(12)
        }
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
    
    private var description: String {
        switch type {
        case .strength: return "Build max strength"
        case .hypertrophy: return "Muscle growth focus"
        case .powerlifting: return "Squat, bench, deadlift"
        case .endurance: return "High reps, conditioning"
        case .custom: return "Your own program"
        }
    }
}

// MARK: - Step 2: Select Exercises

struct SelectExercisesStep: View {
    @Binding var selectedExercises: [ExerciseDefinition]
    
    private let allExercises = ExerciseDefinition.builtInExercises
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select exercises for your plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(allExercises) { exercise in
                    ExerciseSelectionRow(
                        exercise: exercise,
                        isSelected: selectedExercises.contains(where: { $0.id == exercise.id })
                    ) {
                        toggleExercise(exercise)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func toggleExercise(_ exercise: ExerciseDefinition) {
        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
            selectedExercises.remove(at: index)
        } else {
            selectedExercises.append(exercise)
        }
    }
}

// MARK: - Exercise Selection Row

struct ExerciseSelectionRow: View {
    let exercise: ExerciseDefinition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(exercise.category.rawValue)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var categoryIcon: String {
        switch exercise.category {
        case .legs: return "figure.walk"
        case .push: return "arrow.up.circle.fill"
        case .pull: return "arrow.down.circle.fill"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .cardio: return "figure.run"
        }
    }
}

// MARK: - Step 3: Configure Exercises

struct ConfigureExercisesStep: View {
    @Binding var selectedExercises: [ExerciseDefinition]
    @Binding var exerciseConfigs: [UUID: CreatePlanView.ExerciseConfig]
    let useMetric: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Configure sets, reps, and starting weights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(selectedExercises) { exercise in
                    ExerciseConfigCard(
                        exercise: exercise,
                        config: Binding(
                            get: { exerciseConfigs[exercise.id] ?? CreatePlanView.ExerciseConfig() },
                            set: { exerciseConfigs[exercise.id] = $0 }
                        ),
                        useMetric: useMetric
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Exercise Config Card

struct ExerciseConfigCard: View {
    let exercise: ExerciseDefinition
    @Binding var config: CreatePlanView.ExerciseConfig
    let useMetric: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(exercise.name)
                .font(.headline)
            
            HStack(spacing: 12) {
                ConfigField(
                    title: "Sets",
                    value: $config.sets,
                    range: 1...10
                )
                
                ConfigField(
                    title: "Reps",
                    value: $config.reps,
                    range: 1...20
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Starting Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(config.startingWeight)) \(useMetric ? "kg" : "lbs")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Slider(
                    value: $config.startingWeight,
                    in: 0...500,
                    step: 5
                )
                .tint(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Config Field

struct ConfigField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(minWidth: 40)
                
                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(value >= range.upperBound)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Step 4: Review

struct ReviewStep: View {
    let planName: String
    let selectedType: PlanType
    let totalWeeks: Int
    let selectedExercises: [ExerciseDefinition]
    let exerciseConfigs: [UUID: CreatePlanView.ExerciseConfig]
    let useMetric: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Plan Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan Summary")
                        .font(.headline)
                    
                    InfoRow(label: "Name", value: planName)
                    InfoRow(label: "Type", value: selectedType.rawValue)
                    InfoRow(label: "Duration", value: "\(totalWeeks) weeks")
                    InfoRow(label: "Exercises", value: "\(selectedExercises.count)")
                    InfoRow(label: "Units", value: useMetric ? "Metric (kg)" : "Imperial (lbs)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Exercises
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.headline)
                    
                    ForEach(selectedExercises) { exercise in
                        let config = exerciseConfigs[exercise.id] ?? CreatePlanView.ExerciseConfig()
                        
                        HStack {
                            Text(exercise.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(config.sets)×\(config.reps) @ \(Int(config.startingWeight))\(useMetric ? "kg" : "lb")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Navigation Buttons

struct NavigationButtons: View {
    let currentStep: CreatePlanView.CreateStep
    let canProceed: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if currentStep.rawValue > 0 {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            
            Button(action: currentStep == .review ? onCreate : onNext) {
                HStack {
                    Text(currentStep == .review ? "Create Plan" : "Next")
                    if currentStep != .review {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    canProceed ?
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canProceed)
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePlanView()
        .modelContainer(for: [Plan.self])
}
