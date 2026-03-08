import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    final class WorkoutSet {
        var id: UUID
        var setNumber: Int
        
        var targetReps: Int
        var targetWeight: Double
        
        var actualReps: Int?
        var actualWeight: Double?
        var rpe: Int?
        var completed: Bool
        
        var session: WorkoutSession?
        
        var notes: String?
        
        init(
            id: UUID = UUID(),
            setNumber: Int,
            targetReps: Int,
            targetWeight: Double,
            actualReps: Int? = nil,
            actualWeight: Double? = nil,
            rpe: Int? = nil,
            completed: Bool = false,
            notes: String? = nil
        ) {
            self.id = id
            self.setNumber = setNumber
            self.targetReps = targetReps
            self.targetWeight = targetWeight
            self.actualReps = actualReps
            self.actualWeight = actualWeight
            self.rpe = rpe
            self.completed = completed
            self.notes = notes
        }
        
        var wasSuccessful: Bool {
            guard let actualReps = actualReps else { return false }
            return actualReps >= targetReps
        }
    }
}
