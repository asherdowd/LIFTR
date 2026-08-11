import SwiftUI

struct StartWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("What do you want to do?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                NavigationLink(destination: CreateSingleWorkoutView(onComplete: { dismiss() })) {
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

                NavigationLink(destination: Text("Program flow - coming in step 5")) {
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
    StartWorkoutView()
}
