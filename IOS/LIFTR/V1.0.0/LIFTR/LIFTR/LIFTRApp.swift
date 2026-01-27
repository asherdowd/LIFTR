import SwiftUI
import SwiftData

@main
struct LiftrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            User.self,
            GlobalProgressionSettings.self,
            ExerciseProgressionSettings.self,
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            Program.self,
            TrainingDay.self,
            ProgramExercise.self,
            ExerciseSession.self,
            Progression.self,
            WorkoutSession.self,
            WorkoutSet.self,
            CardioProgression.self,
            CardioSession.self
        ])
    }
}
