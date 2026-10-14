import SwiftUI

struct ContentView: View {
    private enum AppTab: Hashable {
        case main, inventory, calculator, workouts, analytics
    }

    @State private var selectedTab: AppTab = .main

    var body: some View {
        TabView(selection: $selectedTab) {
            MainViewWithSettings(onStartWorkout: { selectedTab = .workouts })
                .tabItem { Label("Main", systemImage: "house") }
                .tag(AppTab.main)
            
            InventoryView()
                .tabItem { Label("Inventory", systemImage: "cube.box") }
                .tag(AppTab.inventory)
            
            CalculatorView()
                .tabItem { Label("Calculator", systemImage: "function") }
                .tag(AppTab.calculator)
            
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "calendar") }
                .tag(AppTab.workouts)
            
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar") }
                .tag(AppTab.analytics)
            // WorkoutSessionTestLauncher()
               // .tabItem { Label("Tests", systemImage: "ladybug") }
        }
    }
}

// MARK: - Main View with Settings Button

struct MainViewWithSettings: View {
    var onStartWorkout: (() -> Void)? = nil
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            MainView(onStartWorkout: onStartWorkout)
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
