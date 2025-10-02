import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainView()
                .tabItem { Label("Home", systemImage: "house") }
            
            InventoryView()
                .tabItem { Label("Inventory", systemImage: "cube.box") }
            
            CalculatorView()
                .tabItem { Label("Calculator", systemImage: "function") }
            
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "calendar") }
            
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar") }
        }
    }
}
