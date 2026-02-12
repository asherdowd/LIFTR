import SwiftUI
import SwiftData
import AVFoundation

struct LogSetView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var set: WorkoutSet
    let trackRPE: Bool
    let exerciseName: String
    let totalSets: Int
    
    @State private var repsCompleted: String = ""
    @State private var weightUsed: String = ""
    @State private var rpeValue: Double = 7
    @State private var notes: String = ""
    @Environment(\.modelContext) private var context
    @Query private var globalSettings: [GlobalProgressionSettings]

    @State private var showRestTimer = false

    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }
    
    var setInfo: String {
        "Set \(set.setNumber) of \(totalSets)"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Target")) {
                    HStack {
                        Text("Reps")
                        Spacer()
                        Text("\(set.targetReps)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(Int(set.targetWeight)) lbs")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Actual Performance")) {
                    HStack {
                        Text("Reps Completed")
                        Spacer()
                        TextField("", text: $repsCompleted)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Weight Used")
                        Spacer()
                        TextField("", text: $weightUsed)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                }
                
                if trackRPE {
                    Section(header: Text("Rate of Perceived Exertion (RPE)"),
                            footer: Text("1 = Very Easy, 10 = Maximum Effort")) {
                        HStack {
                            Text("RPE: \(Int(rpeValue))")
                                .fontWeight(.semibold)
                            Slider(value: $rpeValue, in: 1...10, step: 1)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Button(action: saveSet) {
                        HStack {
                            Spacer()
                            Text("Save Set")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(repsCompleted.isEmpty || weightUsed.isEmpty)
                }
            }
            .navigationTitle("Log Set \(set.setNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRestTimer) {
                RestTimerView(
                    defaultDuration: currentSettings.defaultRestTime,
                    exerciseName: exerciseName,
                    setInfo: setInfo,
                    autoStart: currentSettings.autoStartRestTimer,
                    playSound: currentSettings.restTimerSound,
                    enableHaptic: currentSettings.restTimerHaptic,
                    onComplete: {
                        // Timer complete rest tapped - dismiss LogSetView
                        // timer already dismisses itself, this dismisses LogSetView
                        dismiss()
                    }
                )
            }
            .onAppear {
                if let actualReps = set.actualReps {
                    repsCompleted = String(actualReps)
                }
                if let actualWeight = set.actualWeight {
                    weightUsed = String(format: "%.1f", actualWeight)
                }
                if let rpe = set.rpe {
                    rpeValue = Double(rpe)
                }
                notes = set.notes ?? ""
            }
        }
    }
    
    private func saveSet() {
        guard let reps = Int(repsCompleted),
              let weight = Double(weightUsed) else { return }
        
        set.actualReps = reps
        set.actualWeight = weight
        set.rpe = trackRPE ? Int(rpeValue) : nil
        set.notes = notes.isEmpty ? nil : notes
        set.completed = true
        
        try? context.save()
        
        if currentSettings.autoStartRestTimer {
            showRestTimer = true
        } else {
            dismiss()
        }
    }
}
