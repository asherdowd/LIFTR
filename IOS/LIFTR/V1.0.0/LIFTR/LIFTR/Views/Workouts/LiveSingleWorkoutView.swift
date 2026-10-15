import SwiftUI
import SwiftData

struct LiveSingleWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]

    @Bindable var session: ExerciseSession
    @Bindable var workoutExercise: WorkoutExercise
    var onComplete: () -> Void = {}

    @State private var selectedSet: WorkoutSet?
    @State private var showCalculator = false

    private var unitLabel: String {
        globalSettings.first?.useMetric == true ? "kg" : "lbs"
    }

    private var completedSetsCount: Int {
        session.sets.filter { $0.completed }.count
    }

    private var lastCompletedWeight: Double? {
        session.sets
            .filter { $0.completed }
            .sorted { $0.setNumber < $1.setNumber }
            .last?
            .actualWeight
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 8) {
                    Text(workoutExercise.exercise.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(Int(session.plannedWeight)) \(unitLabel)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Calculator button
                Button(action: { showCalculator = true }) {
                    HStack {
                        Image(systemName: "function")
                        Text("Plate Calculator")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Sets list
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sets")
                            .font(.headline)
                        Spacer()
                        Text("\(completedSetsCount) completed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    if session.sets.isEmpty {
                        Text("Tap 'Add Set' to log your first set.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                            SetRowView(
                                set: set,
                                trackRPE: globalSettings.first?.trackRPE ?? false,
                                onEdit: { selectedSet = set }
                            )
                        }
                    }
                }

                // Add Set button
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Workout")
        .onAppear {
            // V5: opening a session starts its clock (first time only).
            if session.startTime == nil && !session.completed {
                session.startTime = Date()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Complete") {
                    completeWorkout()
                }
                .disabled(completedSetsCount == 0)
                .fontWeight(.semibold)
            }
        }
        .sheet(item: $selectedSet) { set in
            LogSetView(
                set: set,
                trackRPE: globalSettings.first?.trackRPE ?? false,
                exerciseName: workoutExercise.exercise.name,
                totalSets: session.sets.count
            )
        }
        .sheet(isPresented: $showCalculator) {
            CalculatorViewWrapper(targetWeight: session.plannedWeight)
        }
    }

    private func addSet() {
        let setNumber = session.sets.count + 1
        let prefillWeight = lastCompletedWeight ?? session.plannedWeight

        let workoutSet = WorkoutSet(
            setNumber: setNumber,
            targetReps: 5,
            targetWeight: prefillWeight
        )
        workoutSet.exerciseSession = session
        session.sets.append(workoutSet)
        context.insert(workoutSet)

        try? context.save()

        selectedSet = workoutSet
    }

    private func completeWorkout() {
        session.completed = true
        session.completedDate = Date()
        session.plannedSets = completedSetsCount
        DeloadAdjustmentService.checkAndAdvanceWeek(session: session, workoutExercise: workoutExercise)
        try? context.save()
        onComplete()
        dismiss()
    }
}
