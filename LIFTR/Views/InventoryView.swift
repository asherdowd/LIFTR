import SwiftUI
import SwiftData

enum InventoryCategory: String, CaseIterable {
    case plates = "Plates"
    case bars = "Bars"
    case collars = "Collars"
    
    var weightHint: String {
        switch self {
        case .plates: return "Plate Weight"
        case .bars: return "Bar Weight"
        case .collars: return "Collar Weight"
        }
    }
    
    var addButtonTitle: String {
        switch self {
        case .plates: return "Add Plate"
        case .bars: return "Add Bar"
        case .collars: return "Add Collar"
        }
    }
}

struct InventoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\PlateItem.weight, order: .reverse)]) private var plates: [PlateItem]
    @Query(sort: [SortDescriptor(\BarItem.weight, order: .reverse)]) private var bars: [BarItem]
    @Query(sort: [SortDescriptor(\CollarItem.weight, order: .reverse)]) private var collars: [CollarItem]
    
    @State private var expandedCategory: InventoryCategory?
    @State private var selectedCategory: InventoryCategory = .plates
    @State private var newName: String = ""
    @State private var newWeight: String = ""
    @State private var newQuantity: String = ""
    @State private var selectedBarType: String = "Olympic"
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private let barTypes = ["Deadlift", "Squat", "Bench", "Olympic", "Curl"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category sections
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            CategorySection(
                                category: category,
                                isExpanded: expandedCategory == category,
                                onToggle: { toggleCategory(category) },
                                onSelect: { selectedCategory = category }
                            ) {
                                categoryContent(for: category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Add new item section
                VStack(spacing: 12) {
                    HStack {
                        Text("Add to: \(selectedCategory.rawValue)")
                            .font(.headline)
                        Spacer()
                    }
                    
                    TextField("Name (optional)", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text(selectedCategory.weightHint)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", text: $newWeight)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Quantity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", text: $newQuantity)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    if selectedCategory == .bars {
                        Picker("Bar Type", selection: $selectedBarType) {
                            ForEach(barTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(action: addNewItem) {
                        Text(selectedCategory.addButtonTitle)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isButtonEnabled ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!isButtonEnabled)
                    
                    // Debug info - remove this later
                    Text("Weight: '\(newWeight)' Qty: '\(newQuantity)'")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Enabled: \(isButtonEnabled ? "Yes" : "No")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Inventory")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isButtonEnabled: Bool {
        let hasWeight = !newWeight.isEmpty && Double(newWeight) != nil
        let hasQuantity = !newQuantity.isEmpty && Int(newQuantity) != nil
        return hasWeight && hasQuantity
    }
    
    @ViewBuilder
    private func categoryContent(for category: InventoryCategory) -> some View {
        switch category {
        case .plates:
            if plates.isEmpty {
                Text("No plates added yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(plates, id: \.id) { plate in
                    InventoryRow(
                        title: String(format: "%.1f lbs", plate.weight),
                        subtitle: plate.name.isEmpty ? nil : plate.name,
                        quantity: plate.quantity,
                        onDelete: { deletePlate(plate) }
                    )
                }
            }
            
        case .bars:
            if bars.isEmpty {
                Text("No bars added yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(bars, id: \.id) { bar in
                    InventoryRow(
                        title: String(format: "%.1f lbs", bar.weight),
                        subtitle: bar.name.isEmpty ? "\(bar.barType)" : "\(bar.name) - \(bar.barType)",
                        quantity: bar.quantity,
                        onDelete: { deleteBar(bar) }
                    )
                }
            }
            
        case .collars:
            if collars.isEmpty {
                Text("No collars added yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(collars, id: \.id) { collar in
                    InventoryRow(
                        title: String(format: "%.1f lbs", collar.weight),
                        subtitle: collar.name.isEmpty ? nil : collar.name,
                        quantity: collar.quantity,
                        onDelete: { deleteCollar(collar) }
                    )
                }
            }
        }
    }
    
    private func toggleCategory(_ category: InventoryCategory) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedCategory == category {
                expandedCategory = nil
            } else {
                expandedCategory = category
                selectedCategory = category
            }
        }
    }
    
    private func addNewItem() {
        guard let weight = Double(newWeight),
              let quantity = Int(newQuantity), quantity > 0 else {
            showErrorAlert(message: "Please enter valid weight and quantity")
            return
        }
        
        do {
            switch selectedCategory {
            case .plates:
                let plate = PlateItem(name: newName, weight: weight, quantity: quantity)
                context.insert(plate)
                
            case .bars:
                let bar = BarItem(name: newName, weight: weight, barType: selectedBarType, quantity: quantity)
                context.insert(bar)
                
            case .collars:
                let collar = CollarItem(name: newName, weight: weight, quantity: quantity)
                context.insert(collar)
            }
            
            try context.save()
            
            // Clear fields after successful save
            newName = ""
            newWeight = ""
            newQuantity = ""
            
            // Expand the category to show the new item
            expandedCategory = selectedCategory
            
        } catch {
            showErrorAlert(message: "Failed to add item: \(error.localizedDescription)")
        }
    }
    
    private func deletePlate(_ plate: PlateItem) {
        context.delete(plate)
        try? context.save()
    }
    
    private func deleteBar(_ bar: BarItem) {
        context.delete(bar)
        try? context.save()
    }
    
    private func deleteCollar(_ collar: CollarItem) {
        context.delete(collar)
        try? context.save()
    }
    
    private func showErrorAlert(message: String) {
        errorMessage = message
        showError = true
    }
}

struct CategorySection<Content: View>: View {
    let category: InventoryCategory
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                onToggle()
                onSelect()
            }) {
                HStack {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            if isExpanded {
                VStack(spacing: 4) {
                    content
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
}

struct InventoryRow: View {
    let title: String
    var subtitle: String?
    let quantity: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("x\(quantity)")
                .foregroundColor(.secondary)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(4)
    }
}
