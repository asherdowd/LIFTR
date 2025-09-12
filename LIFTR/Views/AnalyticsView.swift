import SwiftUI

struct AnalyticsView: View {
    @State private var progress: [Double] = [225, 245, 265, 285, 305]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Analytics (Mocked)")
                    .font(.headline)
                
                List {
                    ForEach(progress.indices, id: \.self) { i in
                        Text(String(format: "Week %d: %.1f lbs", i+1, progress[i]))

                    }
                }
                
                NavigationLink("Run Tests", destination: TestView())
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .navigationTitle("Analytics")
        }
    }
}
