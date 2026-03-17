import Foundation
import HealthKit
import SwiftData

/// Service for managing Apple Health integration
/// Handles authorization, workout export, and sync status
class HealthKitService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var lastSyncDate: Date?
    @Published var syncEnabled = false
    
    // MARK: - Private Properties
    
    private let healthStore = HKHealthStore()
    private var workoutType: HKWorkoutType { HKWorkoutType.workoutType() }
    
    // MARK: - Singleton
    
    static let shared = HealthKitService()
    
    private init() {
        checkAuthorizationStatus()
        loadSyncSettings()
    }
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization to read/write health data
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        // Data types to write
        let writeTypes: Set<HKSampleType> = [
            workoutType,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        // Data types to read (none currently needed)
        let readTypes: Set<HKObjectType> = []
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
    
    /// Check current authorization status
    private func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            authorizationStatus = .notDetermined
            isAuthorized = false
            return
        }
        
        authorizationStatus = healthStore.authorizationStatus(for: workoutType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - Workout Export
    
    /// Export a strength workout session to HealthKit
    @MainActor
    func exportWorkoutSession(_ session: WorkoutSession, context: ModelContext) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard syncEnabled else {
            print("⚠️ Sync disabled, skipping HealthKit export")
            return
        }
        
        // Check if already synced
        if session.syncedToHealthKit == true {
            print("ℹ️ Session already synced to HealthKit")
            return
        }
        
        // Ensure we have timing data
        guard let startTime = session.startTime,
              let endTime = session.endTime else {
            throw HealthKitError.missingData("Missing start/end time")
        }
        
        // Create configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        
        // Create builder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        // Set metadata
        try await builder.beginCollection(at: startTime)
        
        // Add energy if available
        if let calories = session.caloriesBurned {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantity: energyQuantity,
                start: startTime,
                end: endTime
            )
            try await builder.addSamples([energySample])
        }
        
        // Finish workout
        try await builder.endCollection(at: endTime)
        guard let workout = try await builder.finishWorkout() else {
            throw HealthKitError.missingData("Failed to create workout")
        }
        
        // Update session
        session.healthKitWorkoutId = workout.uuid.uuidString
        session.syncedToHealthKit = true
        try? context.save()
        
        print("✅ Exported workout to HealthKit: \(workout.uuid)")
    }
    
    /// Export an exercise session (program workout) to HealthKit
    @MainActor
    func exportExerciseSession(_ session: ExerciseSession, context: ModelContext) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard syncEnabled else {
            print("⚠️ Sync disabled, skipping HealthKit export")
            return
        }
        
        // Check if already synced
        if session.syncedToHealthKit == true {
            print("ℹ️ Session already synced to HealthKit")
            return
        }
        
        // Ensure we have timing data
        guard let startTime = session.startTime,
              let endTime = session.endTime else {
            throw HealthKitError.missingData("Missing start/end time")
        }
        
        // Create configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        
        // Create builder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        try await builder.beginCollection(at: startTime)
        
        // Add energy if available
        if let calories = session.caloriesBurned {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantity: energyQuantity,
                start: startTime,
                end: endTime
            )
            try await builder.addSamples([energySample])
        }
        
        try await builder.endCollection(at: endTime)
        guard let workout = try await builder.finishWorkout() else {
            throw HealthKitError.missingData("Failed to create workout")
        }
        
        // Update session
        session.healthKitWorkoutId = workout.uuid.uuidString
        session.syncedToHealthKit = true
        try? context.save()
        
        print("✅ Exported exercise session to HealthKit: \(workout.uuid)")
    }
    
    /// Export a cardio session to HealthKit
    @MainActor
    func exportCardioSession(_ session: CardioSession, cardioType: CardioType, context: ModelContext) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard syncEnabled else {
            print("⚠️ Sync disabled, skipping HealthKit export")
            return
        }
        
        // Check if already synced
        if session.syncedToHealthKit == true {
            print("ℹ️ Session already synced to HealthKit")
            return
        }
        
        // Ensure we have timing data
        guard let startTime = session.startTime,
              let endTime = session.endTime else {
            throw HealthKitError.missingData("Missing start/end time")
        }
        
        // Map cardio type to HKWorkoutActivityType
        let activityType = mapCardioType(cardioType)
        
        // Create configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        
        // Create builder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        try await builder.beginCollection(at: startTime)
        
        // Add energy if available
        if let calories = session.caloriesBurned {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantity: energyQuantity,
                start: startTime,
                end: endTime
            )
            try await builder.addSamples([energySample])
        }
        
        // Add distance if available
        if let distance = session.actualDistance {
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distance * 1609.34) // miles to meters
            let distanceSample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                quantity: distanceQuantity,
                start: startTime,
                end: endTime
            )
            try await builder.addSamples([distanceSample])
        }
        
        try await builder.endCollection(at: endTime)
        guard let workout = try await builder.finishWorkout() else {
            throw HealthKitError.missingData("Failed to create workout")
        }
        
        // Update session
        session.healthKitWorkoutId = workout.uuid.uuidString
        session.syncedToHealthKit = true
        try? context.save()
        
        print("✅ Exported cardio session to HealthKit: \(workout.uuid)")
    }
    
    // MARK: - Helper Methods
    
    /// Map LIFTR cardio type to HealthKit activity type
    private func mapCardioType(_ cardioType: CardioType) -> HKWorkoutActivityType {
        switch cardioType {
        case .running:
            return .running
        case .swimming:
            return .swimming
        case .calisthenics:
            return .functionalStrengthTraining
        case .crossfit:
            return .crossTraining
        case .freeCardio:
            return .other
        }
    }
    
    // MARK: - Settings
    
    /// Enable/disable automatic sync
    func setSyncEnabled(_ enabled: Bool) {
        syncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "healthKitSyncEnabled")
    }
    
    /// Load sync settings from UserDefaults
    private func loadSyncSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "healthKitSyncEnabled")
    }
    
    /// Update last sync date
    func updateLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "healthKitLastSync")
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case missingData(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization required"
        case .missingData(let detail):
            return "Missing required data: \(detail)"
        }
    }
}
