import SwiftUI
import SwiftData

@main
struct LiftrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            // User & Settings
            User.self,
            GlobalProgressionSettings.self,
            ExerciseProgressionSettings.self,
            
            // Equipment Inventory
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            
            // Strength Training (Legacy Progression System)
            Progression.self,
            WorkoutSession.self,
            WorkoutSet.self,  // Shared: used by both Progression and future Program systems
            
            // Cardio Training
            CardioProgression.self,
            CardioSession.self
        ])
    }
}
