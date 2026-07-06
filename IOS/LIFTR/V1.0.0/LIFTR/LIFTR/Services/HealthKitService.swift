import Foundation
import HealthKit
import SwiftData

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorizedStatus: Bool = false
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.checkAuthorizationStatus()
                completion(success, error)
            }
        }
    }
    
    // MARK: - Check Authorization Status
    
    func checkAuthorizationStatus() {
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        DispatchQueue.main.async {
            self.isAuthorizedStatus = (status == .sharingAuthorized)
        }
    }
    
    func isAuthorized() -> Bool {
        return isAuthorizedStatus
    }
    
    // MARK: - Save Workout (V2)
    
    /// Saves a ScheduledWorkout to HealthKit
    func saveWorkout(
        from scheduledWorkout: ScheduledWorkout,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        guard let startTime = scheduledWorkout.startTime,
              let endTime = scheduledWorkout.endTime else {
            completion(false, nil, NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Workout must have start and end times"]))
            return
        }
        
        // Determine workout activity type based on exercises
        let activityType: HKWorkoutActivityType
        switch scheduledWorkout.workoutType {
        case .strength:
            activityType = .traditionalStrengthTraining
        case .cardio:
            activityType = .running  // Default, could be more specific
        case .mixed:
            activityType = .mixedCardio
        }
        
        let metadata: [String: Any] = [
            "AppName": "LIFTR",
            "WorkoutID": scheduledWorkout.id.uuidString
        ]
        
        let energyBurned = scheduledWorkout.caloriesBurned.map {
            HKQuantity(unit: .kilocalorie(), doubleValue: $0)
        }
        
        // Suppress deprecation warning - we're using the simple API intentionally
        // Will migrate to HKWorkoutBuilder when we need more advanced features
        let workout = HKWorkout(
            activityType: activityType,
            start: startTime,
            end: endTime,
            duration: scheduledWorkout.totalDuration ?? 0,
            totalEnergyBurned: energyBurned,
            totalDistance: nil,
            metadata: metadata
        )
        
        healthStore.save(workout) { success, error in
            if success {
                completion(true, workout.uuid.uuidString, nil)
            } else {
                completion(false, nil, error)
            }
        }
    }
    
    // MARK: - Delete Workout
    
    func deleteWorkout(healthKitWorkoutId: String, completion: @escaping (Bool, Error?) -> Void) {
        let predicate = HKQuery.predicateForObject(with: UUID(uuidString: healthKitWorkoutId)!)
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] query, samples, error in
            guard let workout = samples?.first as? HKWorkout else {
                completion(false, error)
                return
            }
            
            self?.healthStore.delete(workout) { success, error in
                completion(success, error)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Recent Workouts
    
    func fetchRecentWorkouts(limit: Int = 10, completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: nil,
            limit: limit,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            completion(samples as? [HKWorkout], error)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Sync Status Helpers
    
    /// Mark a ScheduledWorkout as synced to HealthKit
    static func markAsSynced(scheduledWorkout: ScheduledWorkout, healthKitWorkoutId: String, context: ModelContext) {
        scheduledWorkout.healthKitWorkoutId = healthKitWorkoutId
        scheduledWorkout.syncedToHealthKit = true
        try? context.save()
    }
    
    /// Mark a ScheduledWorkout as unsynced (e.g., after deletion)
    static func markAsUnsynced(scheduledWorkout: ScheduledWorkout, context: ModelContext) {
        scheduledWorkout.healthKitWorkoutId = nil
        scheduledWorkout.syncedToHealthKit = false
        try? context.save()
    }
}

// MARK: - Extensions

extension HKWorkout {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedCalories: String? {
        guard let calories = totalEnergyBurned?.doubleValue(for: .kilocalorie()) else {
            return nil
        }
        return String(format: "%.0f cal", calories)
    }
}
