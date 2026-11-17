import Foundation
import Combine
import ActivityKit
import AVFoundation
import UIKit
import UserNotifications

// MARK: - Rest Timer Controller
// One rest timer per live workout screen. The screen owns it, the pinned header shows it.
// Date based (see RestClock): it survives the app being suspended. While resting it also
//  - mirrors the countdown to the Lock Screen Live Activity, and
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
    private var activity: Activity<RestTimerAttributes>?
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
        teardown(endActivityImmediately: true)

        self.exerciseName = exerciseName.isEmpty ? "Exercise" : exerciseName
        self.setInfo = setInfo.isEmpty ? "Rest" : setInfo
        self.playSound = playSound
        self.enableHaptic = enableHaptic

        let newClock = RestClock(startedAt: Date(), duration: duration)
        clock = newClock
        phase = .resting

        startTicker()
        startLiveActivity(clock: newClock)
        scheduleNotification(clock: newClock)
    }

    /// +15 s while resting.
    func addTime() {
        guard phase == .resting, let current = clock else { return }
        let extended = current.adding(addTimeSeconds)
        clock = extended
        updateLiveActivity(clock: extended)
        scheduleNotification(clock: extended)
    }

    /// Skip: ends the rest now, with no sound.
    func skip() {
        teardown(endActivityImmediately: true)
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
        completeLiveActivity(clock: finished)

        let linger: TimeInterval = finishedLinger
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(linger * 1_000_000_000))
            guard let self = self, self.phase == .finished else { return }
            self.clock = nil
            self.phase = .idle
        }
    }

    private func teardown(endActivityImmediately: Bool) {
        ticker?.invalidate()
        ticker = nil
        removeNotification()
        if endActivityImmediately { endLiveActivity() }
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
            switch settings.authorizationStatus {
            case .notDetermined:
                // iOS asks once; schedule after the answer.
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        RestTimerController.add(center: center, identifier: identifier, title: title, body: body, withSound: withSound, seconds: seconds)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                RestTimerController.add(center: center, identifier: identifier, title: title, body: body, withSound: withSound, seconds: seconds)
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

    // MARK: - Live Activity (Lock Screen / Dynamic Island mirror)

    private func startLiveActivity(clock: RestClock) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RestTimerAttributes(exerciseName: exerciseName, setInfo: setInfo)
        let state = RestTimerAttributes.ContentState.initial(duration: clock.totalSeconds)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // The Live Activity is optional: the rest continues without it.
        }
    }

    private func updateLiveActivity(clock: RestClock) {
        guard let activity = activity else { return }
        let state = RestTimerAttributes.ContentState.running(
            originalStart: clock.startedAt,
            totalDuration: Int(clock.totalSeconds),
            timeRemaining: Int(clock.remaining(at: Date()).rounded(.up))
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private func completeLiveActivity(clock: RestClock) {
        guard let activity = activity else { return }
        let state = RestTimerAttributes.ContentState.completed(
            originalStart: clock.startedAt,
            totalDuration: Int(clock.totalSeconds)
        )
        self.activity = nil
        Task {
            await activity.update(.init(state: state, staleDate: nil))
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .default)
        }
    }

    private func endLiveActivity() {
        guard let activity = activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
