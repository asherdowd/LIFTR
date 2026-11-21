import Foundation
import Combine
import CoreLocation
import CoreMotion

// MARK: - Live Route Recorder
// Records GPS position and barometer altitude for the ONE cardio session that is running.
// App-wide (not owned by a screen), so recording continues while the live screen is left, and it
// keeps going with the screen locked (location background mode). Nothing here touches SwiftData:
// it only knows the session's UUID. The live screen reads the numbers, and when the workout is
// finished it takes the snapshot and stores it on the session.
//
// While recording it writes a checkpoint file every 30 s, so a run survives the app being killed:
// opening the session again continues from the checkpoint (the gap is not counted as distance).

@MainActor
final class LiveRouteRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LiveRouteRecorder()

    /// A reading reduced to plain values, so nothing non-Sendable crosses threads.
    private struct Reading: Sendable {
        let lat: Double
        let lon: Double
        let time: TimeInterval
        let accuracy: Double
    }

    @Published private(set) var sessionID: UUID?
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var elevationGain: Double = 0
    @Published private(set) var elevationLoss: Double = 0
    @Published private(set) var coordinates: [CLLocationCoordinate2D] = []
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    /// True once a usable position has arrived for this recording.
    @Published private(set) var hasFix: Bool = false

    private let manager = CLLocationManager()
    private let altimeter = CMAltimeter()
    private var route = RouteAccumulator()
    private var elevation = ElevationAccumulator()
    private var hasElevation = false
    private var paused = false
    private var updating = false
    private var beganAt = Date()
    private var lastCheckpoint = Date.distantPast

    private let checkpointEvery: TimeInterval = 30
    private let maxRecordingSeconds: TimeInterval = 12 * 3600

    private override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.pausesLocationUpdatesAutomatically = false
        authorization = manager.authorizationStatus
    }

    /// The device can measure elevation change (barometer).
    static var hasBarometer: Bool {
        return CMAltimeter.isRelativeAltitudeAvailable()
    }

    var isAuthorized: Bool {
        return authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var isDenied: Bool {
        return authorization == .denied || authorization == .restricted
    }

    // MARK: - Control

    /// Starts (or continues) recording for a running session. Safe to call again for the same session.
    func begin(sessionID newID: UUID) {
        if sessionID == newID { return }
        if sessionID != nil {
            // A different run was recording: stop it and keep its checkpoint.
            stopUpdates()
            saveCheckpoint()
        }
        sessionID = newID

        let restored: RouteSnapshot = RouteStore.load(for: newID) ?? RouteSnapshot()
        route = restored.route
        elevation = restored.elevation
        // Time passed while nothing was recording: do not count the jump.
        route.breakSegment()
        elevation.rebase()
        hasElevation = restored.hasElevation || CMAltimeter.isRelativeAltitudeAvailable()
        rebuildPublished()
        hasFix = false

        paused = false
        beganAt = Date()
        authorization = manager.authorizationStatus
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        startUpdates()
    }

    /// Follows the session clock: no recording while paused.
    func setPaused(_ value: Bool) {
        guard sessionID != nil, value != paused else { return }
        paused = value
        if value {
            stopUpdates()
            saveCheckpoint()
        } else {
            startUpdates()
        }
    }

    func snapshot() -> RouteSnapshot {
        return RouteSnapshot(route: route, elevation: elevation, hasElevation: hasElevation)
    }

    /// Stops recording and returns everything recorded. The checkpoint file is removed.
    func finish() -> RouteSnapshot? {
        guard let id = sessionID else { return nil }
        let result: RouteSnapshot = snapshot()
        stopUpdates()
        RouteStore.remove(for: id)
        reset()
        return result
    }

    /// The workout was deleted: stop if it is the one recording, and remove its checkpoint.
    func discard(sessionIDs: [UUID]) {
        if let current = sessionID, sessionIDs.contains(current) {
            stopUpdates()
            reset()
        }
        for id in sessionIDs {
            RouteStore.remove(for: id)
        }
    }

    // MARK: - Updates

    private func startUpdates() {
        guard sessionID != nil, !paused, !updating, isAuthorized else { return }

        // Background updates need the location background mode in Info.plist: without it,
        // turning them on would crash, so check first.
        if let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
           modes.contains("location") {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }
        manager.startUpdatingLocation()
        startAltimeter()
        updating = true
    }

    private func stopUpdates() {
        guard updating else { return }
        manager.stopUpdatingLocation()
        altimeter.stopRelativeAltitudeUpdates()
        updating = false
        // The next reading starts a new segment and a new altitude reference.
        route.breakSegment()
        elevation.rebase()
    }

    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] data, _ in
            guard let meters = data?.relativeAltitude.doubleValue else { return }
            Task { @MainActor in
                self?.handleAltitude(meters)
            }
        }
    }

    private func handle(_ readings: [Reading]) {
        guard sessionID != nil, !paused else { return }
        var accepted = false
        for reading in readings {
            if reading.accuracy >= 0 && reading.accuracy <= RouteAccumulator.maxAccuracy {
                hasFix = true
            }
            if route.add(lat: reading.lat, lon: reading.lon, time: reading.time, accuracy: reading.accuracy) {
                if let point = route.points.last {
                    coordinates.append(CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon))
                }
                accepted = true
            }
        }
        if accepted {
            distanceMeters = route.distance
            checkpointIfDue()
        }
        if Date().timeIntervalSince(beganAt) > maxRecordingSeconds {
            // Safety stop for a run that was forgotten: keep what was recorded.
            paused = true
            stopUpdates()
            saveCheckpoint()
        }
    }

    private func handleAltitude(_ meters: Double) {
        guard sessionID != nil, !paused else { return }
        elevation.add(altitude: meters)
        elevationGain = elevation.gain
        elevationLoss = elevation.loss
    }

    private func authorizationChanged(_ status: CLAuthorizationStatus) {
        authorization = status
        startUpdates()
    }

    // MARK: - State

    private func rebuildPublished() {
        distanceMeters = route.distance
        elevationGain = elevation.gain
        elevationLoss = elevation.loss
        var list: [CLLocationCoordinate2D] = []
        list.reserveCapacity(route.points.count)
        for point in route.points {
            list.append(CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon))
        }
        coordinates = list
    }

    private func reset() {
        sessionID = nil
        route = RouteAccumulator()
        elevation = ElevationAccumulator()
        hasElevation = false
        paused = false
        hasFix = false
        distanceMeters = 0
        elevationGain = 0
        elevationLoss = 0
        coordinates = []
    }

    private func saveCheckpoint() {
        guard let id = sessionID else { return }
        RouteStore.save(snapshot(), for: id)
        lastCheckpoint = Date()
    }

    private func checkpointIfDue() {
        if Date().timeIntervalSince(lastCheckpoint) >= checkpointEvery {
            saveCheckpoint()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var readings: [Reading] = []
        for location in locations {
            readings.append(Reading(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude,
                time: location.timestamp.timeIntervalSince1970,
                accuracy: location.horizontalAccuracy
            ))
        }
        Task { @MainActor in
            self.handle(readings)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationChanged(status)
        }
    }
}
