import SwiftUI
import SwiftData

struct CardioSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    
    @Bindable var session: CardioSession
    @Bindable var progression: CardioProgression
    
    @State private var actualDistance: String = ""
    @State private var actualReps: String = ""
    @State private var actualSets: String = ""
    @State private var duration: String = ""
    @State private var rounds: String = ""
    @State private var movements: String = ""
    @State private var notes: String = ""
    @State private var rpe: Double = 7
    
    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(progression.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Week \(session.weekNumber), Day \(session.dayNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: progression.cardioType.icon)
                            Text(progression.cardioType.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    // Session Input based on type
                    VStack(spacing: 16) {
                        switch progression.cardioType {
                        case .running, .swimming:
                            RunningSwimmingInput(
                                session: session,
                                progression: progression,
                                actualDistance: $actualDistance,
                                duration: $duration
                            )
                            
                        case .calisthenics:
                            CalisthenicsInput(
                                session: session,
                                actualReps: $actualReps,
                                actualSets: $actualSets,
                                progression: progression
                            )
                            
                        case .crossfit:
                            CrossFitInput(
                                session: session,
                                progression: progression,
                                rounds: $rounds,
                                movements: $movements,
                                duration: $duration
                            )
                            
                        case .freeCardio:
                            FreeCardioInput(
                                session: session,
                                duration: $duration
                            )
                        }
                        
                        // RPE if enabled
                        if currentSettings.trackRPE {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Rate of Perceived Exertion")
                                    .font(.headline)
                                
                                HStack {
                                    Text("RPE: \(Int(rpe))")
                                        .fontWeight(.semibold)
                                    Slider(value: $rpe, in: 1...10, step: 1)
                                }
                                
                                Text("1 = Very Easy, 10 = Maximum Effort")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeWorkout()
                    }
                    .disabled(!isValidInput)
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    private var isValidInput: Bool {
        switch progression.cardioType {
        case .running, .swimming:
            return !actualDistance.isEmpty && !duration.isEmpty
        case .calisthenics:
            return !actualReps.isEmpty && !actualSets.isEmpty
        case .crossfit:
            return !duration.isEmpty
        case .freeCardio:
            return !duration.isEmpty
        }
    }
    
    private func loadExistingData() {
        if let distance = session.actualDistance {
            actualDistance = String(format: "%.1f", distance)
        }
        if let reps = session.actualReps {
            actualReps = String(reps)
        }
        if let sets = session.actualSets {
            actualSets = String(sets)
        }
        if let dur = session.duration {
            duration = String(format: "%.0f", dur / 60)
        }
        if let rnds = session.rounds {
            rounds = String(rnds)
        }
        movements = session.movements ?? ""
        notes = session.notes ?? ""
        if let sessionRPE = session.rpe {
            rpe = Double(sessionRPE)
        }
    }
    
    private func completeWorkout() {
        // Save data based on type
        switch progression.cardioType {
        case .running, .swimming:
            session.actualDistance = Double(actualDistance)
            if let dur = Double(duration) {
                session.duration = dur * 60
            }
            
        case .calisthenics:
            session.actualReps = Int(actualReps)
            session.actualSets = Int(actualSets)
            
        case .crossfit:
            session.rounds = Int(rounds)
            session.movements = movements.isEmpty ? nil : movements
            if let dur = Double(duration) {
                session.duration = dur * 60
            }
            
        case .freeCardio:
            if let dur = Double(duration) {
                session.duration = dur * 60
            }
        }
        
        session.completed = true
        session.completedDate = Date()
        session.notes = notes.isEmpty ? nil : notes
        session.rpe = currentSettings.trackRPE ? Int(rpe) : nil
        
        // Check if we should advance the week
        let completedThisWeek = progression.sessions.filter {
            $0.weekNumber == session.weekNumber && $0.completed
        }.count
        
        let totalThisWeek = progression.sessions.filter {
            $0.weekNumber == session.weekNumber
        }.count
        
        if completedThisWeek >= totalThisWeek && progression.currentWeek < progression.totalWeeks {
            progression.currentWeek += 1
        }
        
        try? context.save()
        dismiss()
    }
}

// MARK: - Input Views

struct RunningSwimmingInput: View {
    let session: CardioSession
    let progression: CardioProgression
    @Binding var actualDistance: String
    @Binding var duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned")
                .font(.headline)
                .padding(.horizontal)
            
            if let planned = session.plannedDistance {
                HStack {
                    Text("Distance:")
                    Spacer()
                    Text(String(format: "%.1f", planned))
                        .fontWeight(.semibold)
                    Text(progression.useMetric ? "km" : "mi")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Text("Actual")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Distance")
                    Spacer()
                    TextField("0.0", text: $actualDistance)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(progression.useMetric ? "km" : "mi")
                }
                
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("0", text: $duration)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("minutes")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct CalisthenicsInput: View {
    let session: CardioSession
    @Binding var actualReps: String
    @Binding var actualSets: String
    let progression: CardioProgression
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                VStack(alignment: .leading) {
                    if let planned = session.plannedReps {
                        Text("Reps: \(planned)")
                    }
                    if let sets = session.plannedSets {
                        Text("Sets: \(sets)")
                    }
                }
                Spacer()
                if let exercise = progression.exerciseName {
                    Text(exercise)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Text("Actual")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Reps per Set")
                    Spacer()
                    TextField("0", text: $actualReps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Sets Completed")
                    Spacer()
                    TextField("0", text: $actualSets)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct CrossFitInput: View {
    let session: CardioSession
    let progression: CardioProgression
    @Binding var rounds: String
    @Binding var movements: String
    @Binding var duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WOD Type")
                .font(.headline)
                .padding(.horizontal)
            
            if let workoutType = progression.workoutType {
                Text(workoutType.rawValue)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                if let description = progression.workoutDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            
            Text("Results")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("0", text: $duration)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("minutes")
                }
                
                HStack {
                    Text("Rounds (if applicable)")
                    Spacer()
                    TextField("0", text: $rounds)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Movements/Notes")
                        .font(.subheadline)
                    TextEditor(text: $movements)
                        .frame(height: 80)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct FreeCardioInput: View {
    let session: CardioSession
    @Binding var duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .padding(.horizontal)
            
            if let activity = session.activityType {
                Text(activity)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Text("Duration")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            HStack {
                Text("Time")
                Spacer()
                TextField("0", text: $duration)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("minutes")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}
