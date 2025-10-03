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
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            GlobalProgressionSettings.self,
            ExerciseProgressionSettings.self,
            Progression.self,
            WorkoutSession.self,
            WorkoutSet.self,
            CardioProgression.self,
            CardioSession.self
        ])
    }
}
