import SwiftUI
import HealthKit

struct HealthKitSettingsView: View {
    @StateObject private var healthService = HealthKitService.shared
    @State private var showAuthorizationAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            // Status Section
            Section {
                HStack {
                    Image(systemName: healthService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(healthService.isAuthorized ? .green : .orange)
                    
                    Text("Status")
                    
                    Spacer()
                    
                    Text(statusText)
                        .foregroundColor(.secondary)
                }
                
                if let lastSync = healthService.lastSyncDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Apple Health")
            }
            
            // Authorization Section
            if !healthService.isAuthorized {
                Section {
                    Button(action: requestAuthorization) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .foregroundColor(.red)
                            Text("Connect to Apple Health")
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text("Grant LIFTR permission to write workouts to Apple Health. Your workout data will be saved to the Health app.")
                }
            }
            
            // Sync Settings Section
            if healthService.isAuthorized {
                Section {
                    Toggle(isOn: $healthService.syncEnabled) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text("Automatic Sync")
                        }
                    }
                    .onChange(of: healthService.syncEnabled) { _, newValue in
                        healthService.setSyncEnabled(newValue)
                    }
                } header: {
                    Text("Sync Settings")
                } footer: {
                    Text(healthService.syncEnabled
                         ? "Workouts will automatically sync to Apple Health when completed."
                         : "Automatic sync is disabled. Workouts will not be sent to Apple Health.")
                }
                
                // What Gets Synced Section
                Section {
                    InfoRow(icon: "figure.strengthtraining.traditional", 
                           iconColor: .purple,
                           title: "Strength Workouts",
                           detail: "Sets, reps, weight, duration")
                    
                    InfoRow(icon: "figure.run",
                           iconColor: .orange,
                           title: "Cardio Sessions",
                           detail: "Duration, distance, calories")
                    
                    InfoRow(icon: "flame.fill",
                           iconColor: .red,
                           title: "Calories Burned",
                           detail: "When available")
                    
                    InfoRow(icon: "heart.fill",
                           iconColor: .pink,
                           title: "Heart Rate Data",
                           detail: "Average and max BPM")
                } header: {
                    Text("What Gets Synced")
                } footer: {
                    Text("LIFTR syncs completed workouts to Apple Health as Strength Training or Cardio activities.")
                }
                
                // Disconnect Section
                Section {
                    Button(role: .destructive, action: { showAuthorizationAlert = true }) {
                        HStack {
                            Image(systemName: "link.badge.minus")
                            Text("Disconnect")
                        }
                    }
                } footer: {
                    Text("This will stop syncing workouts to Apple Health. Previously synced data will remain in the Health app.")
                }
            }
            
            // Device Compatibility
            if !healthService.isHealthKitAvailable {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("HealthKit not available on this device")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Apple Health")
        .alert("Disconnect Apple Health?", isPresented: $showAuthorizationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                disconnectHealthKit()
            }
        } message: {
            Text("LIFTR will no longer sync workouts to Apple Health. You can reconnect at any time.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if !healthService.isHealthKitAvailable {
            return "Not Available"
        }
        
        switch healthService.authorizationStatus {
        case .notDetermined:
            return "Not Connected"
        case .sharingDenied:
            return "Denied"
        case .sharingAuthorized:
            return "Connected"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Actions
    
    private func requestAuthorization() {
        Task {
            do {
                try await healthService.requestAuthorization()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func disconnectHealthKit() {
        healthService.setSyncEnabled(false)
        // Note: Cannot revoke HealthKit authorization programmatically
        // User must go to Settings > Privacy > Health > LIFTR to revoke
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthKitSettingsView()
    }
}
