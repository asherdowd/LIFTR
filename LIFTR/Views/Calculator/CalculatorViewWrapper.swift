import SwiftUI

struct CalculatorViewWrapper: View {
    let targetWeight: Double
    
    var body: some View {
        CalculatorView(initialWeight: targetWeight)
    }
}
