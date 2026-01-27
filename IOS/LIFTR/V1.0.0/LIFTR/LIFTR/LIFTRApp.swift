import SwiftUI
import SwiftData

@main
struct LiftrApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Initialize the container with individual types (not array)
            container = try ModelContainer(
                for: User.self,
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
            )
            
            // Run migration checks on startup
            let context = container.mainContext
            MigrationService.performStartupChecks(context: context)
            
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
