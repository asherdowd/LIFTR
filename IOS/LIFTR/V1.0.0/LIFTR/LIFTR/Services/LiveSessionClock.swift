import Foundation

// MARK: - Live Session Clock
// Date-based clock for a live workout session, shared by every live screen. Nothing ticks in
// memory: elapsed time is always computed from stored dates, so it stays correct when the app
// is suspended or relaunched. Pure model logic: no fetches, no saves (the caller saves).
//
// Stored on ExerciseSession: startTime, endTime, pausedSeconds (total paused so far) and
// pausedAt (when the current pause began, nil while running).

enum LiveSessionClock {

    /// A running session older than this is treated as possibly abandoned (asks "Still working out?").
    static let staleAfterSeconds: TimeInterval = 6 * 3600

    /// Not started yet: the screen shows the plan and a Start button, and sets cannot be logged.
    static func needsStart(_ session: ExerciseSession) -> Bool {
        return !session.isDone && session.startTime == nil
    }

    /// Started and not finished.
    static func isRunningSession(_ session: ExerciseSession) -> Bool {
        return !session.isDone && session.startTime != nil
    }

    static func isPaused(_ session: ExerciseSession) -> Bool {
        return session.pausedAt != nil && session.endTime == nil
    }

    static func start(_ session: ExerciseSession, now: Date = Date()) {
        guard session.startTime == nil else { return }
        session.startTime = now
        session.pausedAt = nil
    }

    static func pause(_ session: ExerciseSession, now: Date = Date()) {
        guard isRunningSession(session), session.pausedAt == nil else { return }
        session.pausedAt = now
    }

    static func resume(_ session: ExerciseSession, now: Date = Date()) {
        guard let pausedAt = session.pausedAt else { return }
        let gap: TimeInterval = max(0, now.timeIntervalSince(pausedAt))
        session.pausedSeconds = (session.pausedSeconds ?? 0) + gap
        session.pausedAt = nil
    }

    /// Seconds of active time: start to end (or now, or the moment the current pause began),
    /// minus all paused time. Zero before Start.
    static func elapsed(_ session: ExerciseSession, now: Date = Date()) -> TimeInterval {
        guard let start = session.startTime else { return 0 }
        var end: Date = now
        if let endTime = session.endTime {
            end = endTime
        } else if let pausedAt = session.pausedAt {
            end = pausedAt
        }
        let total: TimeInterval = end.timeIntervalSince(start) - (session.pausedSeconds ?? 0)
        return max(0, total)
    }

    /// Called from the one place every completion path ends up (checkAndAdvanceWeek).
    /// Stamps the end time if none was set and folds a pause still open into the paused total.
    static func close(_ session: ExerciseSession, at fallbackEnd: Date) {
        if session.endTime == nil { session.endTime = fallbackEnd }
        if let pausedAt = session.pausedAt, let end = session.endTime {
            let gap: TimeInterval = max(0, end.timeIntervalSince(pausedAt))
            session.pausedSeconds = (session.pausedSeconds ?? 0) + gap
            session.pausedAt = nil
        }
    }

    /// Possibly abandoned: running (not paused), has logged sets, and active time passed the limit.
    static func isStale(_ session: ExerciseSession, now: Date = Date()) -> Bool {
        guard isRunningSession(session), session.pausedAt == nil, session.hasLoggedSets else { return false }
        return elapsed(session, now: now) > staleAfterSeconds
    }

    /// "Still working out?" > Finish: the owner states how long the workout really was.
    /// Sets the end time so that active time equals that duration (never later than now).
    static func setEnd(_ session: ExerciseSession, durationSeconds: TimeInterval, now: Date = Date()) {
        guard let start = session.startTime else { return }
        let wanted: Date = start.addingTimeInterval((session.pausedSeconds ?? 0) + max(0, durationSeconds))
        session.endTime = min(wanted, now)
    }

    /// The date elapsed time counts from: start shifted by paused time, so that
    /// elapsed = now - activityClockStart. The Lock Screen Live Activity counts from this date
    /// (and freezes at pausedAt), which keeps it equal to elapsed(_:now:) with no app updates.
    static func activityClockStart(_ session: ExerciseSession) -> Date {
        let start: Date = session.startTime ?? Date()
        return start.addingTimeInterval(session.pausedSeconds ?? 0)
    }

    /// "42:07" or "1:05:09".
    static func format(_ seconds: TimeInterval) -> String {
        let total: Int = max(0, Int(seconds))
        let hours: Int = total / 3600
        let minutes: Int = (total % 3600) / 60
        let secs: Int = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
