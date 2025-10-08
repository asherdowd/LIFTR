import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainViewWithSettings()
                .tabItem { Label("Main", systemImage: "house") }
            
            InventoryView()
                .tabItem { Label("Inventory", systemImage: "cube.box") }
            
            CalculatorView()
                .tabItem { Label("Calculator", systemImage: "function") }
            
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "calendar") }
            
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar") }
            WorkoutSessionTestLauncher()
                .tabItem { Label("Tests", systemImage: "ladybug") }
        }
    }
}

// MARK: - Main View with Settings Button

struct MainViewWithSettings: View {
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            MainView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
