import SwiftUI
import SwiftData

struct EditProgressionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Bindable var progression: Progression
    
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
                    DetailsSection(progression: progression)
                case .schedule:
                    ScheduleSection(progression: progression)
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
            Text("Are you sure you want to delete '\(progression.exerciseName)'? This will remove all workout history and cannot be undone.")
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

struct DetailsSection: View {
    @Bindable var progression: Progression
    
    var body: some View {
        Section(header: Text("Basic Information")) {
            HStack {
                Text("Exercise")
                Spacer()
                Text(progression.exerciseName)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Template")
                Spacer()
                Text(progression.templateType.rawValue)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Style")
                Spacer()
                Text(progression.progressionStyle.rawValue)
                    .foregroundColor(.secondary)
            }
        }
        
        Section(header: Text("Weight Parameters")) {
            HStack {
                Text("Current Max")
                Spacer()
                TextField("", value: $progression.currentMax, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("lbs")
            }
            
            HStack {
                Text("Target Max")
                Spacer()
                TextField("", value: $progression.targetMax, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("lbs")
            }
            
            HStack {
                Text("Starting Weight")
                Spacer()
                TextField("", value: $progression.startingWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("lbs")
            }
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

struct ScheduleSection: View {
    @Bindable var progression: Progression
    @State private var expandedWeek: Int?
    
    var sessionsByWeek: [Int: [WorkoutSession]] {
        Dictionary(grouping: progression.sessions.sorted { $0.dayNumber < $1.dayNumber }) { $0.weekNumber }
    }
    
    var body: some View {
        Section(header: Text("Weekly Schedule"),
                footer: Text("Tap a week to edit individual sessions. Changes are saved automatically.")) {
            
            ForEach(1...progression.totalWeeks, id: \.self) { week in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedWeek == week },
                        set: { isExpanded in expandedWeek = isExpanded ? week : nil }
                    )
                ) {
                    if let sessions = sessionsByWeek[week] {
                        ForEach(sessions) { session in
                            EditSessionRow(session: session)
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week \(week)")
                                .fontWeight(.semibold)
                            
                            if let firstSession = sessionsByWeek[week]?.first {
                                Text("\(Int(firstSession.plannedWeight)) lbs × \(firstSession.plannedSets)×\(firstSession.plannedReps)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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

// MARK: - Edit Session Row

struct EditSessionRow: View {
    @Bindable var session: WorkoutSession
    @State private var showEditSheet = false
    
    var body: some View {
        Button(action: { showEditSheet = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: session.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(session.completed ? .green : .secondary)
                        
                        Text("Day \(session.dayNumber)")
                            .fontWeight(.medium)
                    }
                    
                    Text("\(Int(session.plannedWeight)) lbs × \(session.plannedSets)×\(session.plannedReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditSheet) {
            EditSessionSheet(session: session)
        }
    }
}

// MARK: - Edit Session Sheet

struct EditSessionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var session: WorkoutSession
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Session Info")) {
                    HStack {
                        Text("Week")
                        Spacer()
                        Text("\(session.weekNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Day")
                        Spacer()
                        Text("\(session.dayNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Completed", isOn: $session.completed)
                }
                
                Section(header: Text("Planned Workout")) {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("", value: $session.plannedWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                    
                    Stepper("Sets: \(session.plannedSets)", value: $session.plannedSets, in: 1...10)
                    
                    Stepper("Reps: \(session.plannedReps)", value: $session.plannedReps, in: 1...20)
                }
                
                Section(header: Text("Sets")) {
                    ForEach(session.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Set \(set.setNumber)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(set.completed ? .green : .secondary)
                            }
                            
                            if let actualReps = set.actualReps, let actualWeight = set.actualWeight {
                                Text("\(actualReps) reps @ \(Int(actualWeight)) lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Target: \(set.targetReps) reps @ \(Int(set.targetWeight)) lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if let notes = session.notes, !notes.isEmpty {
                    Section(header: Text("Notes")) {
                        Text(notes)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Update all sets to match planned values if they haven't been completed
                        if !session.sets.isEmpty {
                            for set in session.sets where !set.completed {
                                set.targetWeight = session.plannedWeight
                                set.targetReps = session.plannedReps
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Recalculate Button (Optional Feature)

struct RecalculateButton: View {
    @Bindable var progression: Progression
    @State private var showRecalculateSheet = false
    
    var body: some View {
        Section {
            Button(action: { showRecalculateSheet = true }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Recalculate from Current Week")
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showRecalculateSheet) {
            RecalculateSheet(progression: progression)
        }
    }
}

struct RecalculateSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var progression: Progression
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Recalculate Progression")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This will recalculate all future sessions from week \(progression.currentWeek) onward based on your current and target max.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Max:")
                        Spacer()
                        Text("\(Int(progression.currentMax)) lbs")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Target Max:")
                        Spacer()
                        Text("\(Int(progression.targetMax)) lbs")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Weeks Remaining:")
                        Spacer()
                        Text("\(progression.totalWeeks - progression.currentWeek + 1)")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    // TODO: Implement recalculation logic
                    dismiss()
                }) {
                    Text("Recalculate")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Recalculate")
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
