import Foundation

// MARK: - Route tracking logic (pure: no GPS, no SwiftData)
// Everything that turns raw location and barometer readings into distance, elevation gain and
// loss, and a stored route. The live recorder (LiveRouteRecorder) feeds these types and the
// unit tests exercise them directly. Units are SI: meters and seconds.

/// One recorded position.
struct RoutePoint: Codable, Equatable {
    var lat: Double
    var lon: Double
    /// Seconds since 1970.
    var time: TimeInterval
}

// MARK: - Distance and route

struct RouteAccumulator: Codable, Equatable {

    private(set) var points: [RoutePoint] = []
    /// Total distance in meters over accepted points. Never counts the jump across a gap.
    private(set) var distance: Double = 0
    private var gapPending = false

    /// Readings less accurate than this (meters) are ignored.
    static let maxAccuracy: Double = 50
    /// Moves shorter than this, or shorter than the reading's own accuracy, are treated as GPS wander.
    static let minStep: Double = 5
    /// Faster than this (m/s) is a GPS jump, not movement.
    static let maxSpeed: Double = 25

    /// Adds a reading. Returns true if it was accepted as a route point.
    @discardableResult
    mutating func add(lat: Double, lon: Double, time: TimeInterval, accuracy: Double) -> Bool {
        guard accuracy >= 0, accuracy <= RouteAccumulator.maxAccuracy else { return false }

        guard let last = points.last else {
            points.append(RoutePoint(lat: lat, lon: lon, time: time))
            gapPending = false
            return true
        }
        guard time > last.time else { return false }

        let step: Double = RouteAccumulator.meters(fromLat: last.lat, lon: last.lon, toLat: lat, lon: lon)

        if gapPending {
            // First reading after a pause: start a new segment without adding the jump.
            points.append(RoutePoint(lat: lat, lon: lon, time: time))
            gapPending = false
            return true
        }

        let threshold: Double = max(RouteAccumulator.minStep, accuracy)
        guard step >= threshold else { return false }
        guard step / (time - last.time) <= RouteAccumulator.maxSpeed else { return false }

        distance += step
        points.append(RoutePoint(lat: lat, lon: lon, time: time))
        return true
    }

    /// Call when recording stops for a pause (or the app was away): the next point starts a new
    /// segment instead of adding the straight line between the two positions.
    mutating func breakSegment() {
        gapPending = true
    }

    /// At most `maxPoints` points for storage, always keeping the first and last.
    func thinned(maxPoints: Int) -> [RoutePoint] {
        guard maxPoints >= 2, points.count > maxPoints else { return points }
        let step: Int = Int((Double(points.count - 1) / Double(maxPoints - 1)).rounded(.up))
        var result: [RoutePoint] = []
        var index: Int = 0
        while index < points.count {
            result.append(points[index])
            index += step
        }
        if let last = points.last, result.last != last {
            result.append(last)
        }
        return result
    }

    /// Great-circle distance between two coordinates, in meters (haversine).
    static func meters(fromLat lat1: Double, lon lon1: Double, toLat lat2: Double, lon lon2: Double) -> Double {
        let earthRadius: Double = 6_371_000
        let toRadians: Double = Double.pi / 180
        let dLat: Double = (lat2 - lat1) * toRadians
        let dLon: Double = (lon2 - lon1) * toRadians
        let a: Double = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * toRadians) * cos(lat2 * toRadians) * sin(dLon / 2) * sin(dLon / 2)
        let c: Double = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}

// MARK: - Elevation

/// Elevation gain and loss from relative altitude samples (the barometer). A change only counts
/// once it exceeds `threshold`, which filters the small noise in every sample.
struct ElevationAccumulator: Codable, Equatable {

    private(set) var gain: Double = 0
    private(set) var loss: Double = 0
    private var reference: Double?

    static let threshold: Double = 1.0

    mutating func add(altitude: Double) {
        guard let ref = reference else {
            reference = altitude
            return
        }
        let change: Double = altitude - ref
        if change >= ElevationAccumulator.threshold {
            gain += change
            reference = altitude
        } else if change <= -ElevationAccumulator.threshold {
            loss += -change
            reference = altitude
        }
    }

    /// The barometer's relative altitude restarts from zero whenever updates restart (after a
    /// pause), so the next sample becomes the new reference.
    mutating func rebase() {
        reference = nil
    }
}

// MARK: - Snapshot

/// Everything recorded so far for one session. Saved to disk as a checkpoint while recording.
struct RouteSnapshot: Codable, Equatable {
    var route: RouteAccumulator = RouteAccumulator()
    var elevation: ElevationAccumulator = ElevationAccumulator()
    /// False when the device has no barometer: gain and loss are then not recorded.
    var hasElevation: Bool = false
}

// MARK: - Stored route (blob on ExerciseSession)

enum RouteCodec {

    static let maxStoredPoints: Int = 2_000

    /// [[lat, lon, time], ...] as JSON, compressed. Nil when there is no route to store.
    static func encode(_ points: [RoutePoint]) -> Data? {
        guard points.count >= 2 else { return nil }
        var rows: [[Double]] = []
        rows.reserveCapacity(points.count)
        for point in points {
            rows.append([point.lat, point.lon, point.time])
        }
        guard let json = try? JSONEncoder().encode(rows) else { return nil }
        guard let packed = try? (json as NSData).compressed(using: .lzfse) else { return nil }
        return packed as Data
    }

    static func decode(_ data: Data) -> [RoutePoint] {
        guard let unpacked = try? (data as NSData).decompressed(using: .lzfse) else { return [] }
        guard let rows = try? JSONDecoder().decode([[Double]].self, from: unpacked as Data) else { return [] }
        var points: [RoutePoint] = []
        points.reserveCapacity(rows.count)
        for row in rows where row.count == 3 {
            points.append(RoutePoint(lat: row[0], lon: row[1], time: row[2]))
        }
        return points
    }
}

// MARK: - Checkpoint file (survives the app being killed mid-run)

enum RouteStore {

    static func directory() -> URL {
        let base: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("RouteCheckpoints", isDirectory: true)
    }

    static func fileURL(for sessionID: UUID, in directory: URL = RouteStore.directory()) -> URL {
        return directory.appendingPathComponent("route-\(sessionID.uuidString).json")
    }

    static func save(_ snapshot: RouteSnapshot, for sessionID: UUID, in directory: URL = RouteStore.directory()) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL(for: sessionID, in: directory), options: .atomic)
        } catch {
            // A missed checkpoint only costs the points since the last one.
        }
    }

    static func load(for sessionID: UUID, in directory: URL = RouteStore.directory()) -> RouteSnapshot? {
        guard let data = try? Data(contentsOf: fileURL(for: sessionID, in: directory)) else { return nil }
        return try? JSONDecoder().decode(RouteSnapshot.self, from: data)
    }

    static func remove(for sessionID: UUID, in directory: URL = RouteStore.directory()) {
        try? FileManager.default.removeItem(at: fileURL(for: sessionID, in: directory))
    }
}

// MARK: - Display text

enum RouteFormat {

    static let metersPerMile: Double = 1_609.344
    static let feetPerMeter: Double = 3.28084

    /// "3.12 mi" or "5.02 km".
    static func distance(_ meters: Double, useMetric: Bool) -> String {
        let value: Double = useMetric ? meters / 1_000 : meters / metersPerMile
        return String(format: "%.2f %@", value, useMetric ? "km" : "mi")
    }

    /// Just the number in the user's unit, for the Stop form ("3.12").
    static func distanceNumber(_ meters: Double, useMetric: Bool) -> String {
        let value: Double = useMetric ? meters / 1_000 : meters / metersPerMile
        return String(format: "%.2f", value)
    }

    /// "85 ft" or "26 m".
    static func elevation(_ meters: Double, useMetric: Bool) -> String {
        if useMetric { return String(format: "%.0f m", meters) }
        return String(format: "%.0f ft", meters * feetPerMeter)
    }
}
