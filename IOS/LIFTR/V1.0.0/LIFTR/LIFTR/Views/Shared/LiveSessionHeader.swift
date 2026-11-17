import SwiftUI
import SwiftData

// MARK: - Live session UI
// Shared by every live logging screen: a Start bar before the session starts, a pinned header
// with the clock and a single Pause / Resume once it runs, and the "Still working out?" prompt.

/// Pinned at the top while a session is running. The only Pause on the screen: it pauses the clock.
/// While a rest is running a second row shows the rest countdown with +15s and Skip.
struct LiveSessionHeader: View {
    @Environment(\.modelContext) private var context
    let session: ExerciseSession
    @ObservedObject var rest: RestTimerController

    private var isPaused: Bool { LiveSessionClock.isPaused(session) }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        Text(LiveSessionClock.format(LiveSessionClock.elapsed(session, now: timeline.date)))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    Text(isPaused ? "Paused" : "Elapsed")
                        .font(.caption)
                        .foregroundColor(isPaused ? .orange : .secondary)
                }

                Spacer()

                Button(action: togglePause) {
                    Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(isPaused ? .green : .orange)
            }

            if let clock = rest.clock {
                restRow(clock: clock)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder
    private func restRow(clock: RestClock) -> some View {
        if rest.phase == .finished {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Rest over")
                    .fontWeight(.semibold)
                Spacer()
            }
        } else {
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                HStack(spacing: 12) {
                    Text("Rest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(RestClock.format(clock.remaining(at: timeline.date)))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    ProgressView(value: clock.progress(at: timeline.date))
                    Button("+15s") { rest.addTime() }
                        .buttonStyle(.bordered)
                    Button("Skip") { rest.skip() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private func togglePause() {
        if isPaused {
            LiveSessionClock.resume(session)
        } else {
            LiveSessionClock.pause(session)
        }
        try? context.save()
    }
}

/// Bottom bar shown before the session starts.
struct LiveSessionStartBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .background(.bar)
    }
}

/// "Still working out?" for a session that has been running a long time. Finish asks how long
/// the workout really was, then hands the seconds to the screen, which runs its normal Complete flow.
private struct StaleSessionPrompt: ViewModifier {
    let session: ExerciseSession
    let onFinish: (TimeInterval) -> Void

    @State private var showAsk = false
    @State private var showDuration = false
    @State private var minutesText = ""

    func body(content: Content) -> some View {
        content
            .onAppear {
                if LiveSessionClock.isStale(session) { showAsk = true }
            }
            .alert("Still working out?", isPresented: $showAsk) {
                Button("Resume", role: .cancel) {}
                Button("Finish") {
                    let minutes: Int = Int((LiveSessionClock.elapsed(session) / 60).rounded())
                    minutesText = String(minutes)
                    showDuration = true
                }
            } message: {
                Text("This workout has been running for \(LiveSessionClock.format(LiveSessionClock.elapsed(session))).")
            }
            .alert("How long was your workout?", isPresented: $showDuration) {
                TextField("Minutes", text: $minutesText)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {}
                Button("Finish") {
                    if let minutes = Double(minutesText), minutes > 0 {
                        onFinish(minutes * 60)
                    }
                }
            }
    }
}

extension View {
    func stalePrompt(for session: ExerciseSession, onFinish: @escaping (TimeInterval) -> Void) -> some View {
        modifier(StaleSessionPrompt(session: session, onFinish: onFinish))
    }
}
