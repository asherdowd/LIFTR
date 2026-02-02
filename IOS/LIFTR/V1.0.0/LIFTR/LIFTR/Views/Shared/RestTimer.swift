import SwiftUI
import ActivityKit
import AVFoundation

struct RestTimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let defaultDuration: Int
    let exerciseName: String
    let setInfo: String
    let autoStart: Bool
    let playSound: Bool
    let enableHaptic: Bool
    
    @State private var timeRemaining: Int
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    
    // Live Activity
    @State private var activity: Activity<RestTimerAttributes>?
    
    init(defaultDuration: Int, exerciseName: String = "", setInfo: String = "", autoStart: Bool, playSound: Bool, enableHaptic: Bool) {
        self.defaultDuration = defaultDuration
        self.exerciseName = exerciseName.isEmpty ? "Exercise" : exerciseName
        self.setInfo = setInfo.isEmpty ? "Rest" : setInfo
        self.autoStart = autoStart
        self.playSound = playSound
        self.enableHaptic = enableHaptic
        
        _timeRemaining = State(initialValue: defaultDuration)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Exercise Info
            VStack(spacing: 8) {
                Text(exerciseName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(setInfo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(timerColor)
                    
                    Text(isRunning ? "RUNNING" : timeRemaining == 0 ? "COMPLETE" : "PAUSED")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Controls
            VStack(spacing: 16) {
                // Start/Pause/Resume Button
                Button(action: toggleTimer) {
                    HStack {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        Text(isRunning ? "Pause" : timeRemaining == defaultDuration ? "Start" : "Resume")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Reset Button
                Button(action: resetTimer) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                // Quick Adjust Buttons
                HStack(spacing: 12) {
                    adjustButton(seconds: -30, label: "-30s")
                    adjustButton(seconds: -15, label: "-15s")
                    adjustButton(seconds: 15, label: "+15s")
                    adjustButton(seconds: 30, label: "+30s")
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            if autoStart {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
            endLiveActivity()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: CGFloat {
        CGFloat(timeRemaining) / CGFloat(defaultDuration)
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var timerColor: Color {
        if timeRemaining == 0 {
            return .green
        } else if timeRemaining <= 10 {
            return .red
        } else if timeRemaining <= 30 {
            return .orange
        } else {
            return .blue
        }
    }
    
    // MARK: - Timer Controls
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        
        // Start Live Activity
        startLiveActivity()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Haptic feedback at specific intervals
                if enableHaptic && (timeRemaining == 10 || timeRemaining == 5 || timeRemaining <= 3) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                
                // Update Live Activity every 5 seconds
                if timeRemaining % 5 == 0 {
                    updateLiveActivity()
                }
            } else {
                // Timer completed
                completeTimer()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Update Live Activity to paused state
        updateLiveActivityPaused()
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = defaultDuration
        endLiveActivity()
    }
    
    private func completeTimer() {
        stopTimer()
        
        // Play sound
        if playSound {
            playCompletionSound()
        }
        
        // Final haptic
        if enableHaptic {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        // Mark Live Activity as completed
        completeLiveActivity()
    }
    
    // MARK: - Quick Adjust
    
    private func adjustButton(seconds: Int, label: String) -> some View {
        Button(action: {
            adjustTime(by: seconds)
        }) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
    
    private func adjustTime(by seconds: Int) {
        timeRemaining = max(0, timeRemaining + seconds)
        
        // Update Live Activity if running
        if isRunning {
            updateLiveActivity()
        }
    }
    
    // MARK: - Sound
    
    private func playCompletionSound() {
        guard let soundURL = Bundle.main.url(forResource: "timer_complete", withExtension: "mp3") else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1005)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    // MARK: - Live Activity Management
    
    private func startLiveActivity() {
        print("🔍 Checking Live Activity availability...")
        
        // Check if Live Activities are supported
        let authInfo = ActivityAuthorizationInfo()
        print("   areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        print("   frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities not enabled")
            return
        }
        
        // Check if ActivityKit is available
        if #available(iOS 16.1, *) {
            print("✅ iOS 16.1+ detected")
        } else {
            print("❌ iOS version too old")
            return
        }
        
        // End any existing activity first
        endLiveActivity()
        
        let attributes = RestTimerAttributes(
            exerciseName: exerciseName,
            setInfo: setInfo
        )
        
        let contentState = RestTimerAttributes.ContentState.initial(duration: TimeInterval(timeRemaining))
        
        print("🚀 Attempting to start Live Activity...")
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            print("✅ Live Activity started: \(activity?.id ?? "unknown")")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error details: \(error.localizedDescription)")
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = activity else { return }
        
        let contentState = RestTimerAttributes.ContentState(
            startTime: Date(),
            endTime: Date().addingTimeInterval(TimeInterval(timeRemaining)),
            timerState: .running
        )
        
        Task {
            await activity.update(
                .init(state: contentState, staleDate: nil)
            )
        }
    }
    
    private func updateLiveActivityPaused() {
        guard let activity = activity else { return }
        
        let contentState = RestTimerAttributes.ContentState(
            startTime: Date(),
            endTime: Date().addingTimeInterval(TimeInterval(timeRemaining)),
            timerState: .paused
        )
        
        Task {
            await activity.update(
                .init(state: contentState, staleDate: nil)
            )
        }
    }
    
    private func completeLiveActivity() {
        guard let activity = activity else { return }
        
        let contentState = RestTimerAttributes.ContentState(
            startTime: Date().addingTimeInterval(-TimeInterval(defaultDuration)),
            endTime: Date(),
            timerState: .completed
        )
        
        Task {
            await activity.update(
                .init(state: contentState, staleDate: nil)
            )
            
            // End activity after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await activity.end(
                .init(state: contentState, staleDate: nil),
                dismissalPolicy: .default
            )
            self.activity = nil
        }
    }
    
    private func endLiveActivity() {
        guard let activity = activity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}

// MARK: - Helper Function

func formatTimeShort(_ seconds: Int) -> String {
    let mins = seconds / 60
    let secs = seconds % 60
    return String(format: "%d:%02d", mins, secs)
}

#Preview {
    RestTimerView(
        defaultDuration: 180,
        exerciseName: "Squat",
        setInfo: "Set 3 of 5",
        autoStart: true,
        playSound: true,
        enableHaptic: true
    )
}
