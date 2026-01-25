//
//  TemplateSetupView 2.swift
//  LIFTR
//
//  Created by Seth Dowd on 1/24/26.
//


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
                    TextField(defaultProgramName, text: $programName)
                        .autocapitalization(.words)
                }
                
                Section(header: Text(weightSectionHeader),
                        footer: Text(weightSectionFooter)) {
                    
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
                
                Section {
                    Button(action: createProgram) {
                        HStack {
                            Spacer()
                            Text("Create Program")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle(template.rawValue)
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
        }
    }
    
    // MARK: - Template-specific computed properties
    
    private var defaultProgramName: String {
        switch template {
        case .startingStrength:
            return "e.g., My Starting Strength"
        case .texasMethod:
            return "e.g., My Texas Method"
        default:
            return "e.g., My Program"
        }
    }
    
    private var weightSectionHeader: String {
        switch template {
        case .startingStrength:
            return "Starting Weights"
        case .texasMethod:
            return "Current 5 Rep Max"
        default:
            return "Weights"
        }
    }
    
    private var weightSectionFooter: String {
        switch template {
        case .startingStrength:
            return "Enter your current working weights for each exercise. The program will start at 85% of these weights and progress from there."
        case .texasMethod:
            return "Enter your current 5 rep max for each exercise. These will be used as your Intensity Day targets."
        default:
            return "Enter weights for each exercise."
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        guard !programName.trimmingCharacters(in: .whitespaces).isEmpty,
              let _ = Double(squatWeight),
              let _ = Double(benchWeight),
              let _ = Double(pressWeight),
              let _ = Double(deadliftWeight)
        else { return false }
        
        return true
    }
    
    // MARK: - Create Program
    
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
        
        // Create the program based on template type
        switch template {
        case .startingStrength:
            createStartingStrengthProgram(
                squat: squat,
                bench: bench,
                press: press,
                deadlift: deadlift
            )
            
        case .texasMethod:
            createTexasMethodProgram(
                squat: squat,
                bench: bench,
                press: press,
                deadlift: deadlift
            )
            
        default:
            showError(message: "This template is not yet implemented")
        }
    }
    
    private func createStartingStrengthProgram(
        squat: Double,
        bench: Double,
        press: Double,
        deadlift: Double
    ) {
        _ = ProgramTemplates.createStartingStrength(
            name: programName.trimmingCharacters(in: .whitespaces),
            squatWeight: squat * 0.85,  // Start at 85% of entered weight
            benchWeight: bench * 0.85,
            pressWeight: press * 0.85,
            deadliftWeight: deadlift * 0.85,
            totalWeeks: 12,
            context: context
        )
        
        saveAndDismiss()
    }
    
    private func createTexasMethodProgram(
        squat: Double,
        bench: Double,
        press: Double,
        deadlift: Double
    ) {
        _ = ProgramTemplates.createTexasMethod(
            name: programName.trimmingCharacters(in: .whitespaces),
            squatWeight: squat,  // Use actual 5RM for Texas Method
            benchWeight: bench,
            pressWeight: press,
            deadliftWeight: deadlift,
            totalWeeks: 12,
            context: context
        )
        
        saveAndDismiss()
    }
    
    private func saveAndDismiss() {
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