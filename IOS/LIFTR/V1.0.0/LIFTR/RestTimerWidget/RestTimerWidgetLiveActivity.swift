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
                        // The magic: timerInterval automatically counts down
                        Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(timerColor(for: context))
                        
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
                Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(timerColor(for: context))
                    .frame(width: 50)
                
            } minimal: {
                // Minimal (when multiple Live Activities are active)
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
            .keylineTint(.blue)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Determine timer color based on time remaining
    private func timerColor(for context: ActivityViewContext<RestTimerAttributes>) -> Color {
        let now = Date()
        let timeRemaining = context.state.endTime.timeIntervalSince(now)
        
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
                    // The magic countdown text
                    Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(timerColor)
                    
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
    
    /// Determine timer color based on time remaining
    private var timerColor: Color {
        let now = Date()
        let timeRemaining = context.state.endTime.timeIntervalSince(now)
        
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
    
    /// Calculate progress (0.0 to 1.0)
    private var progress: CGFloat {
        let now = Date()
        let totalDuration = context.state.endTime.timeIntervalSince(context.state.startTime)
        let elapsed = now.timeIntervalSince(context.state.startTime)
        
        // Clamp between 0 and 1
        return min(max(CGFloat(elapsed / totalDuration), 0.0), 1.0)
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
