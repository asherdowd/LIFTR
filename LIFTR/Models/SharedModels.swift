import Foundation
import SwiftData

// MARK: - Shared Enums (used by multiple systems)

enum ProgressionStatus: String, Codable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
}

// MARK: - Shared Models (used by multiple systems)

@Model
class WorkoutSet {
    var id: UUID
    var setNumber: Int
    
    var targetReps: Int
    var targetWeight: Double
    
    var actualReps: Int?
    var actualWeight: Double?
    var rpe: Int?
    var completed: Bool
    
    var session: WorkoutSession?  // Legacy - used by old Progression system
    
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
