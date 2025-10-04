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
        case .collars: return "Weight per Pair"
        }
    }
    
    var addButtonTitle: String {
        switch self {
        case .plates: return "Add Plate"
        case .bars: return "Add Bar"
        case .collars: return "Add Collar"
        }
    }
    
    var types: [String] {
        switch self {
        case .bars:
            return ["Bench Bar", "Deadlift Bar", "Squat Bar", "Power Lifting Bar", "Olympic Bar", "Curl Bar", "Womens Bar"]
        case .plates:
            return ["Bumpers", "Calibrated", "Iron", "Fractional"]
        case .collars:
            return ["Competition", "Plastic", "Spring", "Custom"]
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
    @State private var showAddSheet: Bool = false
    @State private var newName: String = ""
    @State private var newWeight: String = ""
    @State private var newQuantity: String = ""
    @State private var selectedType: String = "Bumpers"
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
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
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddInventorySheet(
                    selectedCategory: $selectedCategory,
                    newName: $newName,
                    newWeight: $newWeight,
                    newQuantity: $newQuantity,
                    selectedType: $selectedType,
                    onAdd: addNewItem,
                    onCancel: {
                        showAddSheet = false
                        clearFields()
                    },
                    onCategoryChange: { category in
                        selectedType = category.types.first ?? ""
                    }
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
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
        guard let weight = Double(newWeight) else {
            showErrorAlert(message: "Please enter valid weight")
            return
        }
        
        // Set quantity based on category
        let quantity: Int
        if selectedCategory == .bars {
            quantity = 1  // Bars always quantity 1
        } else if selectedCategory == .collars {
            quantity = 2  // Collars always come in pairs
        } else {
            // Plates require manual quantity entry
            guard let qty = Int(newQuantity), qty > 0 else {
                showErrorAlert(message: "Please enter valid quantity")
                return
            }
            quantity = qty
        }
        
        do {
            switch selectedCategory {
            case .plates:
                let plate = PlateItem(name: newName, weight: weight, quantity: quantity)
                context.insert(plate)
                
            case .bars:
                let bar = BarItem(name: newName, weight: weight, barType: selectedType, quantity: quantity)
                context.insert(bar)
                
            case .collars:
                let collar = CollarItem(name: newName, weight: weight, quantity: quantity)
                context.insert(collar)
            }
            
            try context.save()
            
            // Clear fields and close sheet
            clearFields()
            showAddSheet = false
            
            // Expand the category to show the new item
            expandedCategory = selectedCategory
            
        } catch {
            showErrorAlert(message: "Failed to add item: \(error.localizedDescription)")
        }
    }
    
    private func clearFields() {
        newName = ""
        newWeight = ""
        newQuantity = ""
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

// MARK: - Add Inventory Sheet

struct AddInventorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: InventoryCategory
    @Binding var newName: String
    @Binding var newWeight: String
    @Binding var newQuantity: String
    @Binding var selectedType: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    let onCategoryChange: (InventoryCategory) -> Void
    
    var isButtonEnabled: Bool {
        guard !newWeight.isEmpty else {
            return false
        }
        
        guard Double(newWeight) != nil else {
            return false
        }
        
        // Only plates require quantity input
        // Bars = always 1, Collars = always 2 (pair)
        if selectedCategory == .plates {
            guard !newQuantity.isEmpty else {
                return false
            }
            
            guard Int(newQuantity) != nil else {
                return false
            }
        }
        
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Add to", selection: $selectedCategory) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCategory) { oldValue, newValue in
                        onCategoryChange(newValue)
                    }
                } header: {
                    Text("Category")
                }
                
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(selectedCategory.types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextField("Name (optional)", text: $newName)
                    
                    HStack {
                        Text(selectedCategory.weightHint)
                        Spacer()
                        TextField("0", text: $newWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("lbs")
                    }
                    
                    if selectedCategory == .plates {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            TextField("0", text: $newQuantity)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                } header: {
                    Text("Item Details")
                } footer: {
                    if selectedCategory == .collars {
                        Text("Collars are automatically set to quantity of 2 (one pair)")
                    }
                }
                
                Section {
                    Button(action: {
                        onAdd()
                    }) {
                        HStack {
                            Spacer()
                            Text(selectedCategory.addButtonTitle)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isButtonEnabled)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Category Section

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
