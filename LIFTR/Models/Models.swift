import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var email: String
    
    init(id: UUID = UUID(), firstName: String, email: String) {
        self.id = id
        self.firstName = firstName
        self.email = email
    }
}

@Model
class PlateInventoryItem {
    @Attribute(.unique) var id: UUID
    var plateWeight: Double
    var quantity: Int
    var isCollar: Bool
    
    init(id: UUID = UUID(), plateWeight: Double, quantity: Int, isCollar: Bool = false) {
        self.id = id
        self.plateWeight = plateWeight
        self.quantity = quantity
        self.isCollar = isCollar
    }
}
