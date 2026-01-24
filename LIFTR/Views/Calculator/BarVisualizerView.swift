import SwiftUI

struct BarVisualizerView: View {
    let result: CalculatorResult
    let hasCollars: Bool
    
    @State private var isDetailedView: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bar Setup Visualization")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { isDetailedView.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isDetailedView ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        Text(isDetailedView ? "Fit" : "Detail")
                    }
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
            }
            
            if isDetailedView {
                // Detailed scrollable view
                ScrollView(.horizontal, showsIndicators: true) {
                    barbellView(scaled: false)
                        .frame(height: 180)
                }
            } else {
                // Scaled to fit view
                GeometryReader { geometry in
                    barbellView(scaled: true)
                        .frame(width: geometry.size.width, height: 180)
                        .scaleEffect(calculateScaleFactor(availableWidth: geometry.size.width))
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func barbellView(scaled: Bool) -> some View {
        let barHeight: CGFloat = 8
        let sleeveWidth: CGFloat = calculateSleeveWidth()
        let centerWidth: CGFloat = 150
        let totalWidth = (sleeveWidth * 2) + centerWidth
        
        return VStack(spacing: 8) {
            // Top view of barbell
            HStack(spacing: 0) {
                // Left sleeve with plates
                BarSleeveView(
                    configurations: result.plateConfigurations,
                    hasCollar: hasCollars,
                    width: sleeveWidth,
                    height: barHeight
                )
                
                // Center bar
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: centerWidth, height: barHeight)
                
                // Right sleeve with plates (mirrored)
                BarSleeveView(
                    configurations: result.plateConfigurations,
                    hasCollar: hasCollars,
                    width: sleeveWidth,
                    height: barHeight,
                    isRightSide: true
                )
            }
            .frame(width: totalWidth, height: 120)
            
            // Legend
            if !scaled {
                PlateLegendView(configurations: result.plateConfigurations)
            }
        }
    }
    
    private func calculateScaleFactor(availableWidth: CGFloat) -> CGFloat {
        let sleeveWidth = calculateSleeveWidth()
        let centerWidth: CGFloat = 150
        let totalWidth = (sleeveWidth * 2) + centerWidth
        let padding: CGFloat = 40 // Account for padding
        
        let scaleFactor = (availableWidth - padding) / totalWidth
        return min(scaleFactor, 1.0) // Never scale up, only down
    }
    
    // Calculate sleeve width based on number of plates
    private func calculateSleeveWidth() -> CGFloat {
        let totalPlates = result.plateConfigurations.reduce(0) { $0 + $1.quantity }
        let collarWidth: CGFloat = hasCollars ? 8 : 0
        
        // Calculate width based on plate thickness
        var totalPlateWidth: CGFloat = 0
        for config in result.plateConfigurations {
            let plateWidth = plateWidthFor(weight: config.plateWeight)
            totalPlateWidth += plateWidth * CGFloat(config.quantity)
        }
        
        let spacing: CGFloat = CGFloat(totalPlates - 1) * 2 // 2 points spacing between plates
        
        return totalPlateWidth + spacing + collarWidth + 20 // Add padding
    }
    
    private func plateWidthFor(weight: Double) -> CGFloat {
        switch weight {
        case 100: return 20
        case 55: return 16
        case 45: return 14
        case 35: return 12
        case 25: return 10
        case 15: return 8
        case 10: return 6
        case 7.5: return 5
        case 5: return 4
        case 2.5: return 3
        default: return 5
        }
    }
}

struct BarSleeveView: View {
    let configurations: [PlateConfiguration]
    let hasCollar: Bool
    let width: CGFloat
    let height: CGFloat
    var isRightSide: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            if !isRightSide {
                // Left side: collar then plates (collar on outside)
                if hasCollar {
                    CollarView(height: height)
                }
                PlatesStack(configurations: configurations, width: width, height: height)
            } else {
                // Right side: plates then collar (collar on outside)
                PlatesStack(configurations: configurations.reversed(), width: width, height: height)
                if hasCollar {
                    CollarView(height: height)
                }
            }
        }
    }
}

struct PlatesStack: View {
    let configurations: [PlateConfiguration]
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        HStack(spacing: 2) {
            // Reverse to show heaviest plates closest to center
            ForEach(Array(configurations.reversed().enumerated()), id: \.offset) { index, config in
                ForEach(0..<config.quantity, id: \.self) { _ in
                    PlateView(
                        weight: config.plateWeight,
                        height: height
                    )
                }
            }
        }
    }
}

struct PlateView: View {
    let weight: Double
    let height: CGFloat
    
    // Standard diameter for 10+ lbs plates, smaller for change plates
    private var plateHeight: CGFloat {
        if weight >= 10 {
            return 70 // Standard full-size plate diameter
        } else {
            return 40 // Smaller diameter for change plates (under 10 lbs)
        }
    }
    
    // Width varies by weight (thickness of the plate)
    private var plateWidth: CGFloat {
        switch weight {
        case 100: return 20
        case 55: return 16
        case 45: return 14
        case 35: return 12
        case 25: return 10
        case 15: return 8
        case 10: return 6
        case 7.5: return 5
        case 5: return 4
        case 2.5: return 3
        default: return 5
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Plate rectangle
            RoundedRectangle(cornerRadius: 2)
                .fill(plateColor(for: weight))
                .frame(width: plateWidth, height: plateHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            
            // Weight label
            Text(formatWeight(weight))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.primary)
                .fixedSize()
        }
        .frame(height: 90) // Fixed height container to prevent alignment issues
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        } else {
            return String(format: "%.1f", weight)
        }
    }
    
    private func plateColor(for weight: Double) -> Color {
        switch weight {
        case 100: return Color.purple
        case 55: return Color.red
        case 45: return Color.red
        case 35: return Color.yellow
        case 25: return Color.green
        case 15: return Color.yellow
        case 10: return Color.green
        case 5: return Color.blue
        case 2.5: return Color.red.opacity(0.7)
        default: return Color.gray
        }
    }
}

struct CollarView: View {
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black)
                .frame(width: 8, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            Text("C")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

struct PlateLegendView: View {
    let configurations: [PlateConfiguration]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Color Key:")
                .font(.caption)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 4) {
                ForEach(configurations, id: \.plateWeight) { config in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(plateColor(for: config.plateWeight))
                            .frame(width: 8, height: 8)
                        Text("\(formatWeight(config.plateWeight)) lbs")
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        } else {
            return String(format: "%.1f", weight)
        }
    }
    
    private func plateColor(for weight: Double) -> Color {
        switch weight {
        case 100: return Color.purple
        case 55: return Color.red
        case 45: return Color.red
        case 35: return Color.yellow
        case 25: return Color.green
        case 15: return Color.yellow
        case 10: return Color.green
        case 5: return Color.blue
        case 2.5: return Color.red.opacity(0.7)
        default: return Color.gray
        }
    }
}
