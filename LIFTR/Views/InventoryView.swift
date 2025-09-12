import SwiftUI
import SwiftData

// New separate models for better type safety
@Model
class PlateItem {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var quantity: Int
    var order: Int
    
    init(id: UUID = UUID(), weight: Double, quantity: Int, order: Int = 0) {
        self.id = id
        self.weight = weight
        self.quantity = quantity
        self.order = order
    }
}

@Model
class BarItem {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var barType: String
    var quantity: Int
    var order: Int
    
    init(id: UUID = UUID(), weight: Double, barType: String, quantity: Int, order: Int = 0) {
        self.id = id
        self.weight = weight
        self.barType = barType
        self.quantity = quantity
        self.order = order
    }
}

@Model
class CollarItem {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var quantity: Int
    var order: Int
    
    init(id: UUID = UUID(), weight: Double, quantity: Int, order: Int = 0) {
        self.id = id
        self.weight = weight
        self.quantity = quantity
        self.order = order
    }
}

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
    @Query(sort: \PlateItem.order) private var plates: [PlateItem]
    @Query(sort: \BarItem.order) private var bars: [BarItem]
    @Query(sort: \CollarItem.order) private var collars: [CollarItem]
    
    @State private var expandedCategory: InventoryCategory?
    @State private var selectedCategory: InventoryCategory = .plates
    @State private var newWeight: String = ""
    @State private var newQuantity: String = ""
    @State private var selectedBarType: String = "Olympic"
    
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
                    
                    HStack(spacing: 12) {
                        TextField(selectedCategory.weightHint, text: $newWeight)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Quantity", text: $newQuantity)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if selectedCategory == .bars {
                        Picker("Bar Type", selection: $selectedBarType) {
                            ForEach(barTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(selectedCategory.addButtonTitle) {
                        addNewItem()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newWeight.isEmpty || newQuantity.isEmpty)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Inventory")
        }
    }
    
    @ViewBuilder
    private func categoryContent(for category: InventoryCategory) -> some View {
        switch category {
        case .plates:
            ForEach(plates, id: \.id) { plate in
                InventoryRow(
                    title: String(format: "%.1f lbs", plate.weight),
                    quantity: plate.quantity,
                    onDelete: { deletePlate(plate) }
                )
            }
            .onMove(perform: movePlates)
            
        case .bars:
            ForEach(bars, id: \.id) { bar in
                InventoryRow(
                    title: String(format: "%.1f lbs", bar.weight),
                    subtitle: bar.barType,
                    quantity: bar.quantity,
                    onDelete: { deleteBar(bar) }
                )
            }
            .onMove(perform: moveBars)
            
        case .collars:
            ForEach(collars, id: \.id) { collar in
                InventoryRow(
                    title: String(format: "%.1f lbs", collar.weight),
                    quantity: collar.quantity,
                    onDelete: { deleteCollar(collar) }
                )
            }
            .onMove(perform: moveCollars)
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
              let quantity = Int(newQuantity), quantity > 0 else { return }
        
        let nextOrder = getNextOrder(for: selectedCategory)
        
        switch selectedCategory {
        case .plates:
            let plate = PlateItem(weight: weight, quantity: quantity, order: nextOrder)
            context.insert(plate)
            
        case .bars:
            let bar = BarItem(weight: weight, barType: selectedBarType, quantity: quantity, order: nextOrder)
            context.insert(bar)
            
        case .collars:
            let collar = CollarItem(weight: weight, quantity: quantity, order: nextOrder)
            context.insert(collar)
        }
        
        try? context.save()
        newWeight = ""
        newQuantity = ""
    }
    
    private func getNextOrder(for category: InventoryCategory) -> Int {
        switch category {
        case .plates: return (plates.map(\.order).max() ?? 0) + 1
        case .bars: return (bars.map(\.order).max() ?? 0) + 1
        case .collars: return (collars.map(\.order).max() ?? 0) + 1
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
    
    private func movePlates(from source: IndexSet, to destination: Int) {
        var reorderedPlates = plates
        reorderedPlates.move(fromOffsets: source, toOffset: destination)
        updateOrder(items: reorderedPlates)
    }
    
    private func moveBars(from source: IndexSet, to destination: Int) {
        var reorderedBars = bars
        reorderedBars.move(fromOffsets: source, toOffset: destination)
        updateOrder(items: reorderedBars)
    }
    
    private func moveCollars(from source: IndexSet, to destination: Int) {
        var reorderedCollars = collars
        reorderedCollars.move(fromOffsets: source, toOffset: destination)
        updateOrder(items: reorderedCollars)
    }
    
    private func updateOrder<T: AnyObject>(items: [T]) {
        for (index, item) in items.enumerated() {
            if let plate = item as? PlateItem { plate.order = index }
            else if let bar = item as? BarItem { bar.order = index }
            else if let collar = item as? CollarItem { collar.order = index }
        }
        try? context.save()
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
