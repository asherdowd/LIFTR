import SwiftUI

// MARK: - Adjust Weight (mid-session)
// Shown during a live program session when the planned weight turns out wrong after a set.
// The new weight applies to the sets not completed yet.

struct AdjustWeightSheet: View {
    @Environment(\.dismiss) private var dismiss

    let unitLabel: String
    let remainingSets: Int
    let onApply: (Double) -> Void

    @State private var weightText: String

    init(initialWeight: Double, unitLabel: String, remainingSets: Int, onApply: @escaping (Double) -> Void) {
        self.unitLabel = unitLabel
        self.remainingSets = remainingSets
        self.onApply = onApply
        let text: String = initialWeight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(initialWeight))
            : String(format: "%.1f", initialWeight)
        _weightText = State(initialValue: text)
    }

    private var enteredWeight: Double? {
        guard let value = Double(weightText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("Applies to the \(remainingSets) set\(remainingSets == 1 ? "" : "s") you haven't completed. Sets you've logged stay as they are.")) {
                    HStack {
                        Text("New weight")
                        Spacer()
                        TextField("", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unitLabel)
                    }
                }

                Section {
                    Button(action: apply) {
                        HStack {
                            Spacer()
                            Text("Apply")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(enteredWeight == nil)
                }
            }
            .navigationTitle("Adjust Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func apply() {
        guard let weight = enteredWeight else { return }
        onApply(weight)
        dismiss()
    }
}
