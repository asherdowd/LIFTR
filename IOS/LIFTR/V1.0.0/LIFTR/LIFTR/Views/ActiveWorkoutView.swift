import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: ScheduledWorkout
    @Query private var settings: [GlobalWorkoutSettings]
    
    @State private var currentExerciseIndex: Int = 0
    @State private var currentSetIndex: Int = 0
    @State private var showRestTimer: Bool = false
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var restTimer: Timer?
    @State private var showCompletionSheet: Bool = false
    @State private var actualWeight: String = ""
    @State private var actualReps: String = ""
    
    private var currentSettings: GlobalWorkoutSettings {
        settings.first ?? GlobalWorkoutSettings()
    }
    
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    private var currentExercise: WorkoutExercise? {
        guard currentExerciseIndex < sortedExercises.count else { return nil }
        return sortedExercises[currentExerciseIndex]
    }
    
    private var currentSet: WorkoutSet? {
        guard let exercise = currentExercise else { return nil }
        let sets = exercise.sets.sorted { $0.setNumber < $1.setNumber }
        guard currentSetIndex < sets.count else { return nil }
        return sets[currentSetIndex]
    }
    
    private var totalSets: Int {
        currentExercise?.sets.count ?? 0
    }
    
    private var completedSets: Int {
        currentExercise?.sets.filter { $0.completed }.count ?? 0
    }
    
    var body: some View {
        ZStack {
            // Main Content
            VStack(spacing: 0) {
                // Header
                WorkoutHeader(
                    workout: workout,
                    currentExerciseIndex: currentExerciseIndex,
                    totalExercises: sortedExercises.count,
                    dismiss: dismiss
                )
                
                if let exercise = currentExercise, let set = currentSet {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Exercise Info
                            ExerciseInfoSection(
                                exercise: exercise,
                                currentSet: currentSetIndex + 1,
                                totalSets: totalSets,
                                completedSets: completedSets
                            )
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Target Display
                            TargetDisplaySection(
                                weight: set.targetWeight ?? 0,
                                reps: set.targetReps ?? 0,
                                useMetric: workout.plan?.useMetric ?? false
                            )
                            .padding(.horizontal)
                            
                            // Set Logging
                            SetLoggingSection(
                                set: set,
                                actualWeight: $actualWeight,
                                actualReps: $actualReps,
                                onComplete: completeCurrentSet
                            )
                            .padding(.horizontal)
                            
                            // Previous Sets History
                            if completedSets > 0 {
                                PreviousSetsSection(
                                    sets: exercise.sets
                                        .filter { $0.completed }
                                        .sorted { $0.setNumber < $1.setNumber }
                                )
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.bottom, 100)
                    }
                } else {
                    // Workout Complete
                    WorkoutCompleteView(
                        workout: workout,
                        onDismiss: { dismiss() }
                    )
                }
            }
            
            // Rest Timer Overlay
            if showRestTimer {
                RestTimerOverlay(
                    timeRemaining: $restTimeRemaining,
                    onSkip: skipRestTimer,
                    onComplete: endRestTimer
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            initializeWorkout()
        }
        .onDisappear {
            stopRestTimer()
        }
    }
    
    // MARK: - Actions
    
    private func initializeWorkout() {
        // Pre-fill with target values
        if let set = currentSet {
            actualWeight = set.targetWeight != nil ? String(Int(set.targetWeight!)) : ""
            actualReps = set.targetReps != nil ? String(set.targetReps!) : ""
        }
        
        // Start workout timer
        if workout.startTime == nil {
            workout.startTime = Date()
        }
    }
    
    private func completeCurrentSet() {
        guard let set = currentSet,
              let weight = Double(actualWeight),
              let reps = Int(actualReps) else { return }
        
        // Log set
        set.actualWeight = weight
        set.actualReps = reps
        set.completed = true
        
        // Save
        try? context.save()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Move to next set or exercise
        let remainingSets = totalSets - (completedSets + 1)
        
        if remainingSets > 0 {
            // Start rest timer if enabled
            if currentSettings.autoStartRestTimer {
                startRestTimer()
            }
            
            // Move to next set
            currentSetIndex += 1
            
            // Pre-fill next set
            if let nextSet = currentSet {
                actualWeight = nextSet.targetWeight != nil ? String(Int(nextSet.targetWeight!)) : ""
                actualReps = nextSet.targetReps != nil ? String(nextSet.targetReps!) : ""
            }
        } else {
            // Exercise complete - move to next exercise
            moveToNextExercise()
        }
    }
    
    private func moveToNextExercise() {
        if currentExerciseIndex < sortedExercises.count - 1 {
            currentExerciseIndex += 1
            currentSetIndex = 0
            
            // Pre-fill first set of next exercise
            if let nextSet = currentSet {
                actualWeight = nextSet.targetWeight != nil ? String(Int(nextSet.targetWeight!)) : ""
                actualReps = nextSet.targetReps != nil ? String(nextSet.targetReps!) : ""
            }
            
            // Haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        } else {
            // Workout complete
            completeWorkout()
        }
    }
    
    private func completeWorkout() {
        workout.completed = true
        workout.completedDate = Date()
        workout.endTime = Date()
        
        if let start = workout.startTime {
            workout.totalDuration = Date().timeIntervalSince(start)
        }
        
        try? context.save()
        
        // Haptic celebration
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        showCompletionSheet = true
    }
    
    // MARK: - Rest Timer
    
    private func startRestTimer() {
        restTimeRemaining = TimeInterval(currentSettings.defaultRestTime)
        showRestTimer = true
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
                
                // Haptic at 3, 2, 1
                if restTimeRemaining <= 3 && restTimeRemaining > 0 {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } else {
                endRestTimer()
            }
        }
    }
    
    private func skipRestTimer() {
        stopRestTimer()
        withAnimation(.spring()) {
            showRestTimer = false
        }
    }
    
    private func endRestTimer() {
        stopRestTimer()
        
        if currentSettings.restTimerHaptic {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        withAnimation(.spring()) {
            showRestTimer = false
        }
    }
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
    }
}

// MARK: - Workout Header

struct WorkoutHeader: View {
    let workout: ScheduledWorkout
    let currentExerciseIndex: Int
    let totalExercises: Int
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                if let plan = workout.plan {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text("Exercise \(currentExerciseIndex + 1) of \(totalExercises)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Placeholder for menu
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Exercise Info Section

struct ExerciseInfoSection: View {
    let exercise: WorkoutExercise
    let currentSet: Int
    let totalSets: Int
    let completedSets: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Name
            Text(exercise.exerciseDefinition.displayName)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            // Set Progress
            HStack(spacing: 8) {
                ForEach(1...totalSets, id: \.self) { setNum in
                    Circle()
                        .fill(setNum <= completedSets ? Color.green : (setNum == currentSet ? Color.accentColor : Color(.systemGray5)))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("Set \(currentSet) of \(totalSets)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Target Display Section

struct TargetDisplaySection: View {
    let weight: Double
    let reps: Int
    let useMetric: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("TARGET")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(weight))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                
                Text(useMetric ? "kg" : "lbs")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("×")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("\(reps)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

// MARK: - Set Logging Section

struct SetLoggingSection: View {
    @Bindable var set: WorkoutSet
    @Binding var actualWeight: String
    @Binding var actualReps: String
    let onComplete: () -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("LOG YOUR SET")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Input Fields
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $actualWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .weight)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $actualReps)
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .reps)
                }
            }
            
            // Complete Button
            Button {
                focusedField = nil
                onComplete()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    
                    Text("Complete Set")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(actualWeight.isEmpty || actualReps.isEmpty)
            .opacity((actualWeight.isEmpty || actualReps.isEmpty) ? 0.5 : 1.0)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Previous Sets Section

struct PreviousSetsSection: View {
    let sets: [WorkoutSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREVIOUS SETS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(sets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let weight = set.actualWeight, let reps = set.actualReps {
                        Text("\(Int(weight)) lbs × \(reps)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: View {
    @Binding var timeRemaining: TimeInterval
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 24) {
                Text("REST")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ZStack {
                    // Background Circle
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    // Progress Circle
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining / 180.0))
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                    
                    // Time Text
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip Rest")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
            )
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .background(Color.black.opacity(0.3))
        .ignoresSafeArea()
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Complete View

struct WorkoutCompleteView: View {
    let workout: ScheduledWorkout
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Workout Complete!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                if let duration = workout.totalDuration {
                    Text("Duration: \(formatDuration(duration))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%dm %ds", minutes, seconds)
    }
}

// MARK: - Helper Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plan.self, ScheduledWorkout.self, configurations: config)
    
    // Create sample data
    let plan = Plan(name: "Test Plan", planType: .program, totalWeeks: 8)
    let workout = ScheduledWorkout(scheduledDate: Date(), workoutType: .strength)
    workout.plan = plan
    
    container.mainContext.insert(plan)
    container.mainContext.insert(workout)
    
    ActiveWorkoutView(workout: workout)
        .modelContainer(container)
}
