import SwiftUI

struct SingleWorkoutCategoryView: View {
    var onComplete: () -> Void = {}
    var body: some View {
        VStack(spacing: 24) {
            Text("What type of workout?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)

            NavigationLink(destination: LogSingleStrengthView(onComplete: onComplete)) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                    Text("Strength")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            NavigationLink(destination: LogSingleCardioView(onComplete: onComplete)) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title2)
                    Text("Cardio")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Single Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SingleWorkoutCategoryView()
    }
}
