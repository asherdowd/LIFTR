import Foundation
import SwiftData

class ProgramTemplates {
    
    /// Creates a Starting Strength program with A/B workout alternation
    /// - Parameters:
    ///   - name: Program name (e.g., "My Starting Strength")
    ///   - squatWeight: Starting weight for squats
    ///   - benchWeight: Starting weight for bench press
    ///   - pressWeight: Starting weight for overhead press
    ///   - deadliftWeight: Starting weight for deadlifts
    ///   - totalWeeks: Program duration in weeks (default: 12)
    ///   - context: ModelContext for inserting entities
    /// - Returns: Configured Program ready to use
    static func createStartingStrength(
        name: String,
        squatWeight: Double,
        benchWeight: Double,
        pressWeight: Double,
        deadliftWeight: Double,
        totalWeeks: Int = 12,
        context: ModelContext
    ) -> Program {
        
        let program = Program(
            name: name,
            templateType: .startingStrength,
            totalWeeks: totalWeeks
        )
        context.insert(program)
        
        // Create Workout A: Squat, Bench, Deadlift
        let workoutA = TrainingDay(name: "Workout A", dayNumber: 1)
        workoutA.program = program
        context.insert(workoutA)
        
        // Create Workout B: Squat, Press, Deadlift
        let workoutB = TrainingDay(name: "Workout B", dayNumber: 2)
        workoutB.program = program
        context.insert(workoutB)
        
        // Add exercises to Workout A
        let squatA = ProgramExercise(
            exerciseName: "Squat",
            orderIndex: 0,
            startingWeight: squatWeight,
            targetSets: 3,
            targetReps: 5,
            increment: 5.0
        )
        squatA.trainingDay = workoutA
        workoutA.exercises.append(squatA)
        context.insert(squatA)
        
        let bench = ProgramExercise(
            exerciseName: "Bench Press",
            orderIndex: 1,
            startingWeight: benchWeight,
            targetSets: 3,
            targetReps: 5,
            increment: 5.0
        )
        bench.trainingDay = workoutA
        workoutA.exercises.append(bench)
        context.insert(bench)
        
        let deadliftA = ProgramExercise(
            exerciseName: "Deadlift",
            orderIndex: 2,
            startingWeight: deadliftWeight,
            targetSets: 1,
            targetReps: 5,
            increment: 10.0
        )
        deadliftA.trainingDay = workoutA
        workoutA.exercises.append(deadliftA)
        context.insert(deadliftA)
        
        // Add exercises to Workout B
        let squatB = ProgramExercise(
            exerciseName: "Squat",
            orderIndex: 0,
            startingWeight: squatWeight,
            targetSets: 3,
            targetReps: 5,
            increment: 5.0
        )
        squatB.trainingDay = workoutB
        workoutB.exercises.append(squatB)
        context.insert(squatB)
        
        let press = ProgramExercise(
            exerciseName: "Overhead Press",
            orderIndex: 1,
            startingWeight: pressWeight,
            targetSets: 3,
            targetReps: 5,
            increment: 5.0
        )
        press.trainingDay = workoutB
        workoutB.exercises.append(press)
        context.insert(press)
        
        let deadliftB = ProgramExercise(
            exerciseName: "Deadlift",
            orderIndex: 2,
            startingWeight: deadliftWeight,
            targetSets: 1,
            targetReps: 5,
            increment: 10.0
        )
        deadliftB.trainingDay = workoutB
        workoutB.exercises.append(deadliftB)
        context.insert(deadliftB)
        
        // Generate workout sessions for the entire program
        generateStartingStrengthSessions(
            program: program,
            workoutA: workoutA,
            workoutB: workoutB,
            totalWeeks: totalWeeks,
            context: context
        )
        
        return program
    }
    
    /// Generates alternating A/B workout sessions with progressive weight increases
    private static func generateStartingStrengthSessions(
        program: Program,
        workoutA: TrainingDay,
        workoutB: TrainingDay,
        totalWeeks: Int,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let startDate = program.startDate
        
        // Starting Strength: 3 sessions per week, alternating A/B
        // Week 1: A, B, A
        // Week 2: B, A, B
        // Week 3: A, B, A (pattern repeats)
        
        var isWorkoutA = true // Start with Workout A
        var sessionNumber = 0
        
        for week in 1...totalWeeks {
            let sessionsThisWeek = 3
            
            for dayInWeek in 1...sessionsThisWeek {
                sessionNumber += 1
                
                // Calculate session date (Monday, Wednesday, Friday pattern)
                let daysFromStart = (week - 1) * 7 + (dayInWeek - 1) * 2
                let sessionDate = calendar.date(byAdding: .day, value: daysFromStart, to: startDate) ?? startDate
                
                // Alternate between Workout A and B
                let currentWorkout = isWorkoutA ? workoutA : workoutB
                
                // Create sessions for each exercise in this workout
                for exercise in currentWorkout.exercises {
                    let exerciseSession = ExerciseSession(
                        date: sessionDate,
                        weekNumber: week,
                        sessionNumber: sessionNumber,
                        plannedWeight: calculateWeight(
                            exercise: exercise,
                            sessionNumber: sessionNumber
                        ),
                        plannedSets: exercise.targetSets,
                        plannedReps: exercise.targetReps
                    )
                    
                    exerciseSession.exercise = exercise
                    exerciseSession.trainingDay = currentWorkout
                    currentWorkout.sessions.append(exerciseSession)
                    context.insert(exerciseSession)
                    
                    // Create sets for this exercise session
                    for setNumber in 1...exercise.targetSets {
                        let workoutSet = WorkoutSet(
                            setNumber: setNumber,
                            targetReps: exercise.targetReps,
                            targetWeight: exerciseSession.plannedWeight
                        )
                        workoutSet.session = nil // Not linked to old WorkoutSession
                        exerciseSession.sets.append(workoutSet)
                        context.insert(workoutSet)
                    }
                }
                
                // Alternate for next session
                isWorkoutA.toggle()
            }
        }
    }
    
    /// Calculates progressive weight for an exercise based on session number
    private static func calculateWeight(
        exercise: ProgramExercise,
        sessionNumber: Int
    ) -> Double {
        // Starting Strength progression:
        // - Squat increases every session
        // - Bench/Press increase every session they appear
        // - Deadlift increases every session
        
        let sessionsForThisExercise: Int
        
        switch exercise.exerciseName {
        case "Squat":
            // Squat is in every session (A and B)
            sessionsForThisExercise = sessionNumber
        case "Bench Press", "Overhead Press":
            // Bench and Press alternate, so they appear every other session
            sessionsForThisExercise = (sessionNumber + 1) / 2
        case "Deadlift":
            // Deadlift is in every session (A and B)
            sessionsForThisExercise = sessionNumber
        default:
            sessionsForThisExercise = sessionNumber
        }
        
        // Calculate weight: starting weight + (increment × sessions completed)
        // Subtract 1 because first session uses starting weight
        let weight = exercise.startingWeight + (exercise.increment * Double(sessionsForThisExercise - 1))
        
        return weight
    }
}
