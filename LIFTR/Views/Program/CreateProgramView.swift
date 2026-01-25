import SwiftUI
import SwiftData

struct CreateProgramView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State private var programWasCreated = false
    @State private var selectedTemplate: TemplateType?
    @State private var showTemplateSetup = false
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a Program Template")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select a proven training template to start your strength journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Starting Strength Template
                        TemplateCard(
                            template: .startingStrength,
                            isSelected: selectedTemplate == .startingStrength,
                            onSelect: {
                                selectedTemplate = .startingStrength
                                showTemplateSetup = true
                            }
                        )
                        
                        // Texas Method Template
                        TemplateCard(
                            template: .texasMethod,
                            isSelected: selectedTemplate == .texasMethod,
                            onSelect: {
                                selectedTemplate = .texasMethod
                                showTemplateSetup = true
                            }
                        )
                        
                        // Madcow 5x5 Template
                        TemplateCard(
                            template: .madcow,
                            isSelected: selectedTemplate == .madcow,
                            onSelect: {
                                selectedTemplate = .madcow
                                showTemplateSetup = true
                            }
                        )
                        
                        // Coming Soon Templates
                        ComingSoonTemplateCard(template: .smolov)
                        ComingSoonTemplateCard(template: .fiveThreeOne)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTemplateSetup) {
                if let template = selectedTemplate {
                    TemplateSetupView(template: template, programWasCreated: $programWasCreated)
                }
            }
            .onChange(of: programWasCreated) { oldValue, newValue in
                if newValue {
                    dismiss() // Dismiss the entire CreateProgramView sheet
                }
            }
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: TemplateType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                // Template details
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        Label("12 weeks", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("3x/week", systemImage: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(progressionLabel, systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(exercisesLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var progressionLabel: String {
        switch template {
        case .startingStrength:
            return "Linear"
        case .texasMethod:
            return "Weekly"
        case .madcow:
            return "Ramping"
        default:
            return "Progressive"
        }
    }
    
    private var exercisesLabel: String {
        switch template {
        case .madcow:
            return "Exercises: Squat, Bench, Row, Press, Deadlift"
        default:
            return "Exercises: Squat, Bench, Press, Deadlift"
        }
    }
}

// MARK: - Coming Soon Template Card

struct ComingSoonTemplateCard: View {
    let template: TemplateType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.rawValue)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Text("Coming Soon")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    CreateProgramView()
}
