import SwiftUI
import AVFoundation
import SwiftData

/// A countdown timer for rest periods between sets
struct RestTimerView: View {
    // Timer state
    @State private var timeRemaining: Int
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    
    // Configuration
    let duration: Int  // Total duration in seconds
    let onComplete: () -> Void
    let onDismiss: () -> Void
    
    // Timer publisher
    @State private var timer: Timer?
    
    // Audio player for notification sound
    @State private var audioPlayer: AVAudioPlayer?
    
    let enableSound: Bool
    let enableHaptic: Bool

    init(
        duration: Int,
        enableSound: Bool = true,
        enableHaptic: Bool = true,
        onComplete: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.duration = duration
        self.enableSound = enableSound
        self.enableHaptic = enableHaptic
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        _timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Rest Timer")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Timer Display
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // Time text
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(timerColor)
                    
                    if !isRunning && timeRemaining == duration {
                        Text("Ready")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if isPaused {
                        Text("Paused")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if timeRemaining == 0 {
                        Text("Complete!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            
            // Controls
            HStack(spacing: 20) {
                // Start/Pause Button
                Button(action: toggleTimer) {
                    HStack {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        Text(isRunning ? "Pause" : (timeRemaining == duration ? "Start" : "Resume"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.orange : Color.blue)
                    .cornerRadius(12)
                }
                
                // Reset Button
                Button(action: resetTimer) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            // Quick time adjustments
            HStack(spacing: 12) {
                Text("Quick adjust:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach([-30, -15, +15, +30], id: \.self) { adjustment in
                    Button(action: { adjustTime(by: adjustment) }) {
                        Text("\(adjustment > 0 ? "+" : "")\(adjustment)s")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .disabled(isRunning)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(timeRemaining) / Double(duration)
    }
    
    private var timeString: String {
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
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        isRunning = true
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Haptic feedback at 10, 5, 3, 2, 1 seconds
                if enableHaptic && timeRemaining <= 10 && timeRemaining > 0 {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            } else {
                // Timer complete
                stopTimer()
                playCompletionSound()
                onComplete()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
            isPaused = true
        } else {
            startTimer()
            isPaused = false
        }
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = duration
        isPaused = false
    }
    
    private func adjustTime(by seconds: Int) {
        let newTime = timeRemaining + seconds
        timeRemaining = max(0, min(newTime, duration + 60)) // Cap at duration + 1 minute
    }
    
    private func playCompletionSound() {
        if enableSound {
            // Play system sound
            AudioServicesPlaySystemSound(1304) // Anticipate sound
        }
        
        if enableHaptic {
            // Strong haptic feedback
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
}

// MARK: - Preview

#Preview {
    RestTimerView(
        duration: 90,
        onComplete: {
            print("Timer completed!")
        },
        onDismiss: {
            print("Timer dismissed")
        }
    )
}
