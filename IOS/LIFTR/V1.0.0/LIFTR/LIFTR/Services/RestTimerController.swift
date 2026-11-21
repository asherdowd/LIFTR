import Foundation
import Combine
import AVFoundation
import UIKit
@preconcurrency import UserNotifications

// MARK: - Rest Timer Controller
// One rest timer per live workout screen. The screen owns it, the pinned header shows it.
// Date based (see RestClock): it survives the app being suspended. While resting it also
//  - reports the countdown to the session's Lock Screen Live Activity, and
//  - schedules a local notification for the end, so a locked phone still alerts.
// Sound and haptic fire at the end only when the app is open and the end just happened.

@MainActor
final class RestTimerController: ObservableObject {

    enum Phase {
        case idle
        case resting
        case finished   // shown briefly as "Rest over", then back to idle
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var clock: RestClock?

    private var ticker: Timer?
    private weak var sessionActivity: SessionActivityController?
    private var audioPlayer: AVAudioPlayer?
    private var playSound = true
    private var enableHaptic = true
    private var exerciseName = ""
    private var setInfo = ""

    private let notificationID = "liftr.rest.end"
    private let lateFinishTolerance: TimeInterval = 3
    private let finishedLinger: TimeInterval = 2.5
    private let addTimeSeconds: TimeInterval = 15

    // MARK: - Controls

    /// The screen's session activity, which shows the rest countdown on the Lock Screen.
    func attach(_ activity: SessionActivityController) {
        sessionActivity = activity
    }

    /// Starts a rest after a set is saved, if the owner has auto-start on.
    func startAfterSet(settings: GlobalProgressionSettings, exerciseName: String, setInfo: String) {
        guard settings.autoStartRestTimer else { return }
        start(
            duration: TimeInterval(settings.defaultRestTime),
            exerciseName: exerciseName,
            setInfo: setInfo,
            playSound: settings.restTimerSound,
            enableHaptic: settings.restTimerHaptic
        )
    }

    func start(duration: TimeInterval, exerciseName: String, setInfo: String, playSound: Bool, enableHaptic: Bool) {
        teardown(clearActivity: false)

        self.exerciseName = exerciseName.isEmpty ? "Exercise" : exerciseName
        self.setInfo = setInfo.isEmpty ? "Rest" : setInfo
        self.playSound = playSound
        self.enableHaptic = enableHaptic

        let newClock = RestClock(startedAt: Date(), duration: duration)
        clock = newClock
        phase = .resting

        startTicker()
        sessionActivity?.setRest(start: newClock.startedAt, end: newClock.endsAt)
        scheduleNotification(clock: newClock)
    }

    /// +15 s while resting.
    func addTime() {
        guard phase == .resting, let current = clock else { return }
        let extended = current.adding(addTimeSeconds)
        clock = extended
        sessionActivity?.setRest(start: extended.startedAt, end: extended.endsAt)
        scheduleNotification(clock: extended)
    }

    /// Skip: ends the rest now, with no sound.
    func skip() {
        teardown(clearActivity: true)
        clock = nil
        phase = .idle
    }

    /// Same as skip. Called when the screen is left: rest belongs to the live screen.
    func stop() {
        skip()
    }

    // MARK: - Ticking

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard phase == .resting, let current = clock else { return }
        let now = Date()
        if current.isFinished(at: now) {
            finish(clock: current, now: now)
        }
    }

    private func finish(clock finished: RestClock, now: Date) {
        ticker?.invalidate()
        ticker = nil
        phase = .finished
        removeNotification()

        // If the rest ended while the app was away, the notification already alerted.
        let endedJustNow = now.timeIntervalSince(finished.endsAt) <= lateFinishTolerance
        if endedJustNow {
            if playSound { playCompletionSound() }
            if enableHaptic {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        sessionActivity?.restFinished()

        let linger: TimeInterval = finishedLinger
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(linger * 1_000_000_000))
            guard let self = self, self.phase == .finished else { return }
            self.clock = nil
            self.phase = .idle
            self.sessionActivity?.clearRest()
        }
    }

    private func teardown(clearActivity: Bool) {
        ticker?.invalidate()
        ticker = nil
        removeNotification()
        if clearActivity { sessionActivity?.clearRest() }
    }

    // MARK: - Sound

    private func playCompletionSound() {
        guard let soundURL = Bundle.main.url(forResource: "timer_complete", withExtension: "mp3") else {
            AudioServicesPlaySystemSound(1005)
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1005)
        }
    }

    // MARK: - Local notification (alerts a locked phone at the rest end)

    private func scheduleNotification(clock: RestClock) {
        let center = UNUserNotificationCenter.current()
        let identifier = notificationID
        let title = "Rest over"
        let body = "\(exerciseName) · \(setInfo)"
        let withSound = playSound
        let seconds = max(1, clock.remaining(at: Date()))

        center.getNotificationSettings { settings in
            // Fetch the shared center inside the closure instead of capturing it (Sendable warning).
            let current = UNUserNotificationCenter.current()
            switch settings.authorizationStatus {
            case .notDetermined:
                // iOS asks once; schedule after the answer.
                current.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        RestTimerController.add(center: UNUserNotificationCenter.current(), identifier: identifier, title: title, body: body, withSound: withSound, seconds: seconds)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                RestTimerController.add(center: current, identifier: identifier, title: title, body: body, withSound: withSound, seconds: seconds)
            default:
                break
            }
        }
    }

    private nonisolated static func add(center: UNUserNotificationCenter, identifier: String, title: String, body: String, withSound: Bool, seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if withSound { content.sound = .default }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    private func removeNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
