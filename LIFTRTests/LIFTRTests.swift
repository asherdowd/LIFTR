import XCTest
import SwiftData
@testable import LIFTR

final class LiftrTests: XCTestCase {
    var container: ModelContainer!
    
    override func setUpWithError() throws {
        container = try ModelContainer(for: PlateInventoryItem.self, configurations: .init(isStoredInMemoryOnly: true))
    }

    override func tearDownWithError() throws {
        container = nil
    }

    @MainActor func testAddPlateInventoryItem() throws {
        let context = container.mainContext
        let plate = PlateInventoryItem(plateWeight: 45, quantity: 2)
        context.insert(plate)
        try context.save()
        
        let request = FetchDescriptor<PlateInventoryItem>()
        let items = try context.fetch(request)
        
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.plateWeight, 45)
        XCTAssertEqual(items.first?.quantity, 2)
    }
    
    @MainActor func testDeletePlateInventoryItem() throws {
        let context = container.mainContext
        let plate = PlateInventoryItem(plateWeight: 25, quantity: 4)
        context.insert(plate)
        try context.save()
        
        context.delete(plate)
        try context.save()
        
        let request = FetchDescriptor<PlateInventoryItem>()
        let items = try context.fetch(request)
        
        XCTAssertTrue(items.isEmpty)
    }
}
