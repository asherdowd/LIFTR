import SwiftUI
import SwiftData

struct RestTimerSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [GlobalProgressionSettings]
    
    @State private var defaultRestTime: Double = 180
    @State private var autoStartRestTimer: Bool = true
    @State private var restTimerSound: Bool = true
    @State private var restTimerHaptic: Bool = true
    
    var body: some View {
        Form {
            RestTimerSection(
                defaultRestTime: $defaultRestTime,
                autoStartRestTimer: $autoStartRestTimer,
                restTimerSound: $restTimerSound,
                restTimerHaptic: $restTimerHaptic
            )
        }
        .navigationTitle("Rest Timer")
        .onAppear { loadSettings() }
        .onChange(of: defaultRestTime) { _, _ in saveSettings() }
        .onChange(of: autoStartRestTimer) { _, _ in saveSettings() }
        .onChange(of: restTimerSound) { _, _ in saveSettings() }
        .onChange(of: restTimerHaptic) { _, _ in saveSettings() }
    }
    
    private func loadSettings() {
        guard let currentSettings = settings.first else {
            let newSettings = GlobalProgressionSettings()
            context.insert(newSettings)
            try? context.save()
            return
        }
        defaultRestTime = Double(currentSettings.defaultRestTime)
        autoStartRestTimer = currentSettings.autoStartRestTimer
        restTimerSound = currentSettings.restTimerSound
        restTimerHaptic = currentSettings.restTimerHaptic
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.defaultRestTime = Int(defaultRestTime)
            currentSettings.autoStartRestTimer = autoStartRestTimer
            currentSettings.restTimerSound = restTimerSound
            currentSettings.restTimerHaptic = restTimerHaptic
            try? context.save()
        }
    }
}
