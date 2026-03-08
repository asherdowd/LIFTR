import Foundation

// MARK: - Shared Enums (used across all models)

enum ProgressionStatus: String, Codable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
}

// MARK: - Settings Enums

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
            settings.lowerBodyIncrement = 5.0
            settings.upperBodyIncrement = 2.5
            
        case .moderate:
            settings.excellentThreshold = 90
            settings.goodThreshold = 75
            settings.adjustmentThreshold = 50
            settings.reductionPercent = 5.0
            settings.deloadPercent = 10.0
            settings.lowerBodyIncrement = 5.0
            settings.upperBodyIncrement = 2.5
            
        case .aggressive:
            settings.excellentThreshold = 85
            settings.goodThreshold = 70
            settings.adjustmentThreshold = 40
            settings.reductionPercent = 7.0
            settings.deloadPercent = 12.0
            settings.lowerBodyIncrement = 10.0
            settings.upperBodyIncrement = 5.0
        }
        
        return settings
    }
}

// MARK: - Strength Enums

enum TemplateType: String, Codable, CaseIterable {
    case startingStrength = "Starting Strength"
    case smolov = "Smolov"
    case fiveThreeOne = "5/3/1"
    case texasMethod = "Texas Method"
    case madcow = "Madcow 5x5"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .startingStrength:
            return "Linear progression for beginners"
        case .smolov:
            return "Intense squat specialization program"
        case .fiveThreeOne:
            return "Wave periodization with deloads"
        case .texasMethod:
            return "Intermediate weekly progression"
        case .madcow:
            return "Ramping sets with weekly progression"
        case .custom:
            return "Create your own progression"
        }
    }
}

enum ProgressionStyle: String, Codable, CaseIterable {
    case linear = "Linear"
    case periodization = "Periodization"
    case rpe = "RPE-Based"
    case percentage = "Percentage-Based"
    
    var description: String {
        switch self {
        case .linear:
            return "Consistent weight increases each session/week"
        case .periodization:
            return "Wave-like progression with planned variation"
        case .rpe:
            return "Based on Rate of Perceived Exertion"
        case .percentage:
            return "Based on percentage of max"
        }
    }
}

enum ProgressionAdjustment: Equatable {
    case continueAsPlanned
    case repeatWeight
    case reduceBy(percent: Double)
    case deload(percent: Double)
    
    var message: String {
        switch self {
        case .continueAsPlanned:
            return "Great work! Continue with your planned progression."
        case .repeatWeight:
            return "You completed most reps but not all. Repeat this weight next session."
        case .reduceBy(let percent):
            return "Performance below target. Reduce future weights by \(String(format: "%.1f", percent))%?"
        case .deload(let percent):
            return "Significant performance drop. Deload by \(String(format: "%.1f", percent))% for recovery?"
        }
    }
}

// MARK: - Cardio Enums

enum CardioType: String, Codable, CaseIterable {
    case running = "Running"
    case swimming = "Swimming"
    case calisthenics = "Calisthenics"
    case crossfit = "CrossFit"
    case freeCardio = "Free Cardio"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .swimming: return "figure.pool.swim"
        case .calisthenics: return "figure.climbing"
        case .crossfit: return "figure.strengthtraining.functional"
        case .freeCardio: return "heart.fill"
        }
    }
    
    var description: String {
        switch self {
        case .running: return "Distance-based running progressions"
        case .swimming: return "Swimming distance and time tracking"
        case .calisthenics: return "Bodyweight movement progressions"
        case .crossfit: return "CrossFit WOD tracking"
        case .freeCardio: return "General cardio sessions"
        }
    }
}

enum CrossFitWorkoutType: String, Codable, CaseIterable {
    case forTime = "For Time"
    case amrap = "AMRAP"
    case emom = "EMOM"
    case tabata = "Tabata"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .forTime: return "Complete rounds as fast as possible"
        case .amrap: return "As Many Rounds/Reps As Possible"
        case .emom: return "Every Minute On the Minute"
        case .tabata: return "20 seconds work, 10 seconds rest"
        case .custom: return "Custom workout format"
        }
    }
}
