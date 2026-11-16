import SwiftUI

// MARK: - Workout Complete
// One confirmation screen shown (as a sheet) after finishing a single strength workout or
// logging a cardio activity, so every way of finishing a workout ends the same way.

struct WorkoutCompleteView: View {
    let title: String
    let lines: [String]
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Workout Complete")
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.headline)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }
}

#Preview {
    WorkoutCompleteView(title: "Running", lines: ["3.1 mi · 30 min"], onDone: {})
}
