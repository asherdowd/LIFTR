import SwiftUI
import SwiftData

struct RestTimerSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [GlobalWorkoutSettings]
    
    @State private var defaultRestTime: Double = 180
    @State private var autoStartRestTimer: Bool = true
    @State private var restTimerAfterWarmups: Bool = false
    @State private var restTimerSound: Bool = true
    @State private var restTimerHaptic: Bool = true
    
    var body: some View {
        Form {
            Section(header: Text("Default Rest Time")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(Int(defaultRestTime / 60)) minutes \(Int(defaultRestTime) % 60) seconds")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Slider(value: $defaultRestTime, in: 30...600, step: 15)
                        .onChange(of: defaultRestTime) { _, _ in saveSettings() }
                }
            }
            
            Section(header: Text("Behavior")) {
                Toggle("Auto-start timer after sets", isOn: $autoStartRestTimer)
                    .onChange(of: autoStartRestTimer) { _, _ in saveSettings() }
                
                Toggle("Timer after warmup sets", isOn: $restTimerAfterWarmups)
                    .onChange(of: restTimerAfterWarmups) { _, _ in saveSettings() }
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Sound", isOn: $restTimerSound)
                    .onChange(of: restTimerSound) { _, _ in saveSettings() }
                
                Toggle("Haptic feedback", isOn: $restTimerHaptic)
                    .onChange(of: restTimerHaptic) { _, _ in saveSettings() }
            }
            
            Section {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Rest Timer")
        .onAppear { loadSettings() }
    }
    
    private func loadSettings() {
        guard let currentSettings = settings.first else {
            let newSettings = GlobalWorkoutSettings()
            context.insert(newSettings)
            try? context.save()
            return
        }
        defaultRestTime = Double(currentSettings.defaultRestTime)
        autoStartRestTimer = currentSettings.autoStartRestTimer
        restTimerAfterWarmups = currentSettings.restTimerAfterWarmups
        restTimerSound = currentSettings.restTimerSound
        restTimerHaptic = currentSettings.restTimerHaptic
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.defaultRestTime = Int(defaultRestTime)
            currentSettings.autoStartRestTimer = autoStartRestTimer
            currentSettings.restTimerAfterWarmups = restTimerAfterWarmups
            currentSettings.restTimerSound = restTimerSound
            currentSettings.restTimerHaptic = restTimerHaptic
            try? context.save()
        }
    }
    
    private func resetToDefaults() {
        defaultRestTime = 180
        autoStartRestTimer = true
        restTimerAfterWarmups = false
        restTimerSound = true
        restTimerHaptic = true
        saveSettings()
    }
}
