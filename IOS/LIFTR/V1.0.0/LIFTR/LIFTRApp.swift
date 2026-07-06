import SwiftUI
import SwiftData

@main
struct LiftrApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Use SchemaV2 (new unified architecture)
            let schema = Schema(versionedSchema: SchemaV2.self)
            let modelConfiguration = ModelConfiguration(schema: schema)
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Fresh V2 database - no migration needed
            
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
