import SwiftUI
import SwiftData

struct ProgramWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    
    @Bindable var program: Program
    @Bindable var trainingDay: TrainingDay
    
    @State private var showCalculator = false
    @State private var calculatorWeight: Double = 0
    @State private var selectedSet: WorkoutSet?
    @State private var canCompleteWorkout = false
    
    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }
    
    // Get the next session for each exercise in this training day
    var exerciseSessions: [(exercise: ProgramExercise, session: ExerciseSession)] {
        var results: [(ProgramExercise, ExerciseSession)] = []
        
        for exercise in trainingDay.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // Find the next uncompleted session for this exercise
            if let session = trainingDay.sessions
                .filter({ session in
                    session.exercise?.id == exercise.id && !session.completed
                })
                    .sorted(by: { $0.sessionNumber < $1.sessionNumber })
                    .first {
                results.append((exercise, session))
            }
        }
        
        return results
    }
    
    var weekNumber: Int {
        exerciseSessions.first?.session.weekNumber ?? program.currentWeek
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(program.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(trainingDay.name)
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    Text("Week \(weekNumber) of \(program.totalWeeks)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Check if we have exercises to display
                if exerciseSessions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Workout Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("All sessions for this workout have been completed.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    // Exercises List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(exerciseSessions, id: \.exercise.id) { item in
                            ExerciseCard(
                                exercise: item.exercise,
                                session: item.session,
                                trackRPE: currentSettings.trackRPE,
                                onTapSet: { set in
                                    selectedSet = set
                                },
                                onLoadWeight: { weight in
                                    calculatorWeight = weight
                                    showCalculator = true
                                }
                            )
                        }
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            if !exerciseSessions.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeWorkout()
                    }
                    .disabled(!canCompleteWorkout)
                }
            }
        }
        .sheet(item: $selectedSet) { set in
            LogSetView(set: set, trackRPE: currentSettings.trackRPE)
                .onDisappear {
                    updateCanComplete()
                }
        }
        .sheet(isPresented: $showCalculator) {
            CalculatorViewWrapper(targetWeight: calculatorWeight)
        }
        .onAppear {
            updateCanComplete()
        }
    }
    
    private func updateCanComplete() {
        // Check if at least one set has been logged for each exercise
        var allExercisesHaveSets = true
        
        for (_, session) in exerciseSessions {
            let completedSets = session.sets.filter { $0.completed }.count
            if completedSets == 0 {
                allExercisesHaveSets = false
                break
            }
        }
        
        canCompleteWorkout = !exerciseSessions.isEmpty && allExercisesHaveSets
    }
    
    private func completeWorkout() {
        // print("\n🏋️ ===== PROGRAM WORKOUT COMPLETION =====")
        // print("Program: \(program.name)")
        // print("Training Day: \(trainingDay.name)")
        // print("program.currentWeek BEFORE: \(program.currentWeek)")
        
        // Get the week number from the first session BEFORE marking complete
        guard let completedWeekNumber = exerciseSessions.first?.session.weekNumber else {
            // print("❌ No sessions to complete")
            dismiss()
            return
        }
        
        // print("Completing week: \(completedWeekNumber)")
        
        // Mark all sessions as completed
        for (_, session) in exerciseSessions {
            session.completed = true
            session.completedDate = Date()
            // print("Marked complete: \(exercise.exerciseName) Week \(session.weekNumber)")
        }
        
        // Check if we should advance the week
        // A week is complete when ALL training days for that week have ALL their sessions done
        let allSessionsThisWeek = program.trainingDays
                    .flatMap { $0.sessions }
                    .filter { $0.weekNumber == completedWeekNumber }
                
                // Group by sessionNumber (actual workout instance) not by training day
                let sessionsByWorkout = Dictionary(grouping: allSessionsThisWeek, by: { $0.sessionNumber })
                
                // print("\n📊 Week \(completedWeekNumber) Status:")
                // print("Total workouts this week: \(sessionsByWorkout.count)")
                
                var completedWorkouts = 0
        for (_, exerciseSessions) in sessionsByWorkout.sorted(by: { $0.key < $1.key }) {
                    let allExercisesComplete = exerciseSessions.allSatisfy { $0.completed }
                    if allExercisesComplete {
                        completedWorkouts += 1
                    }
                    // print("  Workout #\(sessionNum): \(exerciseSessions.filter { $0.completed }.count)/\(exerciseSessions.count) exercises complete - \(allExercisesComplete ? "✅" : "❌")")
                }
                
                let allCompleteThisWeek = completedWorkouts == sessionsByWorkout.count && !sessionsByWorkout.isEmpty
                
                // print("\nCompleted workouts: \(completedWorkouts)/\(sessionsByWorkout.count)")
                // print("All workouts complete this week? \(allCompleteThisWeek)")
                // print("Can advance? currentWeek (\(program.currentWeek)) < totalWeeks (\(program.totalWeeks)): \(program.currentWeek < program.totalWeeks)")
                
                if allCompleteThisWeek && program.currentWeek < program.totalWeeks {
                    // print("✅ ADVANCING: \(program.currentWeek) → \(program.currentWeek + 1)")
                    program.currentWeek += 1
                } else {
                    // print("❌ NOT ADVANCING")
                }
        
        // print("program.currentWeek AFTER: \(program.currentWeek)")
        // print("===== END PROGRAM WORKOUT =====\n")

        // Save before dismiss
        do {
            try context.save()
            // print("✅ Context saved successfully")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        } catch {
            // print("❌ Failed to save: \(error)")
            dismiss()
        }
    }
    // MARK: - Exercise Card
    
    struct ExerciseCard: View {
        @Bindable var exercise: ProgramExercise
        @Bindable var session: ExerciseSession
        let trackRPE: Bool
        let onTapSet: (WorkoutSet) -> Void
        let onLoadWeight: (Double) -> Void
        
        var completedSetsCount: Int {
            session.sets.filter { $0.completed }.count
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Exercise Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exerciseName)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("\(session.plannedSets) sets × \(session.plannedReps) reps @ \(Int(session.plannedWeight)) lbs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { onLoadWeight(session.plannedWeight) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "function")
                            Text("Load")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                    }
                }
                
                Divider()
                
                // Sets
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sets")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(completedSetsCount)/\(session.sets.count) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                        SetRowView(
                            set: set,
                            trackRPE: trackRPE,
                            onEdit: { onTapSet(set) }
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    #Preview {
        Text("ProgramWorkoutView Preview")
    }
}
