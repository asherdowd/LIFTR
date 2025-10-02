import Foundation
import SwiftData

// MARK: - Calculator Result Models

struct PlateConfiguration {
    let plateWeight: Double
    let quantity: Int // quantity per side
}

struct CalculatorResult {
    let targetWeight: Double
    let actualWeight: Double
    let barWeight: Double
    let collarWeight: Double
    let plateConfigurations: [PlateConfiguration]
    let weightPerSide: Double
    let isExactMatch: Bool
    
    var totalPlates: Int {
        plateConfigurations.reduce(0) { $0 + $1.quantity * 2 }
    }
}

// MARK: - Plate Calculator Service

class PlateCalculatorService {
    
    /// Calculates the optimal plate configuration for a target weight
    /// - Parameters:
    ///   - targetWeight: The desired total weight
    ///   - barWeight: Weight of the selected bar
    ///   - collarWeight: Total weight of collars (added on top, not included in calculation)
    ///   - availablePlates: Array of available plates from inventory
    ///   - useLargePlates: Whether to allow plates over 45 lbs
    /// - Returns: CalculatorResult with optimal plate configuration, or nil if impossible
    func calculatePlateConfiguration(
        targetWeight: Double,
        barWeight: Double,
        collarWeight: Double,
        availablePlates: [PlateItem],
        useLargePlates: Bool
    ) -> CalculatorResult? {
        
        // Calculate weight needed from plates (collars are NOT subtracted from target)
        let weightFromPlates = targetWeight - barWeight
        
        // Must be non-negative and divisible by 2 (both sides of bar)
        guard weightFromPlates >= 0 else { return nil }
        
        let weightPerSide = weightFromPlates / 2.0
        
        // Determine if we should use large plates automatically (over 505 lbs)
        let shouldUseLargePlates = useLargePlates || targetWeight > 505
        
        // Try to find exact match first, then round down if needed
        if let exactResult = findPlateConfiguration(
            targetWeightPerSide: weightPerSide,
            availablePlates: availablePlates,
            useLargePlates: shouldUseLargePlates,
            allowRoundDown: false
        ) {
            return createResult(
                targetWeight: targetWeight,
                actualWeightPerSide: weightPerSide,
                barWeight: barWeight,
                collarWeight: collarWeight,
                configurations: exactResult,
                isExact: true
            )
        }
        
        // If exact match not possible, round down to nearest achievable weight
        if let roundedResult = findPlateConfiguration(
            targetWeightPerSide: weightPerSide,
            availablePlates: availablePlates,
            useLargePlates: shouldUseLargePlates,
            allowRoundDown: true
        ) {
            let actualWeightPerSide = roundedResult.reduce(0.0) { $0 + ($1.plateWeight * Double($1.quantity)) }
            return createResult(
                targetWeight: targetWeight,
                actualWeightPerSide: actualWeightPerSide,
                barWeight: barWeight,
                collarWeight: collarWeight,
                configurations: roundedResult,
                isExact: false
            )
        }
        
        return nil
    }
    
    /// Optimized algorithm: Maximize 45s, then fill with smaller/larger as needed
    private func findPlateConfiguration(
        targetWeightPerSide: Double,
        availablePlates: [PlateItem],
        useLargePlates: Bool,
        allowRoundDown: Bool
    ) -> [PlateConfiguration]? {
        
        var remainingWeight = targetWeightPerSide
        var configurations: [PlateConfiguration] = []
        
        // Create a mutable inventory - divide by 2 since inventory is TOTAL plates, we need PER SIDE
        var inventory = Dictionary(uniqueKeysWithValues: availablePlates.map { ($0.weight, $0.quantity / 2) })
        
        // Step 1: Maximize 45 lb plates first
        if let fortyFivesAvailable = inventory[45.0], fortyFivesAvailable > 0 {
            let fortyFivesNeeded = Int(remainingWeight / 45.0)
            let fortyFivesToUse = min(fortyFivesNeeded, fortyFivesAvailable)
            
            if fortyFivesToUse > 0 {
                configurations.append(PlateConfiguration(plateWeight: 45.0, quantity: fortyFivesToUse))
                remainingWeight -= 45.0 * Double(fortyFivesToUse)
                inventory[45.0] = fortyFivesAvailable - fortyFivesToUse
            }
        }
        
        // Check if we're done
        if remainingWeight < 0.01 {
            return configurations.sorted { $0.plateWeight > $1.plateWeight }
        }
        
        // Step 2: Determine which plates are available for use
        var availablePlatesForFilling: [PlateItem] = []
        
        if useLargePlates {
            // Use all plates (large and small)
            availablePlatesForFilling = availablePlates.filter { $0.weight != 45.0 }.sorted { $0.weight > $1.weight }
        } else {
            // Only use plates 45 lbs and under (excluding 45 since we already used those)
            availablePlatesForFilling = availablePlates.filter { $0.weight < 45.0 }.sorted { $0.weight > $1.weight }
        }
        
        // Step 3: Fill remaining weight with available plates
        for plate in availablePlatesForFilling {
            guard let available = inventory[plate.weight], available > 0 else { continue }
            
            let needed = Int(remainingWeight / plate.weight)
            let toUse = min(needed, available)
            
            if toUse > 0 {
                configurations.append(PlateConfiguration(plateWeight: plate.weight, quantity: toUse))
                remainingWeight -= plate.weight * Double(toUse)
                inventory[plate.weight] = available - toUse
                
                if remainingWeight < 0.01 {
                    return configurations.sorted { $0.plateWeight > $1.plateWeight }
                }
            }
        }
        
        // Return result if we have configurations
        if !configurations.isEmpty && (remainingWeight < 0.01 || allowRoundDown) {
            // Sort configurations by weight descending (heaviest first)
            return configurations.sorted { $0.plateWeight > $1.plateWeight }
        }
        
        return nil
    }
    
    /// Helper function to fill remaining weight with given plates
    private func fillWeight(
        remaining: Double,
        plates: [PlateItem],
        inventory: inout [Double: Int],
        allowRoundDown: Bool
    ) -> [PlateConfiguration]? {
        
        var remainingWeight = remaining
        var configs: [PlateConfiguration] = []
        
        for plate in plates {
            guard let available = inventory[plate.weight], available > 0 else { continue }
            
            let needed = Int(remainingWeight / plate.weight)
            let toUse = min(needed, available)
            
            if toUse > 0 {
                configs.append(PlateConfiguration(plateWeight: plate.weight, quantity: toUse))
                remainingWeight -= plate.weight * Double(toUse)
                inventory[plate.weight] = available - toUse
                
                if remainingWeight < 0.01 {
                    return configs
                }
            }
        }
        
        // Return what we have if rounding down is allowed
        return (allowRoundDown && !configs.isEmpty) ? configs : nil
    }
    
    private func createResult(
        targetWeight: Double,
        actualWeightPerSide: Double,
        barWeight: Double,
        collarWeight: Double,
        configurations: [PlateConfiguration],
        isExact: Bool
    ) -> CalculatorResult {
        
        // Actual weight = bar + plates on both sides + collars (added on top)
        let actualTotalWeight = barWeight + (actualWeightPerSide * 2) + collarWeight
        
        return CalculatorResult(
            targetWeight: targetWeight,
            actualWeight: actualTotalWeight,
            barWeight: barWeight,
            collarWeight: collarWeight,
            plateConfigurations: configurations,
            weightPerSide: actualWeightPerSide,
            isExactMatch: isExact
        )
    }
}
