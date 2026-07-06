import SwiftUI
import SwiftData

// MARK: - Main Settings View

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var globalSettings: [GlobalWorkoutSettings]
    
    var currentSettings: GlobalWorkoutSettings {
        globalSettings.first ?? GlobalWorkoutSettings()
    }
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section(header: Text("Profile")) {
                    NavigationLink(destination: UserProfileView()) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("User Profile")
                        }
                    }
                }
                
                // Units Preference Section
                Section(header: Text("Preferences")) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.green)
                        Text("Units")
                        Spacer()
                        Text(currentSettings.useMetric ? "Metric (kg)" : "Imperial (lbs)")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleUnits()
                    }
                }
                
                // Workout Settings Section
                Section(header: Text("Workout Settings")) {
                    NavigationLink(destination: WorkoutSettingsView()) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.orange)
                            Text("Workout Preferences")
                        }
                    }
                    
                    NavigationLink(destination: RestTimerSettingsView()) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.purple)
                            Text("Rest Timer")
                        }
                    }
                }
                
                // Integrations Section
                Section(header: Text("Integrations")) {
                    NavigationLink(destination: HealthKitSettingsView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Apple Health")
                        }
                    }
                    
                    NavigationLink(destination: StravaPlaceholderView()) {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(.orange)
                            Text("Strava")
                            Spacer()
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("2.0.0 (Build 10)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func toggleUnits() {
        if let settings = globalSettings.first {
            settings.useMetric.toggle()
            try? context.save()
        } else {
            let newSettings = GlobalWorkoutSettings()
            newSettings.useMetric = true
            context.insert(newSettings)
            try? context.save()
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [User]
    
    @State private var firstName: String = ""
    @State private var email: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $firstName)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section {
                Button("Save Changes") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("User Profile")
        .onAppear {
            if let user = users.first {
                firstName = user.firstName
                email = user.email
            }
        }
    }
    
    private func saveProfile() {
        if let user = users.first {
            user.firstName = firstName
            user.email = email
        } else {
            let newUser = User(firstName: firstName, email: email)
            context.insert(newUser)
        }
        try? context.save()
    }
}

// MARK: - Workout Settings View

struct WorkoutSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [GlobalWorkoutSettings]
    
    @State private var trackRPE: Bool = true
    @State private var adjustmentMode: AdjustmentMode = .prompt
    @State private var excellentThreshold: Double = 100
    @State private var goodThreshold: Double = 90
    @State private var adjustmentThreshold: Double = 75
    @State private var reductionPercent: Double = 10
    @State private var deloadPercent: Double = 20
    @State private var showPresetSheet: Bool = false
    
    var body: some View {
        Form {
            // Preset Profiles Section
            Section {
                Button(action: { showPresetSheet = true }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Load Preset Profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Adjustment Behavior
            Section(header: Text("Workout Adjustments")) {
                Toggle("Track RPE", isOn: $trackRPE)
                
                Picker("Auto-Adjustment", selection: $adjustmentMode) {
                    Text("Ask Me").tag(AdjustmentMode.prompt)
                    Text("Auto-Adjust").tag(AdjustmentMode.autoAdjust)
                    Text("Never Adjust").tag(AdjustmentMode.never)
                }
                .pickerStyle(.menu)
            }
            
            // Performance Thresholds
            Section(header: Text("Performance Thresholds"),
                    footer: Text("Percentage of target reps completed")) {
                
                HStack {
                    Text("Excellent threshold")
                    Spacer()
                    TextField("", value: $excellentThreshold, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("Good threshold")
                    Spacer()
                    TextField("", value: $goodThreshold, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("Adjustment threshold")
                    Spacer()
                    TextField("", value: $adjustmentThreshold, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("Reduction percent")
                    Spacer()
                    TextField("", value: $reductionPercent, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("Deload percent")
                    Spacer()
                    TextField("", value: $deloadPercent, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
            }
            
            // Reset Section
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    resetToDefaults()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Workout Preferences")
        .onAppear { loadSettings() }
        .onChange(of: trackRPE) { _, _ in saveSettings() }
        .onChange(of: adjustmentMode) { _, _ in saveSettings() }
        .onChange(of: excellentThreshold) { _, _ in saveSettings() }
        .onChange(of: goodThreshold) { _, _ in saveSettings() }
        .onChange(of: adjustmentThreshold) { _, _ in saveSettings() }
        .onChange(of: reductionPercent) { _, _ in saveSettings() }
        .onChange(of: deloadPercent) { _, _ in saveSettings() }
        .sheet(isPresented: $showPresetSheet) {
            PresetProfileSheet(onSelect: { preset in
                applyPreset(preset)
                showPresetSheet = false
            })
        }
    }
    
    private func loadSettings() {
        guard let currentSettings = settings.first else {
            let newSettings = GlobalWorkoutSettings()
            context.insert(newSettings)
            try? context.save()
            return
        }
        
        trackRPE = currentSettings.trackRPE
        adjustmentMode = currentSettings.adjustmentMode
        excellentThreshold = Double(currentSettings.excellentThreshold)
        goodThreshold = Double(currentSettings.goodThreshold)
        adjustmentThreshold = Double(currentSettings.adjustmentThreshold)
        reductionPercent = currentSettings.reductionPercent
        deloadPercent = currentSettings.deloadPercent
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.trackRPE = trackRPE
            currentSettings.adjustmentMode = adjustmentMode
            currentSettings.excellentThreshold = Int(excellentThreshold)
            currentSettings.goodThreshold = Int(goodThreshold)
            currentSettings.adjustmentThreshold = Int(adjustmentThreshold)
            currentSettings.reductionPercent = reductionPercent
            currentSettings.deloadPercent = deloadPercent
            try? context.save()
        }
    }
    
    private func resetToDefaults() {
        let defaults = GlobalWorkoutSettings()
        trackRPE = defaults.trackRPE
        adjustmentMode = defaults.adjustmentMode
        excellentThreshold = Double(defaults.excellentThreshold)
        goodThreshold = Double(defaults.goodThreshold)
        adjustmentThreshold = Double(defaults.adjustmentThreshold)
        reductionPercent = defaults.reductionPercent
        deloadPercent = defaults.deloadPercent
        saveSettings()
    }
    
    private func applyPreset(_ preset: PresetProfile) {
        let presetSettings = preset.settings
        trackRPE = presetSettings.trackRPE
        adjustmentMode = presetSettings.adjustmentMode
        excellentThreshold = Double(presetSettings.excellentThreshold)
        goodThreshold = Double(presetSettings.goodThreshold)
        adjustmentThreshold = Double(presetSettings.adjustmentThreshold)
        reductionPercent = presetSettings.reductionPercent
        deloadPercent = presetSettings.deloadPercent
        saveSettings()
    }
}

// MARK: - Preset Profile Sheet

struct PresetProfileSheet: View {
    let onSelect: (PresetProfile) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedPreset: PresetProfile = .moderate
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a preset profile to quickly configure your workout settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(spacing: 16) {
                    PresetOption(
                        preset: .conservative,
                        isSelected: selectedPreset == .conservative,
                        onTap: { selectedPreset = .conservative }
                    )
                    
                    PresetOption(
                        preset: .moderate,
                        isSelected: selectedPreset == .moderate,
                        onTap: { selectedPreset = .moderate }
                    )
                    
                    PresetOption(
                        preset: .aggressive,
                        isSelected: selectedPreset == .aggressive,
                        onTap: { selectedPreset = .aggressive }
                    )
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    onSelect(selectedPreset)
                    dismiss()
                }) {
                    Text("Apply Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Load Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PresetOption: View {
    let preset: PresetProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(preset.title)
                            .font(.headline)
                        if preset == .moderate {
                            Text("Recommended")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(preset.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(preset.goodFor)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Integrations Placeholder

struct StravaPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Strava Integration")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Coming in a future update")
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Strava")
    }
}
