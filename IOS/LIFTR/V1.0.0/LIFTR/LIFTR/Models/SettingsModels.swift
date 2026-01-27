import Foundation
import SwiftData

// MARK: - Enums

enum AdjustmentMode: String, Codable, CaseIterable {
    case prompt = "prompt"
    case autoAdjust = "autoAdjust"
    case never = "never"
    
    var displayName: String {
        switch self {
        case .prompt: return "Always prompt me"
        case .autoAdjust: return "Auto-adjust"
        case .never: return "Never adjust"
        }
    }
}

enum PresetProfile {
    case conservative
    case moderate
    case aggressive
    
    var title: String {
        switch self {
        case .conservative: return "Conservative"
        case .moderate: return "Moderate"
        case .aggressive: return "Aggressive"
        }
    }
    
    var description: String {
        switch self {
        case .conservative: return "Higher thresholds, smaller jumps"
        case .moderate: return "Balanced progression"
        case .aggressive: return "Push harder, bigger jumps"
        }
    }
    
    var goodFor: String {
        switch self {
        case .conservative: return "Good for: Beginners, injury recovery"
        case .moderate: return "Good for: Most lifters"
        case .aggressive: return "Good for: Experienced lifters"
        }
    }
    
    var settings: GlobalProgressionSettings {
        let settings = GlobalProgressionSettings()
        
        switch self {
        case .conservative:
            settings.excellentThreshold = 95
            settings.goodThreshold = 85
            settings.adjustmentThreshold = 70
            settings.reductionPercent = 3.0
            settings.deloadPercent = 8.0
            settings.lowerBodyIncrement = 2.5
            settings.upperBodyIncrement = 2.5
            
        case .moderate:
            break
            
        case .aggressive:
            settings.excellentThreshold = 85
            settings.goodThreshold = 70
            settings.adjustmentThreshold = 50
            settings.reductionPercent = 7.0
            settings.deloadPercent = 12.0
            settings.lowerBodyIncrement = 10.0
            settings.upperBodyIncrement = 5.0
        }
        
        return settings
    }
}

// MARK: - Models

@Model
class GlobalProgressionSettings {
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
    
    // Rest Timer Settings
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
class ExerciseProgressionSettings {
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
