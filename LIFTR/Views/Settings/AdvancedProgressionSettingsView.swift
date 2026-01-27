import SwiftUI
import SwiftData

struct AdvancedProgressionSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [GlobalProgressionSettings]
    
    @State private var trackRPE: Bool = false
    @State private var allowMidWorkoutAdjustments: Bool = true
    @State private var autoDeloadEnabled: Bool = false
    @State private var autoDeloadFrequency: Double = 8
    @State private var upcomingWorkoutsDays: Double = 7
    
    var body: some View {
        Form {
            AdvancedOptionsSection(
                trackRPE: $trackRPE,
                allowMidWorkoutAdjustments: $allowMidWorkoutAdjustments,
                autoDeloadEnabled: $autoDeloadEnabled,
                autoDeloadFrequency: $autoDeloadFrequency
            )
            HomeScreenSection(upcomingWorkoutsDays: $upcomingWorkoutsDays)
        }
        .navigationTitle("Advanced Settings")
        .onAppear { loadSettings() }
        .onChange(of: trackRPE) { _, _ in saveSettings() }
        .onChange(of: allowMidWorkoutAdjustments) { _, _ in saveSettings() }
        .onChange(of: autoDeloadEnabled) { _, _ in saveSettings() }
        .onChange(of: autoDeloadFrequency) { _, _ in saveSettings() }
        .onChange(of: upcomingWorkoutsDays) { _, _ in saveSettings() }
    }
    
    private func loadSettings() {
        guard let currentSettings = settings.first else {
            let newSettings = GlobalProgressionSettings()
            context.insert(newSettings)
            try? context.save()
            return
        }
        trackRPE = currentSettings.trackRPE
        allowMidWorkoutAdjustments = currentSettings.allowMidWorkoutAdjustments
        autoDeloadEnabled = currentSettings.autoDeloadEnabled
        autoDeloadFrequency = Double(currentSettings.autoDeloadFrequency)
        upcomingWorkoutsDays = Double(currentSettings.upcomingWorkoutsDays)
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.trackRPE = trackRPE
            currentSettings.allowMidWorkoutAdjustments = allowMidWorkoutAdjustments
            currentSettings.autoDeloadEnabled = autoDeloadEnabled
            currentSettings.autoDeloadFrequency = Int(autoDeloadFrequency)
            currentSettings.upcomingWorkoutsDays = Int(upcomingWorkoutsDays)
            try? context.save()
        }
    }
}
