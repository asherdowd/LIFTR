import Foundation
import ActivityKit

// MARK: - Session Live Activity attributes
// One Live Activity covers a whole live workout session (Strength or Cardio): the session clock
// between sets, and the rest countdown while resting. The type keeps its original name because
// this file is shared by the app and the widget extension through project membership.
//
// Everything on the Lock Screen counts from DATES, so the system keeps the clock and the rest
// countdown running with no app updates. The app only pushes an update when something changes:
// pause, resume, a set saved, a rest starting, +15s, skip, or rest over.

struct RestTimerAttributes: ActivityAttributes {

    /// Static for the whole activity.
    /// "Strength" or "Cardio".
    var workoutType: String

    /// Exercise or activity name, e.g. "Squat" or "Running".
    var exerciseName: String

    public struct ContentState: Codable, Hashable {
        /// Session clock start shifted by paused time: elapsed = now - clockStart.
        var clockStart: Date

        /// Set while the session clock is paused: the clock stays frozen at this moment.
        var pausedAt: Date?

        /// "2 of 5 sets", "3 sets" or empty (cardio).
        var progressText: String

        /// Rest countdown window. nil when not resting.
        var restStart: Date?
        var restEnd: Date?

        /// True for a short moment when a rest has just ended ("Rest over").
        var restOver: Bool
    }
}

extension RestTimerAttributes {
    static let strengthType = "Strength"
    static let cardioType = "Cardio"
}

extension RestTimerAttributes.ContentState {
    var isResting: Bool { restStart != nil && restEnd != nil && !restOver }
    var isPaused: Bool { pausedAt != nil }

    /// Range for the system-driven elapsed clock (counts up, freezes at pausedAt).
    var clockRange: ClosedRange<Date> {
        return clockStart...clockStart.addingTimeInterval(24 * 3600)
    }

    /// Range for the system-driven rest countdown. Only call when isResting.
    var restRange: ClosedRange<Date> {
        let start: Date = restStart ?? clockStart
        let end: Date = restEnd ?? start
        return start...max(start, end)
    }
}
