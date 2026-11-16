import SwiftUI

struct StartWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    /// The Workouts tab segment the sheet was opened from. Single Workout goes straight to
    /// the matching log screen, so the user is not asked Strength or Cardio a second time.
    let category: WorkoutsView.WorkoutCategory
    
    private var onComplete: () -> Void { { dismiss() } }
    
    @ViewBuilder
    private var singleWorkoutDestination: some View {
        switch category {
        case .strength:
            LogSingleStrengthView(onComplete: { dismiss() })
        case .cardio:
            LogSingleCardioView(onComplete: { dismiss() })
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("What do you want to do?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                NavigationLink(destination: singleWorkoutDestination) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                        Text("Single Workout")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                NavigationLink(destination: ProgramTemplatePickerView(onComplete: onComplete)) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                        Text("Program")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Start Workout")
        }
    }
}

#Preview {
    StartWorkoutView(category: .strength)
}
