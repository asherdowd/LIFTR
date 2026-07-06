import SwiftUI
import SwiftData

struct ExerciseReconciliationView: View {
    @Environment(\.modelContext) private var context
    @Query private var progressions: [Progression]
    @Query private var programExercises: [ProgramExercise]
    @Query private var exerciseSettings: [ExerciseProgressionSettings]
    @Query private var cardioProgressions: [CardioProgression]

    let unresolvedNames: [String]
    @State private var selections: [String: ExerciseCoreType] = [:]

    private var allSelected: Bool {
        unresolvedNames.allSatisfy { selections[$0] != nil }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Up Your Exercises"),
                        footer: Text("Assign each existing exercise name to a core type. This only needs to be done once.")) {
                    ForEach(unresolvedNames, id: \.self) { name in
                        Picker(name, selection: Binding(
                            get: { selections[name] },
                            set: { selections[name] = $0 }
                        )) {
                            Text("Select...").tag(ExerciseCoreType?.none)
                            ForEach(ExerciseCoreType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(ExerciseCoreType?.some(type))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Confirm Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        applySelections()
                    }
                    .disabled(!allSelected)
                }
            }
        }
    }

    private func applySelections() {
        for name in unresolvedNames {
            guard let coreType = selections[name] else { continue }
            let exercise = Exercise(name: name, coreType: coreType)
            context.insert(exercise)

            for p in progressions where p.exerciseName == name && p.exercise == nil {
                p.exercise = exercise
            }
            for pe in programExercises where pe.exerciseName == name && pe.exercise == nil {
                pe.exercise = exercise
            }
            for es in exerciseSettings where es.exerciseName == name && es.exercise == nil {
                es.exercise = exercise
            }
            for cp in cardioProgressions where cp.exerciseName == name && cp.exercise == nil {
                cp.exercise = exercise
            }
        }
        try? context.save()
    }
}
