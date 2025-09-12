import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [User]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hello, \(users.first?.firstName ?? "Guest")!")
                    .font(.largeTitle)
                    .bold()
                
                Text("Recent Workouts")
                    .font(.headline)
                
                List {
                    Text("Deadlift - 405 lbs")
                    Text("Squat - 315 lbs")
                    Text("Bench - 225 lbs")
                }
            }
            .padding()
            .navigationTitle("Main")
        }
    }
}
