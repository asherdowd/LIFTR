import Foundation
import SwiftData

@Model
class PlateItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var weight: Double
    var quantity: Int
    
    init(id: UUID = UUID(), name: String = "", weight: Double, quantity: Int) {
        self.id = id
        self.name = name
        self.weight = weight
        self.quantity = quantity
    }
}

@Model
class BarItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var weight: Double
    var barType: String
    var quantity: Int
    
    init(id: UUID = UUID(), name: String = "", weight: Double, barType: String, quantity: Int) {
        self.id = id
        self.name = name
        self.weight = weight
        self.barType = barType
        self.quantity = quantity
    }
}

@Model
class CollarItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var weight: Double
    var quantity: Int
    
    init(id: UUID = UUID(), name: String = "", weight: Double, quantity: Int) {
        self.id = id
        self.name = name
        self.weight = weight
        self.quantity = quantity
    }
}
