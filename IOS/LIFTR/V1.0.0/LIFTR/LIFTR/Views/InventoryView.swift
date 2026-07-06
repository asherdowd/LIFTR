import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PlateItem.weight, order: .reverse) private var plates: [PlateItem]
    @Query(sort: \BarItem.weight, order: .reverse) private var bars: [BarItem]
    @Query(sort: \CollarItem.weight, order: .reverse) private var collars: [CollarItem]
    
    @State private var selectedTab: InventoryTab = .plates
    @State private var showingAddSheet = false
    
    enum InventoryTab: String, CaseIterable {
        case plates = "Plates"
        case bars = "Bars"
        case collars = "Collars"
        
        var icon: String {
            switch self {
            case .plates: return "circle.fill"
            case .bars: return "minus"
            case .collars: return "lock.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Category", selection: $selectedTab) {
                    ForEach(InventoryTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .plates:
                            PlatesSection(plates: plates, context: context)
                        case .bars:
                            BarsSection(bars: bars, context: context)
                        case .collars:
                            CollarsSection(collars: collars, context: context)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddInventorySheet(selectedTab: selectedTab)
            }
        }
    }
}

// MARK: - Plates Section

struct PlatesSection: View {
    let plates: [PlateItem]
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if plates.isEmpty {
                EmptyStateView(
                    icon: "circle.fill",
                    title: "No Plates",
                    message: "Add your plates to calculate loadings"
                )
            } else {
                ForEach(plates) { plate in
                    PlateRow(plate: plate) {
                        deletePlate(plate)
                    }
                }
            }
        }
    }
    
    private func deletePlate(_ plate: PlateItem) {
        context.delete(plate)
        try? context.save()
    }
}

// MARK: - Plate Row

struct PlateRow: View {
    let plate: PlateItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text("\(Int(plate.weight))")
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                if !plate.name.isEmpty {
                    Text(plate.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    Text("\(Int(plate.weight)) lbs Plate")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text("Quantity: \(plate.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Bars Section

struct BarsSection: View {
    let bars: [BarItem]
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if bars.isEmpty {
                EmptyStateView(
                    icon: "minus",
                    title: "No Bars",
                    message: "Add your barbells for accurate calculations"
                )
            } else {
                ForEach(bars) { bar in
                    BarRow(bar: bar) {
                        deleteBar(bar)
                    }
                }
            }
        }
    }
    
    private func deleteBar(_ bar: BarItem) {
        context.delete(bar)
        try? context.save()
    }
}

// MARK: - Bar Row

struct BarRow: View {
    let bar: BarItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "minus")
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bar.name.isEmpty ? bar.barType : bar.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text("\(Int(bar.weight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !bar.name.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(bar.barType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Qty: \(bar.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Collars Section

struct CollarsSection: View {
    let collars: [CollarItem]
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if collars.isEmpty {
                EmptyStateView(
                    icon: "lock.fill",
                    title: "No Collars",
                    message: "Add collars if you want to include their weight"
                )
            } else {
                ForEach(collars) { collar in
                    CollarRow(collar: collar) {
                        deleteCollar(collar)
                    }
                }
            }
        }
    }
    
    private func deleteCollar(_ collar: CollarItem) {
        context.delete(collar)
        try? context.save()
    }
}

// MARK: - Collar Row

struct CollarRow: View {
    let collar: CollarItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                if !collar.name.isEmpty {
                    Text(collar.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    Text("Collar")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", collar.weight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Qty: \(collar.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Add Inventory Sheet

struct AddInventorySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let selectedTab: InventoryView.InventoryTab
    
    @State private var name: String = ""
    @State private var weight: String = ""
    @State private var quantity: String = "2"
    @State private var barType: String = "Olympic Bar"
    
    private let barTypes = ["Olympic Bar", "Power Bar", "Deadlift Bar", "Squat Bar", "Curl Bar", "Women's Bar", "Training Bar"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (optional)", text: $name)
                    
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    if selectedTab == .bars {
                        Picker("Bar Type", selection: $barType) {
                            ForEach(barTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: Binding(
                        get: { Int(quantity) ?? 2 },
                        set: { quantity = String($0) }
                    ), in: 1...20)
                }
            }
            .navigationTitle("Add \(selectedTab.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        guard let weightValue = Double(weight),
              let quantityValue = Int(quantity) else { return }
        
        switch selectedTab {
        case .plates:
            let plate = PlateItem(
                name: name,
                weight: weightValue,
                quantity: quantityValue
            )
            context.insert(plate)
            
        case .bars:
            let bar = BarItem(
                name: name,
                weight: weightValue,
                barType: barType,
                quantity: quantityValue
            )
            context.insert(bar)
            
        case .collars:
            let collar = CollarItem(
                name: name,
                weight: weightValue,
                quantity: quantityValue
            )
            context.insert(collar)
        }
        
        try? context.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    InventoryView()
        .modelContainer(for: [PlateItem.self, BarItem.self, CollarItem.self])
}
