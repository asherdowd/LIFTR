import SwiftUI
import SwiftData

struct CalculatorView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\PlateItem.weight, order: .reverse)]) private var plates: [PlateItem]
    @Query(sort: [SortDescriptor(\BarItem.weight, order: .reverse)]) private var bars: [BarItem]
    @Query(sort: [SortDescriptor(\CollarItem.weight, order: .reverse)]) private var collars: [CollarItem]
    
    @State private var targetWeight: String = ""
    @State private var selectedBar: BarItem?
    @State private var selectedCollar: CollarItem?
    @State private var useCollars: Bool = false
    @State private var useLargePlates: Bool = false
    @State private var calculatorResult: CalculatorResult?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private let calculator = PlateCalculatorService()
    
    // Optional initializer for pre-filling weight
    var initialWeight: Double?
    
    init(initialWeight: Double? = nil) {
        self.initialWeight = initialWeight
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Bar Selection Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Bar")
                            .font(.headline)
                        
                        if bars.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Please add a bar to your inventory first")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            Picker("Bar", selection: $selectedBar) {
                                Text("Select a bar").tag(nil as BarItem?)
                                ForEach(bars, id: \.id) { bar in
                                    Text("\(bar.barType) - \(String(format: "%.1f", bar.weight)) lbs")
                                        .tag(bar as BarItem?)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Collar Selection
                    if !collars.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $useCollars) {
                                Text("Include Collars")
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            if useCollars {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Select Collar")
                                        .font(.headline)
                                    
                                    Picker("Collar", selection: $selectedCollar) {
                                        Text("Select collar").tag(nil as CollarItem?)
                                        ForEach(collars, id: \.id) { collar in
                                            if !collar.name.isEmpty {
                                                Text("\(collar.name) - \(String(format: "%.1f", collar.weight)) lbs")
                                                    .tag(collar as CollarItem?)
                                            } else {
                                                Text("\(String(format: "%.1f", collar.weight)) lbs")
                                                    .tag(collar as CollarItem?)
                                            }
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Large Plates Toggle
                    Toggle(isOn: $useLargePlates) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use Large Plates")
                                .font(.headline)
                            Text("Allows plates over 45 lbs (auto enabled for 505+ lbs)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Target Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Weight")
                            .font(.headline)
                        
                        TextField("Enter target weight (lbs)", text: $targetWeight)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Calculate Button
                    Button(action: performCalculation) {
                        Text("Calculate Plate Setup")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCalculate)
                    
                    // Results Section
                    if let result = calculatorResult {
                        ResultView(result: result, hasCollars: useCollars && selectedCollar != nil)
                    }
                    
                    // Error Message
                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Calculator")
        }
        .onAppear {
            // Pre-fill target weight if provided
            if let weight = initialWeight {
                targetWeight = String(format: "%.0f", weight)
            }
        }
    }
    
    private var canCalculate: Bool {
        !targetWeight.isEmpty && selectedBar != nil && !bars.isEmpty
    }
    
    private func performCalculation() {
        showError = false
        calculatorResult = nil
        
        guard let weight = Double(targetWeight),
              let bar = selectedBar else {
            showError(message: "Please enter a valid weight and select a bar")
            return
        }
        
        // Get collar weight from selected collar (total weight = collar weight * quantity for the pair)
        let collarWeight = (useCollars && selectedCollar != nil) ? (selectedCollar!.weight * Double(selectedCollar!.quantity)) : 0
        
        guard let result = calculator.calculatePlateConfiguration(
            targetWeight: weight,
            barWeight: bar.weight,
            collarWeight: collarWeight,
            availablePlates: plates,
            useLargePlates: useLargePlates
        ) else {
            showError(message: "Cannot achieve this weight with current inventory")
            return
        }
        
        calculatorResult = result
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Result View

struct ResultView: View {
    let result: CalculatorResult
    var hasCollars: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Bar Visualizer
            BarVisualizerView(result: result, hasCollars: hasCollars)
            
            // Header
            HStack {
                Text("Result")
                    .font(.title2)
                    .bold()
                Spacer()
                if !result.isExactMatch {
                    Text("Rounded Down")
                        .font(.caption)
                        .padding(6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            Divider()
            
            // Weight Summary
            VStack(spacing: 8) {
                HStack {
                    Text("Target Weight:")
                    Spacer()
                    Text(String(format: "%.1f lbs", result.targetWeight))
                        .bold()
                }
                
                HStack {
                    Text("Actual Weight:")
                    Spacer()
                    Text(String(format: "%.1f lbs", result.actualWeight))
                        .bold()
                        .foregroundColor(result.isExactMatch ? .green : .orange)
                }
                
                HStack {
                    Text("Bar Weight:")
                    Spacer()
                    Text(String(format: "%.1f lbs", result.barWeight))
                }
                
                if result.collarWeight > 0 {
                    HStack {
                        Text("Collar Weight:")
                        Spacer()
                        Text(String(format: "%.1f lbs", result.collarWeight))
                    }
                }
                
                HStack {
                    Text("Weight per Side:")
                    Spacer()
                    Text(String(format: "%.1f lbs", result.weightPerSide))
                }
                
                HStack {
                    Text("Total Plates:")
                    Spacer()
                    Text("\(result.totalPlates)")
                }
            }
            .font(.subheadline)
            
            Divider()
            
            // Plate Configuration
            Text("Plates per Side")
                .font(.headline)
            
            ForEach(result.plateConfigurations, id: \.plateWeight) { config in
                HStack {
                    Circle()
                        .fill(plateColor(for: config.plateWeight))
                        .frame(width: 12, height: 12)
                    
                    Text(String(format: "%.1f lbs", config.plateWeight))
                    
                    Spacer()
                    
                    Text("x\(config.quantity)")
                        .bold()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func plateColor(for weight: Double) -> Color {
        // Standard Olympic plate colors
        switch weight {
        case 55: return .red
        case 45: return .red
        case 35: return .yellow
        case 25: return .green
        case 15: return .yellow
        case 10: return .green
        case 5: return .blue
        case 2.5: return .red
        default: return .gray
        }
    }
}
