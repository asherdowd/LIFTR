import SwiftUI
import SwiftData

struct CreateProgramView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
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
                        
                        // Coming Soon Templates
                        ComingSoonTemplateCard(template: .smolov)
                        ComingSoonTemplateCard(template: .fiveThreeOne)
                        ComingSoonTemplateCard(template: .texasMethod)
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
                    TemplateSetupView(template: template)
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
                        
                        Label("Linear", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Exercises: Squat, Bench, Press, Deadlift")
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
