import Foundation

// MARK: - Rest Clock
// Pure date maths for the rest timer. Nothing ticks in memory: remaining time is always the
// end date minus now, so it stays correct after the app was suspended. No fetches, no saves.

struct RestClock: Equatable {
    let startedAt: Date
    let endsAt: Date

    init(startedAt: Date, duration: TimeInterval) {
        self.startedAt = startedAt
        self.endsAt = startedAt.addingTimeInterval(max(0, duration))
    }

    private init(startedAt: Date, endsAt: Date) {
        self.startedAt = startedAt
        self.endsAt = endsAt
    }

    /// Length of the rest including any time added.
    var totalSeconds: TimeInterval {
        return max(0, endsAt.timeIntervalSince(startedAt))
    }

    func remaining(at now: Date) -> TimeInterval {
        return max(0, endsAt.timeIntervalSince(now))
    }

    func isFinished(at now: Date) -> Bool {
        return now >= endsAt
    }

    /// 0 at the start, 1 when finished.
    func progress(at now: Date) -> Double {
        let total: TimeInterval = totalSeconds
        guard total > 0 else { return 1 }
        let done: TimeInterval = total - remaining(at: now)
        return min(1, max(0, done / total))
    }

    /// The same rest with more time on the end.
    func adding(_ seconds: TimeInterval) -> RestClock {
        return RestClock(startedAt: startedAt, endsAt: endsAt.addingTimeInterval(seconds))
    }

    /// "1:12". Rounds up, so 0:00 only shows once the rest is really over.
    static func format(_ seconds: TimeInterval) -> String {
        let total: Int = Int(max(0, seconds).rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
