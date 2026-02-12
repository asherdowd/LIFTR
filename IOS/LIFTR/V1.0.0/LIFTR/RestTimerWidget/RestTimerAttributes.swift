import Foundation
import ActivityKit

// MARK: - Rest Timer Live Activity Attributes

/// Attributes for the rest timer Live Activity
/// This struct defines the data that will be displayed in the lock screen and Dynamic Island
struct RestTimerAttributes: ActivityAttributes {
    
    // MARK: - Static Attributes (Don't Change During Activity)
    
    /// The exercise name (e.g., "Squat", "Bench Press")
    var exerciseName: String
    
    /// Set number (e.g., "Set 3 of 5")
    var setInfo: String
    
    // MARK: - Dynamic Content State (Changes During Activity)
    
    public struct ContentState: Codable, Hashable {
        /// The time when the timer originally started (never changes, used for progress)
        var originalStartTime: Date
        
        /// The total duration of the timer in seconds (never changes, used for progress)
        var totalDuration: Int
        
        /// The time when the current interval started (for countdown display)
        var startTime: Date
        
        /// The time when the timer will end (for countdown display)
        var endTime: Date
        
        /// Current state of the timer
        var timerState: TimerState
        
        /// Time remaining in seconds when paused (stores exact value to prevent recalculation)
        var pausedTimeRemaining: Int?
    }
    
    // MARK: - Timer State
    
    enum TimerState: String, Codable, Hashable {
        case running = "Running"
        case paused = "Paused"
        case completed = "Completed"
    }
}

// MARK: - Helper Extensions

extension RestTimerAttributes {
    /// Create attributes for a new rest timer
    static func create(exerciseName: String, setInfo: String, duration: TimeInterval) -> RestTimerAttributes {
        RestTimerAttributes(
            exerciseName: exerciseName,
            setInfo: setInfo
        )
    }
}

extension RestTimerAttributes.ContentState {
    /// Create initial content state for a timer
    static func initial(duration: TimeInterval) -> RestTimerAttributes.ContentState {
        let now = Date()
        return RestTimerAttributes.ContentState(
            originalStartTime: now,
            totalDuration: Int(duration),
            startTime: now,
            endTime: now.addingTimeInterval(duration),
            timerState: .running,
            pausedTimeRemaining: nil
        )
    }
    
    /// Create paused state with frozen time
    static func paused(originalStart: Date, totalDuration: Int, timeRemaining: Int) -> RestTimerAttributes.ContentState {
        let now = Date()
        return RestTimerAttributes.ContentState(
            originalStartTime: originalStart,
            totalDuration: totalDuration,
            startTime: now,
            endTime: now,  // Same as startTime so countdown stops
            timerState: .paused,
            pausedTimeRemaining: timeRemaining
        )
    }
    
    /// Create running state (for resume or updates)
    static func running(originalStart: Date, totalDuration: Int, timeRemaining: Int) -> RestTimerAttributes.ContentState {
        let now = Date()
        return RestTimerAttributes.ContentState(
            originalStartTime: originalStart,
            totalDuration: totalDuration,
            startTime: now,
            endTime: now.addingTimeInterval(TimeInterval(timeRemaining)),
            timerState: .running,
            pausedTimeRemaining: nil
        )
    }
    
    /// Create completed state
    static func completed(originalStart: Date, totalDuration: Int) -> RestTimerAttributes.ContentState {
        let now = Date()
        return RestTimerAttributes.ContentState(
            originalStartTime: originalStart,
            totalDuration: totalDuration,
            startTime: now,
            endTime: now,
            timerState: .completed,
            pausedTimeRemaining: 0
        )
    }
}
