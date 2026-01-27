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
    var body: some View {
        List {
            NavigationLink("Basic Settings", destination: BasicProgressionSettingsView())
            NavigationLink("Advanced Settings", destination: AdvancedProgressionSettingsView())
            NavigationLink("Rest Timer", destination: RestTimerSettingsView())
        }
        .navigationTitle("Progression Rules")
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
