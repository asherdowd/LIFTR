import SwiftUI
import HealthKit

struct HealthKitSettingsView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var showingAuthorizationAlert = false
    @State private var authorizationError: Error?
    
    var body: some View {
        List {
            Section(header: Text("Authorization Status")) {
                HStack {
                    Text("Status")
                    Spacer()
                    if HKHealthStore.isHealthDataAvailable() {
                        if healthKitService.isAuthorizedStatus {
                            Label("Authorized", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Not Authorized", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("Not Available")
                            .foregroundColor(.secondary)
                    }
                }
                
                if !healthKitService.isAuthorizedStatus && HKHealthStore.isHealthDataAvailable() {
                    Button("Request Authorization") {
                        requestAuthorization()
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("About")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apple Health Integration")
                        .font(.headline)
                    
                    Text("LIFTR can sync your workout data to Apple Health, including:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Workout duration and type", systemImage: "clock")
                        Label("Calories burned", systemImage: "flame")
                        Label("Heart rate data", systemImage: "heart")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
            
            if healthKitService.isAuthorizedStatus {
                Section(header: Text("Sync Settings")) {
                    NavigationLink(destination: RecentWorkoutsView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Recent Workouts")
                        }
                    }
                }
            }
        }
        .navigationTitle("Apple Health")
        .alert("Authorization Error", isPresented: $showingAuthorizationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = authorizationError {
                Text(error.localizedDescription)
            } else {
                Text("Failed to authorize HealthKit")
            }
        }
        .onAppear {
            healthKitService.checkAuthorizationStatus()
        }
    }
    
    private func requestAuthorization() {
        healthKitService.requestAuthorization { success, error in
            if !success {
                authorizationError = error
                showingAuthorizationAlert = true
            }
        }
    }
}

// MARK: - Recent Workouts View

struct RecentWorkoutsView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var recentWorkouts: [HKWorkout] = []
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading workouts...")
            } else if recentWorkouts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No recent workouts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List(recentWorkouts, id: \.uuid) { workout in
                    WorkoutRowView(workout: workout)
                }
            }
        }
        .navigationTitle("Recent Workouts")
        .onAppear {
            loadRecentWorkouts()
        }
    }
    
    private func loadRecentWorkouts() {
        isLoading = true
        healthKitService.fetchRecentWorkouts(limit: 20) { workouts, error in
            DispatchQueue.main.async {
                isLoading = false
                if let workouts = workouts {
                    recentWorkouts = workouts
                }
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: HKWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForWorkoutType(workout.workoutActivityType))
                    .foregroundColor(.blue)
                Text(nameForWorkoutType(workout.workoutActivityType))
                    .font(.headline)
                Spacer()
                Text(workout.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                Label(workout.formattedDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let calories = workout.formattedCalories {
                    Label(calories, systemImage: "flame")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForWorkoutType(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining:
            return "dumbbell"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        default:
            return "figure.walk"
        }
    }
    
    private func nameForWorkoutType(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining:
            return "Strength Training"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .mixedCardio:
            return "Mixed Cardio"
        default:
            return "Workout"
        }
    }
}
