import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayViewWithSettings()
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.clock")
                }
            
            PlansView() 
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.clipboard")
                }
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "cube.box")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Today View with Settings in Toolbar

struct TodayViewWithSettings: View {
    var body: some View {
        NavigationStack {
            TodayView()
        }
    }
}
