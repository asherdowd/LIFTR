import SwiftUI
import SwiftData

struct BasicProgressionSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [GlobalProgressionSettings]
    
    @State private var adjustmentMode: AdjustmentMode = .prompt
    @State private var excellentThreshold: Double = 90
    @State private var goodThreshold: Double = 75
    @State private var adjustmentThreshold: Double = 50
    @State private var reductionPercent: Double = 5.0
    @State private var deloadPercent: Double = 10.0
    @State private var lowerBodyIncrement: Double = 5.0
    @State private var upperBodyIncrement: Double = 2.5
    @State private var showPresetSheet: Bool = false
    
    var body: some View {
        Form {
            PresetSection(showPresetSheet: $showPresetSheet)
            AdjustmentBehaviorSection(adjustmentMode: $adjustmentMode)
            PerformanceThresholdsSection(
                excellentThreshold: $excellentThreshold,
                goodThreshold: $goodThreshold,
                adjustmentThreshold: $adjustmentThreshold,
                reductionPercent: $reductionPercent,
                deloadPercent: $deloadPercent
            )
            ProgressionIncrementsSection(
                lowerBodyIncrement: $lowerBodyIncrement,
                upperBodyIncrement: $upperBodyIncrement
            )
            
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    resetToDefaults()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Basic Settings")
        .onAppear { loadSettings() }
        .onChange(of: adjustmentMode) { _, _ in saveSettings() }
        .onChange(of: excellentThreshold) { _, _ in saveSettings() }
        .onChange(of: goodThreshold) { _, _ in saveSettings() }
        .onChange(of: adjustmentThreshold) { _, _ in saveSettings() }
        .onChange(of: reductionPercent) { _, _ in saveSettings() }
        .onChange(of: deloadPercent) { _, _ in saveSettings() }
        .onChange(of: lowerBodyIncrement) { _, _ in saveSettings() }
        .onChange(of: upperBodyIncrement) { _, _ in saveSettings() }
        .sheet(isPresented: $showPresetSheet) {
            PresetProfileSheet(onSelect: { preset in
                applyPreset(preset)
                showPresetSheet = false
            })
        }
    }
    
    private func loadSettings() {
        guard let currentSettings = settings.first else {
            let newSettings = GlobalProgressionSettings()
            context.insert(newSettings)
            try? context.save()
            return
        }
        adjustmentMode = currentSettings.adjustmentMode
        excellentThreshold = Double(currentSettings.excellentThreshold)
        goodThreshold = Double(currentSettings.goodThreshold)
        adjustmentThreshold = Double(currentSettings.adjustmentThreshold)
        reductionPercent = currentSettings.reductionPercent
        deloadPercent = currentSettings.deloadPercent
        lowerBodyIncrement = currentSettings.lowerBodyIncrement
        upperBodyIncrement = currentSettings.upperBodyIncrement
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.adjustmentMode = adjustmentMode
            currentSettings.excellentThreshold = Int(excellentThreshold)
            currentSettings.goodThreshold = Int(goodThreshold)
            currentSettings.adjustmentThreshold = Int(adjustmentThreshold)
            currentSettings.reductionPercent = reductionPercent
            currentSettings.deloadPercent = deloadPercent
            currentSettings.lowerBodyIncrement = lowerBodyIncrement
            currentSettings.upperBodyIncrement = upperBodyIncrement
            try? context.save()
        }
    }
    
    private func resetToDefaults() {
        let defaults = GlobalProgressionSettings()
        adjustmentMode = defaults.adjustmentMode
        excellentThreshold = Double(defaults.excellentThreshold)
        goodThreshold = Double(defaults.goodThreshold)
        adjustmentThreshold = Double(defaults.adjustmentThreshold)
        reductionPercent = defaults.reductionPercent
        deloadPercent = defaults.deloadPercent
        lowerBodyIncrement = defaults.lowerBodyIncrement
        upperBodyIncrement = defaults.upperBodyIncrement
        saveSettings()
    }
    
    private func applyPreset(_ preset: PresetProfile) {
        let presetSettings = preset.settings
        adjustmentMode = presetSettings.adjustmentMode
        excellentThreshold = Double(presetSettings.excellentThreshold)
        goodThreshold = Double(presetSettings.goodThreshold)
        adjustmentThreshold = Double(presetSettings.adjustmentThreshold)
        reductionPercent = presetSettings.reductionPercent
        deloadPercent = presetSettings.deloadPercent
        lowerBodyIncrement = presetSettings.lowerBodyIncrement
        upperBodyIncrement = presetSettings.upperBodyIncrement
        saveSettings()
    }
}
