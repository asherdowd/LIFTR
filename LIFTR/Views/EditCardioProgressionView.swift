import SwiftUI
import SwiftData

struct EditCardioProgressionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Bindable var progression: CardioProgression
    
    @State private var selectedTab: EditTab = .details
    @State private var showDeleteConfirmation = false
    
    enum EditTab: String, CaseIterable {
        case details = "Details"
        case schedule = "Schedule"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Edit", selection: $selectedTab) {
                ForEach(EditTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            Form {
                switch selectedTab {
                case .details:
                    CardioDetailsSection(progression: progression)
                case .schedule:
                    CardioScheduleSection(progression: progression)
                }
                
                // Danger Zone
                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Progression")
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Progression")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            "Delete Progression",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProgression()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(progression.name)'? This will remove all workout history and cannot be undone.")
        }
    }
    
    private func saveChanges() {
        try? context.save()
    }
    
    private func deleteProgression() {
        context.delete(progression)
        try? context.save()
        dismiss()
    }
}

// MARK: - Details Section

struct CardioDetailsSection: View {
    @Bindable var progression: CardioProgression
    
    var body: some View {
        Section(header: Text("Basic Information")) {
            TextField("Progression Name", text: $progression.name)
            
            HStack {
                Text("Type")
                Spacer()
                Text(progression.cardioType.rawValue)
                    .foregroundColor(.secondary)
            }
        }
        
        // Type-specific details
        switch progression.cardioType {
        case .running:
            Section(header: Text("Running Goals")) {
                if let target = progression.targetDistance {
                    HStack {
                        Text("Target Distance")
                        Spacer()
                        Text(String(format: "%.1f", target))
                            .foregroundColor(.secondary)
                        Text(progression.useMetric ? "km" : "mi")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
        case .calisthenics:
            Section(header: Text("Calisthenics Goals")) {
                if let exercise = progression.exerciseName {
                    HStack {
                        Text("Exercise")
                        Spacer()
                        Text(exercise)
                            .foregroundColor(.secondary)
                    }
                }
                if let target = progression.targetReps {
                    HStack {
                        Text("Target Reps")
                        Spacer()
                        Text("\(target)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
        case .crossfit:
            Section(header: Text("CrossFit WOD")) {
                if let workoutType = progression.workoutType {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(workoutType.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
        case .swimming:
            Section(header: Text("Swimming Goals")) {
                if let target = progression.targetDistance {
                    HStack {
                        Text("Target Distance")
                        Spacer()
                        Text(String(format: "%.1f", target))
                            .foregroundColor(.secondary)
                        Text(progression.useMetric ? "m" : "yd")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
        case .freeCardio:
            EmptyView()
        }
        
        Section(header: Text("Progress")) {
            Stepper("Current Week: \(progression.currentWeek)", value: $progression.currentWeek, in: 1...progression.totalWeeks)
            
            HStack {
                Text("Total Weeks")
                Spacer()
                Text("\(progression.totalWeeks)")
                    .foregroundColor(.secondary)
            }
            
            Picker("Status", selection: $progression.status) {
                Text("Active").tag(ProgressionStatus.active)
                Text("Paused").tag(ProgressionStatus.paused)
                Text("Completed").tag(ProgressionStatus.completed)
            }
        }
        
        Section(header: Text("Notes")) {
            TextEditor(text: Binding(
                get: { progression.notes ?? "" },
                set: { progression.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 100)
        }
    }
}

// MARK: - Schedule Section

struct CardioScheduleSection: View {
    @Bindable var progression: CardioProgression
    @State private var expandedWeek: Int?
    
    var sessionsByWeek: [Int: [CardioSession]] {
        Dictionary(grouping: progression.sessions.sorted { $0.dayNumber < $1.dayNumber }) { $0.weekNumber }
    }
    
    var body: some View {
        Section(header: Text("Weekly Schedule"),
                footer: Text("Tap a week to view sessions. Sessions can be marked complete/incomplete.")) {
            
            ForEach(1...progression.totalWeeks, id: \.self) { week in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedWeek == week },
                        set: { isExpanded in expandedWeek = isExpanded ? week : nil }
                    )
                ) {
                    if let sessions = sessionsByWeek[week] {
                        ForEach(sessions) { session in
                            EditCardioSessionRow(session: session)
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week \(week)")
                                .fontWeight(.semibold)
                            
                            if let firstSession = sessionsByWeek[week]?.first {
                                if let distance = firstSession.plannedDistance {
                                    Text(String(format: "%.1f mi per session", distance))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if let reps = firstSession.plannedReps {
                                    Text("\(reps) reps target")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if let sessions = sessionsByWeek[week] {
                            let completedCount = sessions.filter { $0.completed }.count
                            Text("\(completedCount)/\(sessions.count) done")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Cardio Session Row

struct EditCardioSessionRow: View {
    @Bindable var session: CardioSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: session.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(session.completed ? .green : .secondary)
                    
                    Text("Day \(session.dayNumber)")
                        .fontWeight(.medium)
                }
                
                if let distance = session.plannedDistance {
                    Text(String(format: "Planned: %.1f mi", distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if session.completed, let actual = session.actualDistance {
                    Text(String(format: "Actual: %.1f mi", actual))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $session.completed)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
