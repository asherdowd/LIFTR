import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Session Live Activity (Lock Screen and Dynamic Island)
// One activity per live workout: "STRENGTH · Squat", the session clock, set progress, and the
// rest countdown on top while resting. All clocks are system-driven from dates in the content
// state (Text(timerInterval:)), so they keep running with no app updates.

struct RestTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            SessionLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.1))
                .activitySystemActionForegroundColor(Color.blue)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.workoutType.uppercased())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.attributes.exerciseName)
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SessionMainTime(state: context.state, size: 34)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SessionFooter(state: context.state)
                }
            } compactLeading: {
                Image(systemName: sessionIcon(context.attributes.workoutType))
                    .foregroundColor(.blue)
            } compactTrailing: {
                SessionCompactTime(state: context.state)
            } minimal: {
                Image(systemName: sessionIcon(context.attributes.workoutType))
                    .foregroundColor(.blue)
            }
            .keylineTint(.blue)
        }
    }
}

private func sessionIcon(_ workoutType: String) -> String {
    return workoutType == RestTimerAttributes.cardioType ? "figure.run" : "dumbbell.fill"
}

// MARK: - Lock Screen

struct SessionLockScreenView: View {
    let attributes: RestTimerAttributes
    let state: RestTimerAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: sessionIcon(attributes.workoutType))
                    .foregroundColor(.blue)
                Text("\(attributes.workoutType.uppercased()) · \(attributes.exerciseName)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                if !state.progressText.isEmpty {
                    Text(state.progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                SessionMainTime(state: state, size: 44)
                Spacer()
            }

            if state.isResting {
                ProgressView(timerInterval: state.restRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(.orange)
            }

            SessionFooter(state: state)
        }
        .padding()
    }
}

// MARK: - Shared pieces

/// The big time: "Rest over", the rest countdown, or the session clock.
struct SessionMainTime: View {
    let state: RestTimerAttributes.ContentState
    let size: CGFloat

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if state.restOver {
                Text("Rest over")
                    .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            } else if state.isResting {
                Text("REST")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text(timerInterval: state.restRange, countsDown: true)
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.orange)
            } else {
                Text(state.isPaused ? "PAUSED" : "ELAPSED")
                    .font(.caption2)
                    .foregroundColor(state.isPaused ? .orange : .secondary)
                Text(timerInterval: state.clockRange, pauseTime: state.pausedAt, countsDown: false, showsHours: true)
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
}

/// While resting, the session clock stays visible in small type.
struct SessionFooter: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        if state.isResting || state.restOver {
            HStack(spacing: 6) {
                Text(state.isPaused ? "Paused" : "Elapsed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(timerInterval: state.clockRange, pauseTime: state.pausedAt, countsDown: false, showsHours: true)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                Spacer()
            }
        } else if state.isPaused {
            Text("Clock paused")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
}

/// Dynamic Island compact trailing: rest countdown while resting, otherwise the session clock.
struct SessionCompactTime: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        if state.isResting {
            Text(timerInterval: state.restRange, countsDown: true, showsHours: false)
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(.orange)
                .frame(width: 50)
        } else {
            Text(timerInterval: state.clockRange, pauseTime: state.pausedAt, countsDown: false, showsHours: false)
                .font(.caption2)
                .monospacedDigit()
                .frame(width: 50)
        }
    }
}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: RestTimerAttributes(workoutType: "Strength", exerciseName: "Squat")) {
    RestTimerWidgetLiveActivity()
} contentStates: {
    RestTimerAttributes.ContentState(
        clockStart: Date().addingTimeInterval(-754),
        pausedAt: nil,
        progressText: "2 of 5 sets",
        restStart: nil,
        restEnd: nil,
        restOver: false
    )
    RestTimerAttributes.ContentState(
        clockStart: Date().addingTimeInterval(-754),
        pausedAt: nil,
        progressText: "2 of 5 sets",
        restStart: Date(),
        restEnd: Date().addingTimeInterval(90),
        restOver: false
    )
}
