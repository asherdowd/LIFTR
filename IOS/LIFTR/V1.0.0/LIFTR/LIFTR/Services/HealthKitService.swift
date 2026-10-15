import Foundation
import HealthKit

// MARK: - HealthKit Service (read-only)
// Reads finished workouts from Apple Health. Nothing is written to Health (decision
// 2026-10-14: read now, write later). Values are returned in SI units: meters, seconds,
// bpm, kcal. Mapping into the Workout model lives in HealthImportService so it can be tested
// without a device.

/// One workout read from Health, already reduced to the numbers LIFTR stores.
struct ImportedActivity: Equatable {
    /// Health workout UUID string, used to avoid importing the same workout twice.
    let externalID: String
    /// Display name used for the exercise, for example "Running" or "Hiking".
    let activityName: String
    let start: Date
    let end: Date
    let duration: TimeInterval
    let distance: Double?
    let elevationGain: Double?
    let avgHeartRate: Double?
    let maxHeartRate: Double?
    let caloriesBurned: Double?
    /// Meters descended, from the workout metadata when the writing app stored it.
    let elevationLoss: Double?
    /// Meters per second, from the workout metadata when the writing app stored it.
    let maxSpeed: Double?
}

enum HealthKitServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Health data is not available on this device."
        }
    }
}

final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        let identifiers: [HKQuantityTypeIdentifier] = [
            .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
            .activeEnergyBurned, .heartRate
        ]
        for identifier in identifiers {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }
        return types
    }

    /// Shows the system permission sheet. Health never reveals whether READ access was granted,
    /// so a successful return only means the sheet was handled.
    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitServiceError.unavailable }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    /// Cardio-type workouts that ended on or after `since`, newest first.
    func fetchActivities(since: Date, limit: Int = 200) async throws -> [ImportedActivity] {
        guard isAvailable else { throw HealthKitServiceError.unavailable }

        let datePredicate = HKQuery.predicateForSamples(withStart: since, end: nil, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(datePredicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: limit
        )
        let workouts = try await descriptor.result(for: store)

        var result: [ImportedActivity] = []
        for workout in workouts {
            guard let name = Self.activityName(for: workout.workoutActivityType) else { continue }
            let heart = await heartRate(from: workout.startDate, to: workout.endDate)
            result.append(ImportedActivity(
                externalID: workout.uuid.uuidString,
                activityName: name,
                start: workout.startDate,
                end: workout.endDate,
                duration: workout.duration,
                distance: distance(of: workout),
                elevationGain: elevationGain(of: workout),
                avgHeartRate: heart.avg,
                maxHeartRate: heart.max,
                caloriesBurned: calories(of: workout),
                elevationLoss: elevationLoss(of: workout),
                maxSpeed: maxSpeed(of: workout)
            ))
        }
        return result
    }

    // MARK: Reading values

    private func distance(of workout: HKWorkout) -> Double? {
        let identifiers: [HKQuantityTypeIdentifier] = [.distanceWalkingRunning, .distanceCycling, .distanceSwimming]
        for identifier in identifiers {
            let type = HKQuantityType(identifier)
            if let meters = workout.statistics(for: type)?.sumQuantity()?.doubleValue(for: .meter()), meters > 0 {
                return meters
            }
        }
        return nil
    }

    private func calories(of workout: HKWorkout) -> Double? {
        let type = HKQuantityType(.activeEnergyBurned)
        guard let kcal = workout.statistics(for: type)?.sumQuantity()?.doubleValue(for: .kilocalorie()), kcal > 0 else {
            return nil
        }
        return kcal
    }

    /// Only present when the app that wrote the workout stored it in the metadata.
    private func elevationGain(of workout: HKWorkout) -> Double? {
        guard let quantity = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity else { return nil }
        let meters = quantity.doubleValue(for: .meter())
        return meters > 0 ? meters : nil
    }

    /// Garmin stores these under the raw keys "HKElevationDescended" and "HKMaximumSpeed"
    /// (seen in an Apple Health export on 2026-10-15). Read by raw key so nothing depends on
    /// whether a named constant exists.
    private func elevationLoss(of workout: HKWorkout) -> Double? {
        guard let quantity = workout.metadata?["HKElevationDescended"] as? HKQuantity else { return nil }
        let meters = quantity.doubleValue(for: .meter())
        return meters > 0 ? meters : nil
    }

    private func maxSpeed(of workout: HKWorkout) -> Double? {
        guard let quantity = workout.metadata?["HKMaximumSpeed"] as? HKQuantity else { return nil }
        let speed = quantity.doubleValue(for: HKUnit.meter().unitDivided(by: .second()))
        return speed > 0 ? speed : nil
    }

    /// Average and maximum heart rate over the workout's time window, whatever app wrote them.
    private func heartRate(from start: Date, to end: Date) async -> (avg: Double?, max: Double?) {
        let type = HKQuantityType(.heartRate)
        let window = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: window),
            options: [.discreteAverage, .discreteMax]
        )
        guard let statistics = try? await descriptor.result(for: store) else { return (nil, nil) }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return (
            statistics.averageQuantity()?.doubleValue(for: unit),
            statistics.maximumQuantity()?.doubleValue(for: unit)
        )
    }

    // MARK: Activity types

    /// Only cardio-style activities are imported in this slice. Returns nil for the rest
    /// (including strength training, which LIFTR records itself).
    static func activityName(for type: HKWorkoutActivityType) -> String? {
        switch type {
        case .running: return "Running"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .rowing: return "Rowing"
        case .elliptical: return "Elliptical"
        default: return nil
        }
    }
}
