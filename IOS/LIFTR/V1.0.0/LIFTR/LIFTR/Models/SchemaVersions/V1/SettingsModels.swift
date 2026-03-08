import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    final class GlobalProgressionSettings {
        var id: UUID
        var adjustmentMode: AdjustmentMode
        
        var excellentThreshold: Int
        var goodThreshold: Int
        var adjustmentThreshold: Int
        var reductionPercent: Double
        var deloadPercent: Double
        
        var lowerBodyIncrement: Double
        var upperBodyIncrement: Double
        
        var useMetric: Bool
        
        var autoDeloadEnabled: Bool
        var autoDeloadFrequency: Int
        
        var trackRPE: Bool
        var allowMidWorkoutAdjustments: Bool
        var upcomingWorkoutsDays: Int
        
        // Rest Timer Properties
        var defaultRestTime: Int
        var autoStartRestTimer: Bool
        var restTimerSound: Bool
        var restTimerHaptic: Bool
        
        init(
            id: UUID = UUID(),
            adjustmentMode: AdjustmentMode = .prompt,
            excellentThreshold: Int = 90,
            goodThreshold: Int = 75,
            adjustmentThreshold: Int = 50,
            reductionPercent: Double = 5.0,
            deloadPercent: Double = 10.0,
            lowerBodyIncrement: Double = 5.0,
            upperBodyIncrement: Double = 2.5,
            useMetric: Bool = false,
            autoDeloadEnabled: Bool = false,
            autoDeloadFrequency: Int = 8,
            trackRPE: Bool = false,
            allowMidWorkoutAdjustments: Bool = true,
            upcomingWorkoutsDays: Int = 7,
            defaultRestTime: Int = 180,
            autoStartRestTimer: Bool = true,
            restTimerSound: Bool = true,
            restTimerHaptic: Bool = true
        ) {
            self.id = id
            self.adjustmentMode = adjustmentMode
            self.excellentThreshold = excellentThreshold
            self.goodThreshold = goodThreshold
            self.adjustmentThreshold = adjustmentThreshold
            self.reductionPercent = reductionPercent
            self.deloadPercent = deloadPercent
            self.lowerBodyIncrement = lowerBodyIncrement
            self.upperBodyIncrement = upperBodyIncrement
            self.useMetric = useMetric
            self.autoDeloadEnabled = autoDeloadEnabled
            self.autoDeloadFrequency = autoDeloadFrequency
            self.trackRPE = trackRPE
            self.allowMidWorkoutAdjustments = allowMidWorkoutAdjustments
            self.upcomingWorkoutsDays = upcomingWorkoutsDays
            self.defaultRestTime = defaultRestTime
            self.autoStartRestTimer = autoStartRestTimer
            self.restTimerSound = restTimerSound
            self.restTimerHaptic = restTimerHaptic
        }
    }
    
    @Model
    final class ExerciseProgressionSettings {
        var id: UUID
        var exerciseName: String
        var useCustomRules: Bool
        
        var excellentThreshold: Int?
        var goodThreshold: Int?
        var adjustmentThreshold: Int?
        var reductionPercent: Double?
        var deloadPercent: Double?
        
        var weightIncrement: Double?
        var autoDeloadFrequency: Int?
        
        init(
            id: UUID = UUID(),
            exerciseName: String,
            useCustomRules: Bool = false,
            excellentThreshold: Int? = nil,
            goodThreshold: Int? = nil,
            adjustmentThreshold: Int? = nil,
            reductionPercent: Double? = nil,
            deloadPercent: Double? = nil,
            weightIncrement: Double? = nil,
            autoDeloadFrequency: Int? = nil
        ) {
            self.id = id
            self.exerciseName = exerciseName
            self.useCustomRules = useCustomRules
            self.excellentThreshold = excellentThreshold
            self.goodThreshold = goodThreshold
            self.adjustmentThreshold = adjustmentThreshold
            self.reductionPercent = reductionPercent
            self.deloadPercent = deloadPercent
            self.weightIncrement = weightIncrement
            self.autoDeloadFrequency = autoDeloadFrequency
        }
    }
}
