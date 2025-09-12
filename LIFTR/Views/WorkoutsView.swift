import SwiftUI

struct WorkoutsView: View {
    @State private var exerciseName: String = ""
    @State private var currentMax: String = ""
    @State private var targetMax: String = ""
    @State private var weeks: String = ""
    @State private var plan: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                TextField("Exercise Name (e.g., Deadlift)", text: $exerciseName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Current Max", text: $currentMax)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Target Max", text: $targetMax)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Weeks to Target", text: $weeks)
                    .textFieldStyle(.roundedBorder)
                
                Button("Generate Plan") {
                    generatePlan()
                }
                .buttonStyle(.borderedProminent)
                
                if !plan.isEmpty {
                    List(plan, id: \.self) { entry in
                        Text(entry)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Workouts")
        }
    }
    
    private func generatePlan() {
        plan.removeAll()
        
        guard let current = Double(currentMax),
              let target = Double(targetMax),
              let numWeeks = Int(weeks),
              numWeeks > 0,
              !exerciseName.isEmpty else {
            plan.append("Please enter valid inputs")
            return
        }
        
        let increment = (target - current) / Double(numWeeks)
        
        for week in 1...numWeeks {
            let projected = current + increment * Double(week)
            let entry = String(format: "Week %d: %@ %.1f lbs", week, exerciseName, projected)
            plan.append(entry)
        }
    }
}
