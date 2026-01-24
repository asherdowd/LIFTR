import SwiftUI
import SwiftData

struct EditProgramView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Bindable var program: Program
    
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
                    ProgramDetailsSection(program: program)
                case .schedule:
                    ProgramScheduleSection(program: program)
                }
                
                // Danger Zone
                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Program")
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Program")
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
            "Delete Program",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProgram()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(program.name)'? This will remove all workout history and cannot be undone.")
        }
    }
    
    private func saveChanges() {
        try? context.save()
    }
    
    private func deleteProgram() {
        context.delete(program)
        try? context.save()
        dismiss()
    }
}

// MARK: - Details Section

struct ProgramDetailsSection: View {
    @Bindable var program: Program
    
    var body: some View {
        Section(header: Text("Basic Information")) {
            HStack {
                Text("Program Name")
                Spacer()
                Text(program.name)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Template")
                Spacer()
                Text(program.templateType.rawValue)
                    .foregroundColor(.secondary)
            }
        }
        
        Section(header: Text("Progress")) {
            Stepper("Current Week: \(program.currentWeek)", value: $program.currentWeek, in: 1...program.totalWeeks)
            
            HStack {
                Text("Total Weeks")
                Spacer()
                Text("\(program.totalWeeks)")
                    .foregroundColor(.secondary)
            }
            
            Picker("Status", selection: $program.status) {
                Text("Active").tag(ProgressionStatus.active)
                Text("Paused").tag(ProgressionStatus.paused)
                Text("Completed").tag(ProgressionStatus.completed)
            }
        }
        
        Section(header: Text("Notes")) {
            TextEditor(text: Binding(
                get: { program.notes ?? "" },
                set: { program.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 100)
        }
    }
}

// MARK: - Schedule Section

struct ProgramScheduleSection: View {
    @Bindable var program: Program
    @State private var expandedWeek: Int?
    
    var sessionsByWeek: [Int: [ExerciseSession]] {
        let allSessions = program.trainingDays.flatMap { $0.sessions }
        return Dictionary(grouping: allSessions.sorted { $0.sessionNumber < $1.sessionNumber }) { $0.weekNumber }
    }
    
    var body: some View {
        Section(header: Text("Weekly Schedule"),
                footer: Text("Tap a week to view sessions. Changes are saved automatically.")) {
            
            ForEach(1...program.totalWeeks, id: \.self) { week in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedWeek == week },
                        set: { isExpanded in expandedWeek = isExpanded ? week : nil }
                    )
                ) {
                    if let sessions = sessionsByWeek[week] {
                        ForEach(sessions) { session in
                            EditProgramSessionRow(session: session)
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week \(week)")
                                .fontWeight(.semibold)
                            
                            if let firstSession = sessionsByWeek[week]?.first {
                                Text("\(firstSession.exercise?.exerciseName ?? "Exercise")")
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

struct EditProgramSessionRow: View {
    @Bindable var session: ExerciseSession
    @State private var showEditSheet = false
    
    var body: some View {
        Button(action: { showEditSheet = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: session.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(session.completed ? .green : .secondary)
                        
                        Text(session.exercise?.exerciseName ?? "Exercise")
                            .fontWeight(.medium)
                    }
                    
                    Text("\(session.plannedSets)×\(session.plannedReps) @ \(Int(session.plannedWeight)) lbs")
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
            EditProgramSessionSheet(session: session)
        }
    }
}

// MARK: - Edit Session Sheet

struct EditProgramSessionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var session: ExerciseSession
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Session Info")) {
                    HStack {
                        Text("Exercise")
                        Spacer()
                        Text(session.exercise?.exerciseName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Week")
                        Spacer()
                        Text("\(session.weekNumber)")
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
