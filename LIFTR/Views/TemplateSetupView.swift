import SwiftUI
import SwiftData

struct TemplateSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    let template: TemplateType
    @Binding var programWasCreated: Bool
    
    @State private var programName: String = ""
    @State private var squatWeight: String = ""
    @State private var benchWeight: String = ""
    @State private var pressWeight: String = ""
    @State private var deadliftWeight: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Program Name")) {
                    TextField("e.g., My Starting Strength", text: $programName)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Starting Weights"),
                        footer: Text("Enter your current working weights for each exercise. The program will start at 85-90% of these weights and progress from there.")) {
                    
                    HStack {
                        Text("Squat")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        TextField("0", text: $squatWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Bench Press")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        TextField("0", text: $benchWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Overhead Press")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        TextField("0", text: $pressWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                    
                    HStack {
                        Text("Deadlift")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        TextField("0", text: $deadliftWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                    }
                }
                
                Section(header: Text("Program Details")) {
                    HStack {
                        Text("Template")
                        Spacer()
                        Text(template.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("12 weeks")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text("3 sessions/week")
                            .foregroundColor(.secondary)
                    }
                }
                
                if isValidInput {
                    Section(header: Text("Preview")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your program will include:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("• Workout A: Squat, Bench Press, Deadlift")
                                .font(.caption)
                            Text("• Workout B: Squat, Overhead Press, Deadlift")
                                .font(.caption)
                            Text("• 36 total workout sessions")
                                .font(.caption)
                            Text("• Progressive loading with auto-calculated weights")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: createProgram) {
                        HStack {
                            Spacer()
                            Text("Create Program")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
            .navigationTitle("Configure Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if programName.isEmpty {
                    programName = "My \(template.rawValue)"
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard !programName.trimmingCharacters(in: .whitespaces).isEmpty,
              let _ = Double(squatWeight),
              let _ = Double(benchWeight),
              let _ = Double(pressWeight),
              let _ = Double(deadliftWeight)
        else { return false }
        
        return true
    }
    
    private func createProgram() {
        guard let squat = Double(squatWeight),
              let bench = Double(benchWeight),
              let press = Double(pressWeight),
              let deadlift = Double(deadliftWeight)
        else {
            showError(message: "Please enter valid weights for all exercises")
            return
        }
        
        // Validate weights are reasonable
        if squat < 45 || bench < 45 || press < 45 || deadlift < 45 {
            showError(message: "Starting weights should be at least 45 lbs (empty bar)")
            return
        }
        
        // Create the program using the template service
        _ = ProgramTemplates.createStartingStrength(
            name: programName.trimmingCharacters(in: .whitespaces),
            squatWeight: squat * 0.85,  // Start at 85% of entered weight
            benchWeight: bench * 0.85,
            pressWeight: press * 0.85,
            deadliftWeight: deadlift * 0.85,
            totalWeeks: 12,
            context: context
        )
        
        // Save context
        do {
            try context.save()
            programWasCreated = true 
            dismiss()
        } catch {
            showError(message: "Failed to create program: \(error.localizedDescription)")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    TemplateSetupView(template: .startingStrength, programWasCreated: .constant(false))
}
