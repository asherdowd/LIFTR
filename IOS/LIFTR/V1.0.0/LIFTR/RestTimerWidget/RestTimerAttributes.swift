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
        /// The time when the timer started
        var startTime: Date
        
        /// The time when the timer will end
        var endTime: Date
        
        /// Current state of the timer
        var timerState: TimerState
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
            startTime: now,
            endTime: now.addingTimeInterval(duration),
            timerState: .running
        )
    }
    
    /// Create paused state
    func paused() -> RestTimerAttributes.ContentState {
        RestTimerAttributes.ContentState(
            startTime: self.startTime,
            endTime: self.endTime,
            timerState: .paused
        )
    }
    
    /// Create resumed state with adjusted end time
    func resumed(remainingTime: TimeInterval) -> RestTimerAttributes.ContentState {
        let now = Date()
        return RestTimerAttributes.ContentState(
            startTime: now,
            endTime: now.addingTimeInterval(remainingTime),
            timerState: .running
        )
    }
    
    /// Create completed state
    func completed() -> RestTimerAttributes.ContentState {
        RestTimerAttributes.ContentState(
            startTime: self.startTime,
            endTime: self.endTime,
            timerState: .completed
        )
    }
}
