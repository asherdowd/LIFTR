import SwiftUI
import SwiftData

@main
struct LiftrApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Use versioned schema with migration plan
            let schema = Schema(versionedSchema: CurrentSchema.self)
            let modelConfiguration = ModelConfiguration(schema: schema)
            
            container = try ModelContainer(
                for: schema,
                migrationPlan: LIFTRMigrationPlan.self,
                configurations: [modelConfiguration]
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
