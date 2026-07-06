import SwiftData
import SwiftUI
import Foundation

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            // V2 New Models
            Plan.self,
            ScheduledWorkout.self,
            WorkoutExercise.self,
            WorkoutSet.self,  // ← RENAMED from Set
            PlannedExercise.self,
            CustomExercise.self,
            GlobalWorkoutSettings.self,
            
            // Unchanged from V1
            User.self,
            PlateItem.self,
            BarItem.self,
            CollarItem.self,
            ExerciseProgressionSettings.self
        ]
    }
    
    // MARK: - Plan
    
    @Model
    final class Plan {
        var id: UUID
        var name: String
        var planType: PlanType
        var status: PlanStatus
        
        var startDate: Date
        var totalWeeks: Int
        var currentWeek: Int
        
        var useMetric: Bool
        var notes: String?
        
        @Relationship(deleteRule: .cascade)
        var scheduledWorkouts: [ScheduledWorkout]
        
        @Relationship(deleteRule: .cascade)
        var exercises: [PlannedExercise]
        
        var progressPercentage: Double {
            Double(currentWeek) / Double(totalWeeks) * 100
        }
        
        init(
            id: UUID = UUID(),
            name: String,
            planType: PlanType,
            status: PlanStatus = .active,
            startDate: Date = Date(),
            totalWeeks: Int,
            currentWeek: Int = 1,
            useMetric: Bool = false,
            notes: String? = nil
        ) {
            self.id = id
            self.name = name
            self.planType = planType
            self.status = status
            self.startDate = startDate
            self.totalWeeks = totalWeeks
            self.currentWeek = currentWeek
            self.useMetric = useMetric
            self.notes = notes
            self.scheduledWorkouts = []
            self.exercises = []
        }
    }
    
    // MARK: - PlannedExercise
    
    @Model
    final class PlannedExercise {
        var id: UUID
        var exerciseDefinition: ExerciseDefinition
        var orderIndex: Int
        
        var startingWeight: Double?
        var currentWeight: Double?
        var targetSets: Int?
        var targetReps: Int?
        var increment: Double?
        
        var startingDistance: Double?
        var targetDistance: Double?
        var targetDuration: TimeInterval?
        
        var progressionStyle: ProgressionStyle?
        
        var warmupStyle: WarmupStyle?
        var warmupRepsStyle: WarmupRepsStyle?
        
        var notes: String?
        
        var plan: Plan?
        
        init(
            id: UUID = UUID(),
            exerciseDefinition: ExerciseDefinition,
            orderIndex: Int,
            startingWeight: Double? = nil,
            currentWeight: Double? = nil,
            targetSets: Int? = nil,
            targetReps: Int? = nil,
            increment: Double? = nil,
            startingDistance: Double? = nil,
            targetDistance: Double? = nil,
            targetDuration: TimeInterval? = nil,
            progressionStyle: ProgressionStyle? = nil,
            warmupStyle: WarmupStyle? = nil,
            warmupRepsStyle: WarmupRepsStyle? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.exerciseDefinition = exerciseDefinition
            self.orderIndex = orderIndex
            self.startingWeight = startingWeight
            self.currentWeight = currentWeight
            self.targetSets = targetSets
            self.targetReps = targetReps
            self.increment = increment
            self.startingDistance = startingDistance
            self.targetDistance = targetDistance
            self.targetDuration = targetDuration
            self.progressionStyle = progressionStyle
            self.warmupStyle = warmupStyle
            self.warmupRepsStyle = warmupRepsStyle
            self.notes = notes
        }
    }
    
    // MARK: - ScheduledWorkout
    
    @Model
    final class ScheduledWorkout {
        var id: UUID
        var date: Date
        var weekNumber: Int
        var dayNumber: Int
        var sessionNumber: Int
        
        var completed: Bool
        var completedDate: Date?
        var paused: Bool
        
        var startTime: Date?
        var endTime: Date?
        var totalDuration: TimeInterval?
        
        var healthKitWorkoutId: String?
        var syncedToHealthKit: Bool
        var stravaActivityId: String?
        var syncedToStrava: Bool
        var caloriesBurned: Double?
        var heartRateAverage: Int?
        var heartRateMax: Int?
        
        var notes: String?
        
        var plan: Plan?
        
        @Relationship(deleteRule: .cascade)
        var exercises: [WorkoutExercise]
        
        var workoutType: WorkoutType {
            if exercises.allSatisfy({ $0.exerciseType == .strength }) {
                return .strength
            } else if exercises.allSatisfy({ $0.exerciseType == .cardio }) {
                return .cardio
            } else {
                return .mixed
            }
        }
        
        init(
            id: UUID = UUID(),
            date: Date = Date(),
            weekNumber: Int,
            dayNumber: Int,
            sessionNumber: Int,
            completed: Bool = false,
            completedDate: Date? = nil,
            paused: Bool = false,
            startTime: Date? = nil,
            endTime: Date? = nil,
            totalDuration: TimeInterval? = nil,
            healthKitWorkoutId: String? = nil,
            syncedToHealthKit: Bool = false,
            stravaActivityId: String? = nil,
            syncedToStrava: Bool = false,
            caloriesBurned: Double? = nil,
            heartRateAverage: Int? = nil,
            heartRateMax: Int? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.date = date
            self.weekNumber = weekNumber
            self.dayNumber = dayNumber
            self.sessionNumber = sessionNumber
            self.completed = completed
            self.completedDate = completedDate
            self.paused = paused
            self.startTime = startTime
            self.endTime = endTime
            self.totalDuration = totalDuration
            self.healthKitWorkoutId = healthKitWorkoutId
            self.syncedToHealthKit = syncedToHealthKit
            self.stravaActivityId = stravaActivityId
            self.syncedToStrava = syncedToStrava
            self.caloriesBurned = caloriesBurned
            self.heartRateAverage = heartRateAverage
            self.heartRateMax = heartRateMax
            self.notes = notes
            self.exercises = []
        }
    }
    
    // MARK: - WorkoutExercise
    
    @Model
    final class WorkoutExercise {
        var id: UUID
        var exerciseDefinition: ExerciseDefinition
        var exerciseType: ExerciseType
        var orderIndex: Int
        
        var plannedWeight: Double?
        var plannedSets: Int?
        var plannedReps: Int?
        
        var plannedDistance: Double?
        var plannedDuration: TimeInterval?
        
        var actualDistance: Double?
        var actualDuration: TimeInterval?
        var actualReps: Int?
        var actualSets: Int?
        var rounds: Int?
        var movements: String?
        
        var rpe: Int?
        var notes: String?
        
        var scheduledWorkout: ScheduledWorkout?
        
        @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
        var sets: [WorkoutSet]  // ← UPDATED
        
        var totalPlannedReps: Int {
            (plannedSets ?? 0) * (plannedReps ?? 0)
        }
        
        var totalCompletedReps: Int {
            sets.filter({ !$0.isWarmup }).reduce(0) { $0 + ($1.actualReps ?? 0) }
        }
        
        var performancePercentage: Double {
            guard totalPlannedReps > 0 else { return 0 }
            return Double(totalCompletedReps) / Double(totalPlannedReps) * 100
        }
        
        var isCompleted: Bool {
            if exerciseType == .strength {
                return sets.filter({ !$0.isWarmup }).allSatisfy { $0.completed }
            } else {
                return actualDistance != nil || actualDuration != nil
            }
        }
        
        init(
            id: UUID = UUID(),
            exerciseDefinition: ExerciseDefinition,
            exerciseType: ExerciseType,
            orderIndex: Int,
            plannedWeight: Double? = nil,
            plannedSets: Int? = nil,
            plannedReps: Int? = nil,
            plannedDistance: Double? = nil,
            plannedDuration: TimeInterval? = nil,
            actualDistance: Double? = nil,
            actualDuration: TimeInterval? = nil,
            actualReps: Int? = nil,
            actualSets: Int? = nil,
            rounds: Int? = nil,
            movements: String? = nil,
            rpe: Int? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.exerciseDefinition = exerciseDefinition
            self.exerciseType = exerciseType
            self.orderIndex = orderIndex
            self.plannedWeight = plannedWeight
            self.plannedSets = plannedSets
            self.plannedReps = plannedReps
            self.plannedDistance = plannedDistance
            self.plannedDuration = plannedDuration
            self.actualDistance = actualDistance
            self.actualDuration = actualDuration
            self.actualReps = actualReps
            self.actualSets = actualSets
            self.rounds = rounds
            self.movements = movements
            self.rpe = rpe
            self.notes = notes
            self.sets = []
        }
    }
    
    // MARK: - WorkoutSet (RENAMED from Set)
    
    @Model
    final class WorkoutSet {
        var id: UUID
        var setNumber: Int
        
        var targetReps: Int
        var targetWeight: Double
        
        var actualReps: Int?
        var actualWeight: Double?
        var rpe: Int?
        var completed: Bool
        var notes: String?
        
        var isWarmup: Bool
        var warmupPercentage: Int?
        
        var workoutExercise: WorkoutExercise?
        
        var wasSuccessful: Bool {
            guard let actualReps = actualReps else { return false }
            return actualReps >= targetReps
        }
        
        init(
            id: UUID = UUID(),
            setNumber: Int,
            targetReps: Int,
            targetWeight: Double,
            actualReps: Int? = nil,
            actualWeight: Double? = nil,
            rpe: Int? = nil,
            completed: Bool = false,
            notes: String? = nil,
            isWarmup: Bool = false,
            warmupPercentage: Int? = nil
        ) {
            self.id = id
            self.setNumber = setNumber
            self.targetReps = targetReps
            self.targetWeight = targetWeight
            self.actualReps = actualReps
            self.actualWeight = actualWeight
            self.rpe = rpe
            self.completed = completed
            self.notes = notes
            self.isWarmup = isWarmup
            self.warmupPercentage = warmupPercentage
        }
    }
    
    // MARK: - CustomExercise
    
    @Model
    final class CustomExercise {
        var id: UUID
        var displayName: String
        var shortName: String
        var category: ExerciseCategory
        var createdDate: Date
        
        var asDefinition: ExerciseDefinition {
            ExerciseDefinition(
                id: id,
                category: category,
                displayName: displayName,
                shortName: shortName,
                commonVariations: nil,
                isCustom: true
            )
        }
        
        init(
            id: UUID = UUID(),
            displayName: String,
            shortName: String,
            category: ExerciseCategory,
            createdDate: Date = Date()
        ) {
            self.id = id
            self.displayName = displayName
            self.shortName = shortName
            self.category = category
            self.createdDate = createdDate
        }
    }
    
    // MARK: - GlobalWorkoutSettings
    
    @Model
    final class GlobalWorkoutSettings {
        var id: UUID
        
        var useMetric: Bool
        var trackRPE: Bool
        
        var adjustmentMode: AdjustmentMode
        var excellentThreshold: Int
        var goodThreshold: Int
        var adjustmentThreshold: Int
        var reductionPercent: Double
        var deloadPercent: Double
        
        var defaultRestTime: Int
        var autoStartRestTimer: Bool
        var restTimerAfterWarmups: Bool
        var restTimerSound: Bool
        var restTimerHaptic: Bool
        
        var defaultView: DefaultView
        var weekStartsOn: DayOfWeek
        
        var autoSyncHealthKit: Bool
        var autoSyncStrava: Bool
        
        init(
            id: UUID = UUID(),
            useMetric: Bool = false,
            trackRPE: Bool = true,
            adjustmentMode: AdjustmentMode = .prompt,
            excellentThreshold: Int = 100,
            goodThreshold: Int = 90,
            adjustmentThreshold: Int = 75,
            reductionPercent: Double = 10,
            deloadPercent: Double = 20,
            defaultRestTime: Int = 180,
            autoStartRestTimer: Bool = true,
            restTimerAfterWarmups: Bool = false,
            restTimerSound: Bool = true,
            restTimerHaptic: Bool = true,
            defaultView: DefaultView = .today,
            weekStartsOn: DayOfWeek = .monday,
            autoSyncHealthKit: Bool = true,
            autoSyncStrava: Bool = false
        ) {
            self.id = id
            self.useMetric = useMetric
            self.trackRPE = trackRPE
            self.adjustmentMode = adjustmentMode
            self.excellentThreshold = excellentThreshold
            self.goodThreshold = goodThreshold
            self.adjustmentThreshold = adjustmentThreshold
            self.reductionPercent = reductionPercent
            self.deloadPercent = deloadPercent
            self.defaultRestTime = defaultRestTime
            self.autoStartRestTimer = autoStartRestTimer
            self.restTimerAfterWarmups = restTimerAfterWarmups
            self.restTimerSound = restTimerSound
            self.restTimerHaptic = restTimerHaptic
            self.defaultView = defaultView
            self.weekStartsOn = weekStartsOn
            self.autoSyncHealthKit = autoSyncHealthKit
            self.autoSyncStrava = autoSyncStrava
        }
    }
    
    // MARK: - Supporting Types (Enums & Structs)
    
    enum PlanType: String, Codable, CaseIterable {
        case singleExercise = "Single Exercise"
        case program = "Full Program"
        case cardioProgram = "Cardio Program"
    }
    
    enum PlanStatus: String, Codable {
        case active = "Active"
        case paused = "Paused"
        case completed = "Completed"
    }
    
    enum ProgressionStyle: String, Codable, CaseIterable {
        case linear = "Linear"
        case periodization = "Periodization"
        case rpe = "RPE-Based"
        case percentage = "Percentage-Based"
    }
    
    enum WarmupStyle: String, Codable, CaseIterable {
        case none = "None"
        case minimal = "Minimal"
        case pyramid = "Pyramid"
    }
    
    enum WarmupRepsStyle: String, Codable, CaseIterable {
        case decreasing = "Decreasing Reps"
        case constant = "Constant Reps"
        case matchWorking = "Match Working"
    }
    
    enum WorkoutType: String {
        case strength = "Strength"
        case cardio = "Cardio"
        case mixed = "Mixed"
    }
    
    enum ExerciseType: String, Codable {
        case strength = "Strength"
        case cardio = "Cardio"
    }
    
    enum AdjustmentMode: String, Codable, CaseIterable {
        case prompt = "Ask Me"
        case autoAdjust = "Auto-Adjust"
        case never = "Never Adjust"
    }
    
    enum DefaultView: String, Codable, CaseIterable {
        case today = "Today"
        case plans = "My Plans"
        case history = "History"
    }
    
    enum DayOfWeek: String, Codable, CaseIterable {
        case sunday = "Sunday"
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"
    }
    
    enum ExerciseCategory: String, Codable, CaseIterable {
        case squat = "Squat"
        case deadlift = "Deadlift"
        case benchPress = "Bench Press"
        case overheadPress = "Overhead Press"
        case row = "Row"
        case pullup = "Pull-up / Chin-up"
        
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case quads = "Quads"
        case hamstrings = "Hamstrings"
        case glutes = "Glutes"
        case calves = "Calves"
        case biceps = "Biceps"
        case triceps = "Triceps"
        case forearms = "Forearms"
        case abs = "Abs"
        
        case running = "Running"
        case cycling = "Cycling"
        case swimming = "Swimming"
        case rowing = "Rowing (Cardio)"
        case other = "Other"
        
        var exerciseStyle: ExerciseStyle {
            switch self {
            case .squat, .deadlift, .benchPress, .overheadPress, .row, .pullup:
                return .compound
            case .chest, .back, .shoulders, .quads, .hamstrings, .glutes, .calves, .biceps, .triceps, .forearms, .abs:
                return .bodybuilding
            case .running, .cycling, .swimming, .rowing, .other:
                return .cardio
            }
        }
    }
    
    enum ExerciseStyle: String, Codable {
        case compound = "Compound"
        case bodybuilding = "Bodybuilding"
        case cardio = "Cardio"
    }
    
    struct ExerciseDefinition: Identifiable, Codable, Hashable {
        let id: UUID
        let category: ExerciseCategory
        let displayName: String
        let shortName: String
        let commonVariations: [String]?
        let isCustom: Bool
        
        static let builtIn: [ExerciseDefinition] = [
            // COMPOUNDS
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                category: .squat,
                displayName: "Squat Variations",
                shortName: "Squat",
                commonVariations: ["Back Squat", "Front Squat", "Goblet Squat", "Box Squat", "Pause Squat"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                category: .deadlift,
                displayName: "Deadlift Variations",
                shortName: "Deadlift",
                commonVariations: ["Conventional", "Sumo", "Romanian", "Trap Bar", "Deficit"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                category: .benchPress,
                displayName: "Bench Press Variations",
                shortName: "Bench Press",
                commonVariations: ["Flat Bench", "Incline Bench", "Decline Bench", "Close-Grip", "Pause Bench"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                category: .overheadPress,
                displayName: "Overhead Press Variations",
                shortName: "Overhead Press",
                commonVariations: ["Strict Press", "Push Press", "Seated Press", "Dumbbell Press", "Arnold Press"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                category: .row,
                displayName: "Row Variations",
                shortName: "Row",
                commonVariations: ["Barbell Row", "Dumbbell Row", "Cable Row", "T-Bar Row", "Pendlay Row"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                category: .pullup,
                displayName: "Pull-up / Chin-up Variations",
                shortName: "Pull-up",
                commonVariations: ["Pull-ups", "Chin-ups", "Neutral Grip", "Wide Grip", "Weighted"],
                isCustom: false
            ),
            
            // BODYBUILDING
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                category: .chest,
                displayName: "Chest - Isolation",
                shortName: "Chest Fly",
                commonVariations: ["Dumbbell Fly", "Cable Crossover", "Pec Deck", "Machine Fly"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
                category: .back,
                displayName: "Back - Isolation",
                shortName: "Lat Pulldown",
                commonVariations: ["Lat Pulldown", "Face Pulls", "Rear Delt Fly", "Straight Arm Pulldown"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
                category: .shoulders,
                displayName: "Shoulders - Lateral/Rear Delts",
                shortName: "Lateral Raise",
                commonVariations: ["Lateral Raise", "Rear Delt Fly", "Cable Lateral Raise", "Upright Row"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!,
                category: .quads,
                displayName: "Quads - Isolation",
                shortName: "Leg Extension",
                commonVariations: ["Leg Extension", "Leg Press", "Hack Squat", "Bulgarian Split Squat"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!,
                category: .hamstrings,
                displayName: "Hamstrings - Isolation",
                shortName: "Leg Curl",
                commonVariations: ["Leg Curl", "Nordic Curl", "Good Morning", "Glute-Ham Raise"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000C")!,
                category: .glutes,
                displayName: "Glutes - Isolation",
                shortName: "Hip Thrust",
                commonVariations: ["Hip Thrust", "Glute Bridge", "Cable Kickback", "Bulgarian Split Squat"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000D")!,
                category: .calves,
                displayName: "Calves",
                shortName: "Calf Raise",
                commonVariations: ["Standing Calf Raise", "Seated Calf Raise", "Donkey Calf Raise"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000E")!,
                category: .biceps,
                displayName: "Biceps - Curl Variations",
                shortName: "Biceps Curl",
                commonVariations: ["Barbell Curl", "Dumbbell Curl", "Hammer Curl", "Preacher Curl", "Cable Curl"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000F")!,
                category: .triceps,
                displayName: "Triceps - Extension Variations",
                shortName: "Triceps Extension",
                commonVariations: ["Tricep Pushdown", "Overhead Extension", "Skull Crusher", "Close-Grip Bench", "Dips"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                category: .forearms,
                displayName: "Forearms",
                shortName: "Wrist Curl",
                commonVariations: ["Wrist Curl", "Reverse Wrist Curl", "Farmer's Walk", "Dead Hang"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                category: .abs,
                displayName: "Abs / Core",
                shortName: "Abs",
                commonVariations: ["Plank", "Hanging Leg Raise", "Cable Crunch", "Ab Wheel", "Sit-ups"],
                isCustom: false
            ),
            
            // CARDIO
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
                category: .running,
                displayName: "Running",
                shortName: "Run",
                commonVariations: ["Treadmill", "Outdoor", "Track", "Trail"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
                category: .cycling,
                displayName: "Cycling",
                shortName: "Cycle",
                commonVariations: ["Stationary Bike", "Road Bike", "Mountain Bike", "Spin Class"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
                category: .swimming,
                displayName: "Swimming",
                shortName: "Swim",
                commonVariations: ["Freestyle", "Backstroke", "Breaststroke", "Butterfly"],
                isCustom: false
            ),
            ExerciseDefinition(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!,
                category: .rowing,
                displayName: "Rowing (Cardio)",
                shortName: "Row (Cardio)",
                commonVariations: ["Rowing Machine", "Water Rowing"],
                isCustom: false
            )
        ]
    }
    
    // MARK: - Unchanged Models from V1
    
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
    
    // MARK: - UI Helpers (Not stored in DB)
    
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
        
        var settings: GlobalWorkoutSettings {
            let settings = GlobalWorkoutSettings()
            
            switch self {
            case .conservative:
                settings.excellentThreshold = 95
                settings.goodThreshold = 85
                settings.adjustmentThreshold = 70
                settings.reductionPercent = 3.0
                settings.deloadPercent = 8.0
                
            case .moderate:
                settings.excellentThreshold = 90
                settings.goodThreshold = 75
                settings.adjustmentThreshold = 50
                settings.reductionPercent = 5.0
                settings.deloadPercent = 10.0
                
            case .aggressive:
                settings.excellentThreshold = 85
                settings.goodThreshold = 70
                settings.adjustmentThreshold = 40
                settings.reductionPercent = 7.0
                settings.deloadPercent = 12.0
            }
            
            return settings
        }
    }
}
