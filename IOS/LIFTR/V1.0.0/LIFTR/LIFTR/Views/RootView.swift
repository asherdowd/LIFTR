import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var progressions: [Progression]
    @Query private var programExercises: [ProgramExercise]
    @Query private var exerciseSettings: [ExerciseProgressionSettings]
    @Query private var cardioProgressions: [CardioProgression]

    private var unresolvedExerciseNames: [String] {
        var names = Set<String>()
        for p in progressions where p.exercise == nil {
            names.insert(p.exerciseName)
        }
        for pe in programExercises where pe.exercise == nil {
            names.insert(pe.exerciseName)
        }
        for es in exerciseSettings where es.exercise == nil {
            names.insert(es.exerciseName)
        }
        for cp in cardioProgressions where cp.exercise == nil {
            if let name = cp.exerciseName {
                names.insert(name)
            }
        }
        return Array(names).sorted()
    }

    var body: some View {
        if unresolvedExerciseNames.isEmpty {
            ContentView()
        } else {
            ExerciseReconciliationView(unresolvedNames: unresolvedExerciseNames)
        }
    }
}
