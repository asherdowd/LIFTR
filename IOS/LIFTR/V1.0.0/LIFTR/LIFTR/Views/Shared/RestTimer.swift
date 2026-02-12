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
    var onComplete: (() -> Void)?  // Called when user taps "Complete Rest"
    
    @State private var timeRemaining: Int
    @State private var isRunning: Bool = false
    @State private var isCompleted: Bool = false
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    
    // Live Activity tracking
    @State private var activity: Activity<RestTimerAttributes>?
    @State private var originalStartTime: Date?
    @State private var currentTotalDuration: Int
    
    init(defaultDuration: Int, exerciseName: String = "", setInfo: String = "", autoStart: Bool, playSound: Bool, enableHaptic: Bool, onComplete: (() -> Void)? = nil) {
        self.defaultDuration = defaultDuration
        self.exerciseName = exerciseName.isEmpty ? "Exercise" : exerciseName
        self.setInfo = setInfo.isEmpty ? "Rest" : setInfo
        self.autoStart = autoStart
        self.playSound = playSound
        self.enableHaptic = enableHaptic
        self.onComplete = onComplete
        
        _timeRemaining = State(initialValue: defaultDuration)
        _currentTotalDuration = State(initialValue: defaultDuration)
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
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(isCompleted ? .green : .secondary)
                        .fontWeight(isCompleted ? .semibold : .regular)
                }
            }
            
            if isCompleted {
                // MARK: - Completion State
                VStack(spacing: 16) {
                    // Complete Rest Button
                    Button(action: handleCompleteRest) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Rest")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                    
                    // Restart Timer Button (in case they need more rest)
                    Button(action: restartTimer) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart Timer")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                
            } else {
                // MARK: - Active Timer Controls
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
            }
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
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
        CGFloat(defaultDuration - timeRemaining) / CGFloat(currentTotalDuration)
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var statusText: String {
        if isCompleted {
            return "REST COMPLETE"
        } else if isRunning {
            return "RUNNING"
        } else if timeRemaining == defaultDuration {
            return "READY"
        } else {
            return "PAUSED"
        }
    }
    
    private var timerColor: Color {
        if isCompleted || timeRemaining == 0 {
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
        isCompleted = false
        
        startLiveActivity()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                if enableHaptic && (timeRemaining == 10 || timeRemaining == 5 || timeRemaining <= 3) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                
                if timeRemaining % 5 == 0 {
                    updateLiveActivity()
                }
            } else {
                completeTimer()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateLiveActivityPaused()
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        isCompleted = false
        timeRemaining = defaultDuration
        currentTotalDuration = defaultDuration
        originalStartTime = nil
        endLiveActivity()
    }
    
    private func restartTimer() {
        resetTimer()
        startTimer()
    }
    
    private func completeTimer() {
        stopTimer()
        isCompleted = true
        
        if playSound {
            playCompletionSound()
        }
        
        if enableHaptic {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        completeLiveActivity()
    }
    
    /// Called when user taps "Complete Rest" button
    private func handleCompleteRest() {
        endLiveActivity()
        onComplete?()  // Notify parent to dismiss LogSetView
        dismiss()      // Dismiss the timer sheet
    }
    
    // MARK: - Quick Adjust
    
    private func adjustButton(seconds: Int, label: String) -> some View {
        Button(action: { adjustTime(by: seconds) }) {
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
        currentTotalDuration = max(timeRemaining, currentTotalDuration + seconds)
        
        if isRunning {
            updateLiveActivity()
        } else {
            updateLiveActivityPaused()
        }
    }
    
    // MARK: - Sound
    
    private func playCompletionSound() {
        guard let soundURL = Bundle.main.url(forResource: "timer_complete", withExtension: "mp3") else {
            AudioServicesPlaySystemSound(1005)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    // MARK: - Live Activity Management
    
    private func startLiveActivity() {
        
        let authInfo = ActivityAuthorizationInfo()
        
        guard authInfo.areActivitiesEnabled else { return }
        
        guard #available(iOS 16.1, *) else { return }
        
        endLiveActivity()
        
        let attributes = RestTimerAttributes(
            exerciseName: exerciseName,
            setInfo: setInfo
        )
        
        let now = Date()
        originalStartTime = now
        
        let contentState = RestTimerAttributes.ContentState.initial(duration: TimeInterval(timeRemaining))
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activity failed to start - timer continues normally without it
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = activity,
              let originalStart = originalStartTime else { return }
        
        let contentState = RestTimerAttributes.ContentState.running(
            originalStart: originalStart,
            totalDuration: currentTotalDuration,
            timeRemaining: timeRemaining
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    private func updateLiveActivityPaused() {
        guard let activity = activity,
              let originalStart = originalStartTime else { return }
        
        let contentState = RestTimerAttributes.ContentState.paused(
            originalStart: originalStart,
            totalDuration: currentTotalDuration,
            timeRemaining: timeRemaining
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    private func completeLiveActivity() {
        guard let activity = activity,
              let originalStart = originalStartTime else { return }
        
        let contentState = RestTimerAttributes.ContentState.completed(
            originalStart: originalStart,
            totalDuration: currentTotalDuration
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await activity.end(
                .init(state: contentState, staleDate: nil),
                dismissalPolicy: .default
            )
            self.activity = nil
            self.originalStartTime = nil
        }
    }
    
    private func endLiveActivity() {
        guard let activity = activity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
            self.originalStartTime = nil
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
