import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Rest Timer Live Activity Widget

struct RestTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock Screen UI
            LockScreenRestTimerView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.1))
                .activitySystemActionForegroundColor(Color.blue)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (when user long-presses Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.exerciseName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(context.attributes.setInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Show countdown only when running, static when paused
                        if context.state.timerState == .running {
                            Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(timerColor(for: context))
                        } else {
                            Text(formattedTime(context: context))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(timerColor(for: context))
                        }
                        
                        Text(context.state.timerState.rawValue.uppercased())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Progress bar
                    TimerProgressBar(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.blue)
                        Text("Rest Period")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
            } compactLeading: {
                // Compact Leading (left side of Dynamic Island)
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                
            } compactTrailing: {
                // Compact Trailing (right side of Dynamic Island)
                if context.state.timerState == .running {
                    Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundColor(timerColor(for: context))
                        .frame(width: 50)
                } else {
                    Text(formattedTime(context: context))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundColor(timerColor(for: context))
                        .frame(width: 50)
                }
                
            } minimal: {
                // Minimal (when multiple Live Activities are active)
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
            .keylineTint(.blue)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Format time as MM:SS for static display
    /// Uses pausedTimeRemaining when paused to prevent recalculation
    private func formattedTime(context: ActivityViewContext<RestTimerAttributes>) -> String {
        let remaining: Int
        
        // When paused, use stored value to prevent countdown
        if context.state.timerState == .paused, let pausedTime = context.state.pausedTimeRemaining {
            remaining = pausedTime
        } else if context.state.timerState == .completed {
            remaining = 0
        } else {
            // Running - calculate from dates
            remaining = max(0, Int(context.state.endTime.timeIntervalSince(Date())))
        }
        
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Determine timer color based on time remaining
    private func timerColor(for context: ActivityViewContext<RestTimerAttributes>) -> Color {
        let timeRemaining: Int
        
        if context.state.timerState == .paused, let pausedTime = context.state.pausedTimeRemaining {
            timeRemaining = pausedTime
        } else if context.state.timerState == .completed {
            timeRemaining = 0
        } else {
            timeRemaining = max(0, Int(context.state.endTime.timeIntervalSince(Date())))
        }
        
        if context.state.timerState == .completed {
            return .green
        } else if timeRemaining <= 10 {
            return .red
        } else if timeRemaining <= 30 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenRestTimerView: View {
    let context: ActivityViewContext<RestTimerAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Exercise info
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.exerciseName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(context.attributes.setInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Timer display
            HStack {
                Spacer()
                
                VStack(spacing: 4) {
                    // Show countdown only when running, static when paused/completed
                    if context.state.timerState == .running {
                        Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(timerColor)
                    } else {
                        Text(formattedTime)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(timerColor)
                    }
                    
                    Text(context.state.timerState.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress bar
            TimerProgressBar(context: context)
                .frame(height: 8)
        }
        .padding()
    }
    
    /// Format time as MM:SS for static display
    /// Uses pausedTimeRemaining when paused to prevent recalculation
    private var formattedTime: String {
        let remaining: Int
        
        // When paused, use stored value to prevent countdown
        if context.state.timerState == .paused, let pausedTime = context.state.pausedTimeRemaining {
            remaining = pausedTime
        } else if context.state.timerState == .completed {
            remaining = 0
        } else {
            // Running - calculate from dates
            remaining = max(0, Int(context.state.endTime.timeIntervalSince(Date())))
        }
        
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Determine timer color based on time remaining
    private var timerColor: Color {
        let timeRemaining: Int
        
        if context.state.timerState == .paused, let pausedTime = context.state.pausedTimeRemaining {
            timeRemaining = pausedTime
        } else if context.state.timerState == .completed {
            timeRemaining = 0
        } else {
            timeRemaining = max(0, Int(context.state.endTime.timeIntervalSince(Date())))
        }
        
        if context.state.timerState == .completed {
            return .green
        } else if timeRemaining <= 10 {
            return .red
        } else if timeRemaining <= 30 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Timer Progress Bar

struct TimerProgressBar: View {
    let context: ActivityViewContext<RestTimerAttributes>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress)
            }
        }
    }
    
    /// Calculate progress (0.0 to 1.0) based on elapsed time
    private var progress: CGFloat {
        let totalDuration = TimeInterval(context.state.totalDuration)
        guard totalDuration > 0 else { return 1.0 }
        
        let elapsed: TimeInterval
        
        switch context.state.timerState {
        case .paused:
            // When paused, calculate elapsed from remaining time
            if let pausedTime = context.state.pausedTimeRemaining {
                elapsed = totalDuration - TimeInterval(pausedTime)
            } else {
                elapsed = 0
            }
            
        case .completed:
            // Completed = 100% elapsed
            elapsed = totalDuration
            
        case .running:
            // Running - calculate actual elapsed time from original start
            elapsed = Date().timeIntervalSince(context.state.originalStartTime)
        }
        
        let calculatedProgress = elapsed / totalDuration
        return min(max(CGFloat(calculatedProgress), 0.0), 1.0)
    }
    
    /// Progress bar color based on completion
    private var progressColor: Color {
        if progress >= 1.0 || context.state.timerState == .completed {
            return .green
        } else if progress >= 0.85 {
            return .red
        } else if progress >= 0.75 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Previews

#Preview("Notification", as: .content, using: RestTimerAttributes(exerciseName: "Squat", setInfo: "Set 3 of 5")) {
    RestTimerWidgetLiveActivity()
} contentStates: {
    RestTimerAttributes.ContentState.initial(duration: 180)
}
