import SwiftUI
import SwiftData

struct CalculatorView: View {
    @Environment(\.modelContext) private var context
    @Query private var plates: [PlateInventoryItem]
    
    @State private var targetWeight: String = ""
    @State private var result: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Enter Target Weight", text: $targetWeight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Calculate") {
                    if let weight = Double(targetWeight) {
                        result = "Optimizer suggests setup for \(weight) lbs (mocked)."
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if !result.isEmpty {
                    Text(result)
                        .font(.headline)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Calculator")
        }
    }
}
