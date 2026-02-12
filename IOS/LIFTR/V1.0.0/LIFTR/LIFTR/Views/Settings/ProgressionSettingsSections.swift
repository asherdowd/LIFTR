import SwiftUI
import SwiftData

// MARK: - Reusable Settings Sections

struct PresetSection: View {
    @Binding var showPresetSheet: Bool
    
    var body: some View {
        Section {
            Button(action: { showPresetSheet = true }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Load Preset Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AdjustmentBehaviorSection: View {
    @Binding var adjustmentMode: AdjustmentMode
    
    var body: some View {
        Section(header: Text("Auto-Adjustment Behavior")) {
            Picker("Adjustment Mode", selection: $adjustmentMode) {
                Text("Always prompt me").tag(AdjustmentMode.prompt)
                Text("Auto-adjust").tag(AdjustmentMode.autoAdjust)
                Text("Never adjust").tag(AdjustmentMode.never)
            }
            .pickerStyle(.menu)
        }
    }
}

struct PerformanceThresholdsSection: View {
    @Binding var excellentThreshold: Double
    @Binding var goodThreshold: Double
    @Binding var adjustmentThreshold: Double
    @Binding var reductionPercent: Double
    @Binding var deloadPercent: Double
    
    var body: some View {
        Section(header: Text("Performance Thresholds"),
                footer: Text("Percentage of target reps completed")) {
            
            HStack {
                Text("Excellent threshold")
                Spacer()
                TextField("", value: $excellentThreshold, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }
            
            HStack {
                Text("Good threshold")
                Spacer()
                TextField("", value: $goodThreshold, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }
            
            HStack {
                Text("Adjustment threshold")
                Spacer()
                TextField("", value: $adjustmentThreshold, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }
            
            HStack {
                Text("Reduction percent")
                Spacer()
                TextField("", value: $reductionPercent, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }
            
            HStack {
                Text("Deload percent")
                Spacer()
                TextField("", value: $deloadPercent, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("%")
            }
        }
    }
}

struct ProgressionIncrementsSection: View {
    @Binding var lowerBodyIncrement: Double
    @Binding var upperBodyIncrement: Double
    
    var body: some View {
        Section(header: Text("Progression Increments")) {
            HStack {
                Text("Lower body")
                Spacer()
                TextField("", value: $lowerBodyIncrement, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("lbs")
            }
            
            HStack {
                Text("Upper body")
                Spacer()
                TextField("", value: $upperBodyIncrement, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("lbs")
            }
        }
    }
}

struct AdvancedOptionsSection: View {
    @Binding var trackRPE: Bool
    @Binding var allowMidWorkoutAdjustments: Bool
    @Binding var autoDeloadEnabled: Bool
    @Binding var autoDeloadFrequency: Double
    
    var body: some View {
        Section(header: Text("Advanced Options")) {
            Toggle("Track RPE (Rate of Perceived Effort)", isOn: $trackRPE)
            Toggle("Allow mid-workout adjustments", isOn: $allowMidWorkoutAdjustments)
            Toggle("Auto-suggest deload", isOn: $autoDeloadEnabled)
            
            if autoDeloadEnabled {
                HStack {
                    Text("Every")
                    Spacer()
                    TextField("", value: $autoDeloadFrequency, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("weeks")
                }
            }
        }
    }
}

struct HomeScreenSection: View {
    @Binding var upcomingWorkoutsDays: Double
    
    var body: some View {
        Section(header: Text("Home Screen"),
                footer: Text("Number of days to show in the 'Upcoming Workouts' section")) {
            HStack {
                Text("Show workouts for next")
                Spacer()
                TextField("", value: $upcomingWorkoutsDays, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("days")
            }
        }
    }
}

struct RestTimerSection: View {
    @Binding var defaultRestTime: Double
    @Binding var autoStartRestTimer: Bool
    @Binding var restTimerSound: Bool
    @Binding var restTimerHaptic: Bool
    
    var body: some View {
        Section(header: Text("Rest Timer Settings")) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Default Rest Time: \(formatTime(Int(defaultRestTime)))")
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    TimeButton(seconds: 30, selected: Int(defaultRestTime) == 30) {
                        defaultRestTime = 30
                    }
                    TimeButton(seconds: 60, selected: Int(defaultRestTime) == 60) {
                        defaultRestTime = 60
                    }
                    TimeButton(seconds: 90, selected: Int(defaultRestTime) == 90) {
                        defaultRestTime = 90
                    }
                }
                
                HStack(spacing: 8) {
                    TimeButton(seconds: 120, selected: Int(defaultRestTime) == 120) {
                        defaultRestTime = 120
                    }
                    TimeButton(seconds: 180, selected: Int(defaultRestTime) == 180) {
                        defaultRestTime = 180
                    }
                    TimeButton(seconds: 300, selected: Int(defaultRestTime) == 300) {
                        defaultRestTime = 300
                    }
                }
            }
            
            Toggle("Auto-start timer after logging set", isOn: $autoStartRestTimer)
            Toggle("Play sound when timer completes", isOn: $restTimerSound)
            Toggle("Haptic feedback during countdown", isOn: $restTimerHaptic)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
}

struct TimeButton: View {
    let seconds: Int
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formatTimeShort(seconds))
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(selected ? Color.blue : Color(.systemGray5))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func formatTimeShort(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m"
        }
    }
}
