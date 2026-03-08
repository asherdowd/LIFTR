import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    final class User {
        @Attribute(.unique) var id: UUID
        var firstName: String
        var email: String
        
        init(id: UUID = UUID(), firstName: String, email: String) {
            self.id = id
            self.firstName = firstName
            self.email = email
        }
    }
}
