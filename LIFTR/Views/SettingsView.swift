import SwiftUI
import SwiftData

// MARK: - Main Settings View

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var globalSettings: [GlobalProgressionSettings]
    @Query private var exerciseSettings: [ExerciseProgressionSettings]
    
    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
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
                
                // Progression Rules Section
                Section(header: Text("Workout Planning")) {
                    NavigationLink(destination: GlobalProgressionSettingsView()) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.orange)
                            Text("Progression Rules")
                        }
                    }
                    
                    NavigationLink(destination: ExerciseRulesListView()) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.purple)
                            Text("Exercise-Specific Rules")
                            Spacer()
                            Text("\(exerciseSettings.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Integrations Section
                Section(header: Text("Integrations")) {
                    NavigationLink(destination: IntegrationsView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Apple Health")
                        }
                    }
                    
                    NavigationLink(destination: IntegrationsView()) {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(.orange)
                            Text("Strava")
                        }
                    }
                }
                // Support Section
                Section(header: Text("Support")) {
                    NavigationLink(destination: SupportView()) {
                        HStack {
                            Image(systemName: "lifepreserver.fill")
                                .foregroundColor(.green)
                            Text("Report an Issue")
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
                        Text("1.0.0")
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
            let newSettings = GlobalProgressionSettings()
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

// MARK: - Global Progression Settings View

struct GlobalProgressionSettingsView: View {
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
    @State private var trackRPE: Bool = false
    @State private var allowMidWorkoutAdjustments: Bool = true
    @State private var autoDeloadEnabled: Bool = false
    @State private var autoDeloadFrequency: Double = 8
    @State private var showPresetSheet: Bool = false
    @State private var upcomingWorkoutsDays: Double = 7
    
    var body: some View {
        Form {
            // Preset Profiles
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
            
            // Auto-Adjustment Behavior
            Section(header: Text("Auto-Adjustment Behavior")) {
                Picker("Adjustment Mode", selection: $adjustmentMode) {
                    Text("Always prompt me").tag(AdjustmentMode.prompt)
                    Text("Auto-adjust").tag(AdjustmentMode.autoAdjust)
                    Text("Never adjust").tag(AdjustmentMode.never)
                }
                .pickerStyle(.menu)
            }
            
            // Performance Thresholds
            Section(header: Text("Performance Thresholds"),
                    footer: Text("Percentage of target reps completed")) {
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Excellent (Continue as planned)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        Text("\(Int(excellentThreshold))%")
                        Slider(value: $excellentThreshold, in: 80...100, step: 1)
                        Text("100%")
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Good (Repeat current weight)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        Text("\(Int(goodThreshold))%")
                        Slider(value: $goodThreshold, in: 60...90, step: 1)
                        Text("\(Int(excellentThreshold) - 1)%")
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Needs Adjustment (Reduce weight)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        Text("\(Int(adjustmentThreshold))%")
                        Slider(value: $adjustmentThreshold, in: 40...80, step: 1)
                        Text("\(Int(goodThreshold) - 1)%")
                    }
                    
                    HStack {
                        Text("Reduce by:")
                        Spacer()
                        Text("\(String(format: "%.1f", reductionPercent))%")
                    }
                    Slider(value: $reductionPercent, in: 2...10, step: 0.5)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Poor Performance (Deload)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        Text("0%")
                        Text("-")
                        Text("\(Int(adjustmentThreshold) - 1)%")
                    }
                    
                    HStack {
                        Text("Deload by:")
                        Spacer()
                        Text("\(String(format: "%.1f", deloadPercent))%")
                    }
                    Slider(value: $deloadPercent, in: 5...20, step: 0.5)
                }
            }
            
            // Progression Increments
            Section(header: Text("Progression Increments")) {
                HStack {
                    Text("Lower body")
                    Spacer()
                    TextField("", value: $lowerBodyIncrement, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("lbs")
                }
                
                HStack {
                    Text("Upper body")
                    Spacer()
                    TextField("", value: $upperBodyIncrement, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("lbs")
                }
            }
            
            // Advanced Options
            Section(header: Text("Advanced Options")) {
                Toggle("Track RPE (Rate of Perceived Effort)", isOn: $trackRPE)
                
                Toggle("Allow mid-workout adjustments", isOn: $allowMidWorkoutAdjustments)
                
                Toggle("Auto-suggest deload", isOn: $autoDeloadEnabled)
                
                if autoDeloadEnabled {
                    HStack {
                        Text("Every")
                        Spacer()
                        TextField("", value: $autoDeloadFrequency, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("weeks")
                    }
                }
            }
            
            
            // Home Screen Options
                        Section(header: Text("Home Screen"),
                                footer: Text("Number of days to show in the 'Upcoming Workouts' section")) {
                            HStack {
                                Text("Show workouts for next")
                                Spacer()
                                TextField("", value: $upcomingWorkoutsDays, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                Text("days")
                            }
                        }
            // Reset
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    resetToDefaults()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Progression Rules")
        .onAppear {
            loadSettings()
        }
        .onChange(of: adjustmentMode) { _, _ in saveSettings() }
        .onChange(of: excellentThreshold) { _, _ in saveSettings() }
        .onChange(of: goodThreshold) { _, _ in saveSettings() }
        .onChange(of: adjustmentThreshold) { _, _ in saveSettings() }
        .onChange(of: reductionPercent) { _, _ in saveSettings() }
        .onChange(of: deloadPercent) { _, _ in saveSettings() }
        .onChange(of: lowerBodyIncrement) { _, _ in saveSettings() }
        .onChange(of: upperBodyIncrement) { _, _ in saveSettings() }
        .onChange(of: trackRPE) { _, _ in saveSettings() }
        .onChange(of: allowMidWorkoutAdjustments) { _, _ in saveSettings() }
        .onChange(of: autoDeloadEnabled) { _, _ in saveSettings() }
        .onChange(of: autoDeloadFrequency) { _, _ in saveSettings() }
        .onChange(of: upcomingWorkoutsDays) { _, _ in saveSettings() }
        .sheet(isPresented: $showPresetSheet) {
            PresetProfileSheet(onSelect: { preset in
                applyPreset(preset)
                showPresetSheet = false
            })
        }
    }
    
    private func loadSettings() {
        guard let currentSettings = settings.first else {
            // Create default settings
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
        trackRPE = currentSettings.trackRPE
        allowMidWorkoutAdjustments = currentSettings.allowMidWorkoutAdjustments
        autoDeloadEnabled = currentSettings.autoDeloadEnabled
        autoDeloadFrequency = Double(currentSettings.autoDeloadFrequency)
        upcomingWorkoutsDays = Double(currentSettings.upcomingWorkoutsDays)
    }
    
    private func saveSettings() {
        if let currentSettings = settings.first {
            currentSettings.adjustmentMode = adjustmentMode
            currentSettings.excellentThreshold = Int(excellentThreshold)
            currentSettings.goodThreshold = Int(goodThreshold)
            currentSettings.adjustmentThreshold = Int(adjustmentThreshold)
            currentSettings.upcomingWorkoutsDays = Int(upcomingWorkoutsDays)
            currentSettings.reductionPercent = reductionPercent
            currentSettings.deloadPercent = deloadPercent
            currentSettings.lowerBodyIncrement = lowerBodyIncrement
            currentSettings.upperBodyIncrement = upperBodyIncrement
            currentSettings.trackRPE = trackRPE
            currentSettings.allowMidWorkoutAdjustments = allowMidWorkoutAdjustments
            currentSettings.autoDeloadEnabled = autoDeloadEnabled
            currentSettings.autoDeloadFrequency = Int(autoDeloadFrequency)
            try? context.save()
        }
    }
    
    private func resetToDefaults() {
        let defaults = GlobalProgressionSettings()
        adjustmentMode = defaults.adjustmentMode
        excellentThreshold = Double(defaults.excellentThreshold)
        goodThreshold = Double(defaults.goodThreshold)
        adjustmentThreshold = Double(defaults.adjustmentThreshold)
        upcomingWorkoutsDays = Double(defaults.upcomingWorkoutsDays)
        reductionPercent = defaults.reductionPercent
        deloadPercent = defaults.deloadPercent
        lowerBodyIncrement = defaults.lowerBodyIncrement
        upperBodyIncrement = defaults.upperBodyIncrement
        trackRPE = defaults.trackRPE
        allowMidWorkoutAdjustments = defaults.allowMidWorkoutAdjustments
        autoDeloadEnabled = defaults.autoDeloadEnabled
        autoDeloadFrequency = Double(defaults.autoDeloadFrequency)
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

// MARK: - Preset Profile Sheet

struct PresetProfileSheet: View {
    let onSelect: (PresetProfile) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedPreset: PresetProfile = .moderate
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a preset profile to quickly configure your progression rules")
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

// MARK: - Exercise Rules List View

struct ExerciseRulesListView: View {
    @Environment(\.modelContext) private var context
    @Query private var exerciseSettings: [ExerciseProgressionSettings]
    
    var body: some View {
        List {
            if exerciseSettings.isEmpty {
                Section {
                    Text("No exercise-specific rules yet")
                        .foregroundColor(.secondary)
                    Text("Exercise rules will appear here once you create progressions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(exerciseSettings) { setting in
                    NavigationLink(destination: ExerciseSettingsDetailView(exerciseSetting: setting)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(setting.exerciseName)
                                    .font(.headline)
                                
                                if setting.useCustomRules {
                                    HStack(spacing: 4) {
                                        Image(systemName: "gear")
                                            .font(.caption)
                                        Text("Custom rules active")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.orange)
                                } else {
                                    Text("Using global defaults")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: deleteSettings)
            }
        }
        .navigationTitle("Exercise Rules")
    }
    
    private func deleteSettings(at offsets: IndexSet) {
        for index in offsets {
            context.delete(exerciseSettings[index])
        }
        try? context.save()
    }
}

// MARK: - Exercise Settings Detail View

struct ExerciseSettingsDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var exerciseSetting: ExerciseProgressionSettings
    
    var body: some View {
        Form {
            Section {
                Toggle("Use custom rules for \(exerciseSetting.exerciseName)", isOn: $exerciseSetting.useCustomRules)
            }
            
            if exerciseSetting.useCustomRules {
                Section(header: Text("Performance Thresholds")) {
                    HStack {
                        Text("Excellent threshold")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.excellentThreshold ?? 90 },
                            set: { exerciseSetting.excellentThreshold = $0 }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("%")
                    }
                    
                    HStack {
                        Text("Good threshold")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.goodThreshold ?? 75 },
                            set: { exerciseSetting.goodThreshold = $0 }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("%")
                    }
                    
                    HStack {
                        Text("Adjustment threshold")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.adjustmentThreshold ?? 50 },
                            set: { exerciseSetting.adjustmentThreshold = $0 }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("%")
                    }
                    
                    HStack {
                        Text("Reduction percent")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.reductionPercent ?? 5.0 },
                            set: { exerciseSetting.reductionPercent = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("%")
                    }
                    
                    HStack {
                        Text("Deload percent")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.deloadPercent ?? 10.0 },
                            set: { exerciseSetting.deloadPercent = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("%")
                    }
                }
                
                Section(header: Text("Progression")) {
                    HStack {
                        Text("Weight increment")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.weightIncrement ?? 5.0 },
                            set: { exerciseSetting.weightIncrement = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Auto-deload frequency")
                        Spacer()
                        TextField("", value: Binding(
                            get: { exerciseSetting.autoDeloadFrequency ?? 8 },
                            set: { exerciseSetting.autoDeloadFrequency = $0 }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("weeks")
                    }
                }
            } else {
                Section {
                    Text("This exercise is using the global default rules. Enable custom rules above to override.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(exerciseSetting.exerciseName)
        .onChange(of: exerciseSetting.useCustomRules) { _, _ in
            try? context.save()
        }
    }
}

// MARK: - Integrations View (Placeholder)

struct IntegrationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Integrations Coming Soon")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Apple Health and Strava integrations will be available in a future update.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
        }
        .padding()
    }
}
