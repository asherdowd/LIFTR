import SwiftUI
import SwiftData

// MARK: - Test Launcher View

struct WorkoutSessionTestLauncher: View {
    @State private var showTest1 = false
    @State private var showTest2 = false
    @State private var showTest3 = false
    @State private var showTest4 = false
    @State private var showTest5 = false
    @State private var showTest6 = false
    @State private var showTest7 = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Debug Tests for Overlay Issue")) {
                    Text("Start with Test 1 and work through sequentially. Note which test first shows the draggable overlay bug.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Basic Structure Tests")) {
                    Button("Test 1: Minimal View") {
                        showTest1 = true
                    }
                    
                    Button("Test 2: Alert with Single Button") {
                        showTest2 = true
                    }
                    
                    Button("Test 3: Alert with Multiple Buttons") {
                        showTest3 = true
                    }
                }
                
                Section(header: Text("Flow Tests")) {
                    Button("Test 4: Complete Workflow") {
                        showTest4 = true
                    }
                    
                    Button("Test 5: Sheets + Alert") {
                        showTest5 = true
                    }
                    
                    Button("Test 6: EXACT WorkoutSession Structure") {
                        showTest6 = true
                    }
                    
                    Button("Test 7: With @Bindable Context") {
                        showTest7 = true
                    }
                }
            }
            .navigationTitle("Overlay Bug Tests")
        }
        .sheet(isPresented: $showTest1) {
            Test1_MinimalView()
        }
        .sheet(isPresented: $showTest2) {
            Test2_AlertView()
        }
        .sheet(isPresented: $showTest3) {
            Test3_MultiButtonAlert()
        }
        .sheet(isPresented: $showTest4) {
            Test4_CompleteFlow()
        }
        .sheet(isPresented: $showTest5) {
            Test5_WithSheets()
        }
        .sheet(isPresented: $showTest6) {
            Test6_ExactStructure()
        }
        .sheet(isPresented: $showTest7) {
            Test7_WithBindableContext()
        }
    }
}

// MARK: - TEST 1: Minimal Structure

struct Test1_MinimalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 1: Minimal View")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This tests the basic structure")
                        .foregroundColor(.secondary)
                    
                    Text("✅ Expected: Dismiss cleanly without overlay")
                        .font(.caption)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 1")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - TEST 2: Alert with Single Button

struct Test2_AlertView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 2: Alert Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Tests if alert causes the overlay")
                        .foregroundColor(.secondary)
                    
                    Button("Trigger Alert") {
                        showAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("✅ Expected: Alert appears, tapping OK dismisses cleanly")
                        .font(.caption)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 2")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Test Alert", isPresented: $showAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("This is a test alert")
            }
        }
    }
}

// MARK: - TEST 3: Alert with Multiple Buttons

struct Test3_MultiButtonAlert: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 3: Multi-Button Alert")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Tests multiple alert buttons all calling dismiss()")
                        .foregroundColor(.secondary)
                    
                    Button("Trigger Alert") {
                        showAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("⭐ CRITICAL: All 3 buttons call dismiss()")
                        .font(.caption)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("❌ If this fails: Multiple dismiss() calls are the issue")
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 3")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Multiple Buttons", isPresented: $showAlert) {
                Button("Option 1") {
                    print("Option 1 selected")
                    dismiss()
                }
                Button("Option 2") {
                    print("Option 2 selected")
                    dismiss()
                }
                Button("Option 3") {
                    print("Option 3 selected")
                    dismiss()
                }
            } message: {
                Text("Choose an option - all call dismiss()")
            }
        }
    }
}

// MARK: - TEST 4: Complete Flow Simulation

struct Test4_CompleteFlow: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var recommendation: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 4: Complete Flow")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Replicates exact workout completion flow")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flow:")
                            .fontWeight(.semibold)
                        Text("1. Tap 'Complete Workout'")
                        Text("2. Sets state & shows alert")
                        Text("3. Tap any alert button")
                        Text("4. Calls dismiss()")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Complete Workout") {
                        completeWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("❌ If this fails: Alert flow with state is the issue")
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 4")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Workout Performance", isPresented: $showAlert) {
                if let rec = recommendation {
                    Button("Accept Recommendation") {
                        print("Accepted: \(rec)")
                        dismiss()
                    }
                    Button("Keep Original Plan") {
                        print("Keeping plan")
                        dismiss()
                    }
                    Button("Manual Adjustment") {
                        print("Manual adjustment")
                        dismiss()
                    }
                }
            } message: {
                if let rec = recommendation {
                    Text(rec)
                }
            }
        }
    }
    
    private func completeWorkout() {
        recommendation = "Great work! Continue with your planned progression."
        showAlert = true
    }
}

// MARK: - TEST 5: Sheets + Alert

struct Test5_WithSheets: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var showCalculator = false
    @State private var recommendation: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 5: Sheets + Alert")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Tests if sheets interfere with alert dismiss")
                        .foregroundColor(.secondary)
                    
                    Button("Show Calculator Sheet") {
                        showCalculator = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Complete Workout") {
                        completeWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test sequence:")
                            .fontWeight(.semibold)
                        Text("1. Open calculator sheet (dismiss it)")
                        Text("2. Then tap 'Complete Workout'")
                        Text("3. Dismiss alert")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Text("❌ If this fails: Sheet + alert combo is the issue")
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 5")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCalculator) {
                NavigationView {
                    VStack {
                        Text("Calculator Mock")
                            .font(.title)
                        Text("This simulates the calculator sheet")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Calculator")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showCalculator = false
                            }
                        }
                    }
                }
            }
            .alert("Workout Performance", isPresented: $showAlert) {
                Button("Accept") {
                    print("Accept tapped")
                    dismiss()
                }
                Button("Keep Plan") {
                    print("Keep plan tapped")
                    dismiss()
                }
                Button("Manual") {
                    print("Manual tapped")
                    dismiss()
                }
            } message: {
                Text(recommendation ?? "Test recommendation")
            }
        }
    }
    
    private func completeWorkout() {
        recommendation = "Performance analysis complete"
        showAlert = true
    }
}

// MARK: - TEST 6: Exact WorkoutSession Structure

struct Test6_ExactStructure: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var showSheet1 = false
    @State private var showSheet2 = false
    @State private var selectedItem: String?
    @State private var recommendation: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 6: Exact Structure")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This replicates the EXACT modifier stack from WorkoutSessionView")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Structure:")
                            .fontWeight(.semibold)
                        Text("• NavigationView (in sheet)")
                        Text("• .sheet(item:) - Sheet 1")
                        Text("• .sheet(isPresented:) - Sheet 2")
                        Text("• .alert() - Alert")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Show Sheet 1 (item binding)") {
                        selectedItem = "Test Item"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Show Sheet 2 (isPresented)") {
                        showSheet2 = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Complete & Show Alert") {
                        recommendation = "Test recommendation"
                        showAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("⭐ THIS SHOULD REPRODUCE THE BUG")
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 6")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: Binding(
                get: { selectedItem.map { TestItem(id: $0) } },
                set: { selectedItem = $0?.id }
            )) { item in
                NavigationView {
                    VStack {
                        Text("Sheet 1 (item binding)")
                            .font(.title)
                        Text("Item: \(item.id)")
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Sheet 1")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedItem = nil
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSheet2) {
                NavigationView {
                    VStack {
                        Text("Sheet 2 (isPresented)")
                            .font(.title)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Sheet 2")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSheet2 = false
                            }
                        }
                    }
                }
            }
            .alert("Test Alert", isPresented: $showAlert) {
                Button("Option 1") {
                    print("Option 1")
                    dismiss()
                }
                Button("Option 2") {
                    print("Option 2")
                    dismiss()
                }
                Button("Option 3") {
                    print("Option 3")
                    dismiss()
                }
            } message: {
                Text(recommendation ?? "")
            }
        }
    }
}

struct TestItem: Identifiable {
    let id: String
}

// MARK: - TEST 7: With @Bindable and Context Operations

struct Test7_WithBindableContext: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var globalSettings: [GlobalProgressionSettings]
    
    @State private var showAlert = false
    @State private var showSheet1 = false
    @State private var showSheet2 = false
    @State private var selectedItem: String?
    @State private var recommendation: String?
    
    var currentSettings: GlobalProgressionSettings {
        globalSettings.first ?? GlobalProgressionSettings()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test 7: With @Bindable Context")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Adds SwiftData @Query and context operations")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Added complexity:")
                            .fontWeight(.semibold)
                        Text("• @Environment(\\.modelContext)")
                        Text("• @Query for settings")
                        Text("• context.save() call")
                        Text("• Computed property access")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                    
                    Text("Settings loaded: \(globalSettings.isEmpty ? "❌ No" : "✅ Yes")")
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    
                    Button("Show Sheet 1") {
                        selectedItem = "Test Item"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Show Sheet 2") {
                        showSheet2 = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Complete & Show Alert") {
                        completeWithContext()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("⭐ Does THIS reproduce the bug?")
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Test 7")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: Binding(
                get: { selectedItem.map { TestItem(id: $0) } },
                set: { selectedItem = $0?.id }
            )) { item in
                NavigationView {
                    VStack {
                        Text("Sheet 1")
                            .font(.title)
                        Text("Item: \(item.id)")
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Sheet 1")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedItem = nil
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSheet2) {
                NavigationView {
                    VStack {
                        Text("Sheet 2")
                            .font(.title)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Sheet 2")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSheet2 = false
                            }
                        }
                    }
                }
            }
            .alert("Performance Alert", isPresented: $showAlert) {
                Button("Accept") {
                    applyChanges()
                }
                Button("Keep Plan") {
                    dismiss()
                }
                Button("Manual") {
                    dismiss()
                }
            } message: {
                Text(recommendation ?? "")
            }
        }
    }
    
    private func completeWithContext() {
        // Simulate what WorkoutSessionView does
        recommendation = "Test recommendation based on settings"
        showAlert = true
    }
    
    private func applyChanges() {
        // Simulate the applyAdjustment function
        try? context.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    WorkoutSessionTestLauncher()
}
