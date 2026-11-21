import Foundation
import Combine
import ActivityKit

// MARK: - Session Activity Controller
// Owns the single Lock Screen / Dynamic Island Live Activity for one live workout screen.
// The activity lives for the whole session (type, name, clock, progress) and shows the rest
// countdown on top while a rest runs (RestTimerController reports rest changes here).
// The activity is optional: if Live Activities are off or the request fails, the workout
// carries on without it.

@MainActor
final class SessionActivityController: ObservableObject {

    private var activity: Activity<RestTimerAttributes>?
    private var wanted = false

    private var clockStart = Date()
    private var pausedAt: Date?
    private var progressText = ""
    private var restStart: Date?
    private var restEnd: Date?
    private var restOver = false

    // MARK: - Lifecycle

    /// Starts the activity for a running session (also after returning to a session that is still running).
    func begin(workoutType: String, name: String, progress: String, session: ExerciseSession) {
        wanted = true
        readClock(from: session)
        progressText = progress
        if activity != nil {
            push()
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RestTimerAttributes(workoutType: workoutType, exerciseName: name)
        let state = currentState()
        Task { @MainActor [weak self] in
            // An activity left over from a killed app would otherwise stay on the Lock Screen.
            for old in Activity<RestTimerAttributes>.activities {
                await old.end(nil, dismissalPolicy: .immediate)
            }
            guard let self = self, self.wanted, self.activity == nil else { return }
            do {
                self.activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                // Optional feature: the workout continues without it.
            }
        }
    }

    /// Ends the activity (workout finished, or the live screen was left).
    func end() {
        wanted = false
        clearRestFields()
        guard let current = activity else { return }
        activity = nil
        Task {
            await current.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: - Updates

    /// Pause, resume: re-reads the clock from the session.
    func sync(session: ExerciseSession) {
        readClock(from: session)
        push()
    }

    func setProgress(_ text: String) {
        progressText = text
        push()
    }

    func setRest(start: Date, end: Date) {
        restStart = start
        restEnd = end
        restOver = false
        push()
    }

    func restFinished() {
        restOver = true
        push()
    }

    func clearRest() {
        guard restStart != nil || restEnd != nil || restOver else { return }
        clearRestFields()
        push()
    }

    // MARK: - Internals

    private func readClock(from session: ExerciseSession) {
        clockStart = LiveSessionClock.activityClockStart(session)
        pausedAt = session.endTime == nil ? session.pausedAt : nil
    }

    private func clearRestFields() {
        restStart = nil
        restEnd = nil
        restOver = false
    }

    private func currentState() -> RestTimerAttributes.ContentState {
        return RestTimerAttributes.ContentState(
            clockStart: clockStart,
            pausedAt: pausedAt,
            progressText: progressText,
            restStart: restStart,
            restEnd: restEnd,
            restOver: restOver
        )
    }

    private func push() {
        guard let current = activity else { return }
        let state = currentState()
        Task {
            await current.update(.init(state: state, staleDate: nil))
        }
    }
}
