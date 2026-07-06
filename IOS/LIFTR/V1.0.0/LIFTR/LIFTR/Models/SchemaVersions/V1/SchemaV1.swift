import SwiftData
import Foundation

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            User.self,
            GlobalProgressionSettings.self,
            ExerciseProgressionSettings.self,
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            Progression.self,
            WorkoutSession.self,
            WorkoutSet.self,
            Program.self,
            TrainingDay.self,
            ProgramExercise.self,
            ExerciseSession.self,
            CardioProgression.self,
            CardioSession.self
        ]
    }
    
    // MARK: - Enums
    
    enum ProgressionStatus: String, Codable {
        case active = "Active"
        case paused = "Paused"
        case completed = "Completed"
    }
    
    enum TemplateType: String, Codable, CaseIterable {
        case startingStrength = "Starting Strength"
        case smolov = "Smolov"
        case fiveThreeOne = "5/3/1"
        case texasMethod = "Texas Method"
        case madcow = "Madcow 5x5"
        case custom = "Custom"
    }
    
    enum ProgressionStyle: String, Codable, CaseIterable {
        case linear = "Linear"
        case periodization = "Periodization"
        case rpe = "RPE-Based"
        case percentage = "Percentage-Based"
    }
    
    enum AdjustmentMode: String, Codable, CaseIterable {
        case prompt = "prompt"
        case autoAdjust = "autoAdjust"
        case never = "never"
    }
    
    enum CardioType: String, Codable, CaseIterable {
        case running = "Running"
        case swimming = "Swimming"
        case calisthenics = "Calisthenics"
        case crossfit = "CrossFit"
        case freeCardio = "Free Cardio"
    }
    
    enum CrossFitWorkoutType: String, Codable, CaseIterable {
        case forTime = "For Time"
        case amrap = "AMRAP"
        case emom = "EMOM"
        case tabata = "Tabata"
        case custom = "Custom"
    }
    
    // MARK: - User
    
    @Model
    final class User {
        @Attribute(.unique) var id: UUID
        var firstName: String
        var email: String
        
        init(id: UUID = UUID(), firstName: String, email: String) {
            self.id = id
            self.firstName = firstName
            self.email = email
        }
    }
    
    // MARK: - Inventory Models
    
    @Model
    final class PlateItem {
        @Attribute(.unique) var id: UUID
        var name: String
        var weight: Double
        var quantity: Int
        
        init(id: UUID = UUID(), name: String = "", weight: Double, quantity: Int) {
            self.id = id
            self.name = name
            self.weight = weight
            self.quantity = quantity
        }
    }
    
    @Model
    final class BarItem {
        @Attribute(.unique) var id: UUID
        var name: String
        var weight: Double
        var barType: String
        var quantity: Int
        
        init(id: UUID = UUID(), name: String = "", weight: Double, barType: String, quantity: Int) {
            self.id = id
            self.name = name
            self.weight = weight
            self.barType = barType
            self.quantity = quantity
        }
    }
    
    @Model
    final class CollarItem {
        @Attribute(.unique) var id: UUID
        var name: String
        var weight: Double
        var quantity: Int
        
        init(id: UUID = UUID(), name: String = "", weight: Double, quantity: Int) {
            self.id = id
            self.name = name
            self.weight = weight
            self.quantity = quantity
        }
    }
    
    // MARK: - Settings Models
    
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
    
    // MARK: - Strength Models (Minimal - V1 legacy)
    
    @Model
    final class Progression {
        var id: UUID
        var exerciseName: String
        var status: ProgressionStatus
        @Relationship(deleteRule: .cascade) var sessions: [WorkoutSession]
        
        init(id: UUID = UUID(), exerciseName: String, status: ProgressionStatus = .active) {
            self.id = id
            self.exerciseName = exerciseName
            self.status = status
            self.sessions = []
        }
    }
    
    @Model
    final class WorkoutSession {
        var id: UUID
        var date: Date
        @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
        
        init(id: UUID = UUID(), date: Date = Date()) {
            self.id = id
            self.date = date
            self.sets = []
        }
    }
    
    @Model
    final class WorkoutSet {
        var id: UUID
        var setNumber: Int
        var targetReps: Int
        var targetWeight: Double
        var actualReps: Int?
        var actualWeight: Double?
        var completed: Bool
        
        init(id: UUID = UUID(), setNumber: Int, targetReps: Int, targetWeight: Double, actualReps: Int? = nil, actualWeight: Double? = nil, completed: Bool = false) {
            self.id = id
            self.setNumber = setNumber
            self.targetReps = targetReps
            self.targetWeight = targetWeight
            self.actualReps = actualReps
            self.actualWeight = actualWeight
            self.completed = completed
        }
    }
    
    // MARK: - Program Models (Minimal - V1 legacy)
    
    @Model
    final class Program {
        var id: UUID
        var name: String
        var templateType: TemplateType
        var status: ProgressionStatus
        @Relationship(deleteRule: .cascade) var trainingDays: [TrainingDay]
        
        init(id: UUID = UUID(), name: String, templateType: TemplateType, status: ProgressionStatus = .active) {
            self.id = id
            self.name = name
            self.templateType = templateType
            self.status = status
            self.trainingDays = []
        }
    }
    
    @Model
    final class TrainingDay {
        var id: UUID
        var name: String
        var dayNumber: Int
        @Relationship(deleteRule: .cascade) var exercises: [ProgramExercise]
        @Relationship(deleteRule: .cascade) var sessions: [ExerciseSession]
        
        init(id: UUID = UUID(), name: String, dayNumber: Int) {
            self.id = id
            self.name = name
            self.dayNumber = dayNumber
            self.exercises = []
            self.sessions = []
        }
    }
    
    @Model
    final class ProgramExercise {
        var id: UUID
        var exerciseName: String
        var orderIndex: Int
        
        init(id: UUID = UUID(), exerciseName: String, orderIndex: Int) {
            self.id = id
            self.exerciseName = exerciseName
            self.orderIndex = orderIndex
        }
    }
    
    @Model
    final class ExerciseSession {
        var id: UUID
        var date: Date
        @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
        
        init(id: UUID = UUID(), date: Date = Date()) {
            self.id = id
            self.date = date
            self.sets = []
        }
    }
    
    // MARK: - Cardio Models (Minimal - V1 legacy)
    
    @Model
    final class CardioProgression {
        var id: UUID
        var name: String
        var cardioType: CardioType
        var status: ProgressionStatus
        @Relationship(deleteRule: .cascade) var sessions: [CardioSession]
        
        init(id: UUID = UUID(), name: String, cardioType: CardioType, status: ProgressionStatus = .active) {
            self.id = id
            self.name = name
            self.cardioType = cardioType
            self.status = status
            self.sessions = []
        }
    }
    
    @Model
    final class CardioSession {
        var id: UUID
        var date: Date
        var completed: Bool
        
        init(id: UUID = UUID(), date: Date = Date(), completed: Bool = false) {
            self.id = id
            self.date = date
            self.completed = completed
        }
    }
}
