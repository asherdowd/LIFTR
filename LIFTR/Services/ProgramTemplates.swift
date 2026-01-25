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
    static func createTexasMethod(
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
                templateType: .texasMethod,
                totalWeeks: totalWeeks
            )
            context.insert(program)
            
            // Create Volume Day (Monday): 5x5 at 90% of 5RM
            let volumeDay = TrainingDay(name: "Volume Day", dayNumber: 1)
            volumeDay.program = program
            context.insert(volumeDay)
            
            // Create Recovery Day (Wednesday): Light squats, alternating press
            let recoveryDay = TrainingDay(name: "Recovery Day", dayNumber: 2)
            recoveryDay.program = program
            context.insert(recoveryDay)
            
            // Create Intensity Day (Friday): 1x5 PR attempts
            let intensityDay = TrainingDay(name: "Intensity Day", dayNumber: 3)
            intensityDay.program = program
            context.insert(intensityDay)
            
            // VOLUME DAY EXERCISES
            let volumeSquat = ProgramExercise(
                exerciseName: "Squat",
                orderIndex: 0,
                startingWeight: squatWeight * 0.90,
                targetSets: 5,
                targetReps: 5,
                increment: 5.0,
                notes: "5x5 @ 90% of Friday's weight"
            )
            volumeSquat.trainingDay = volumeDay
            volumeDay.exercises.append(volumeSquat)
            context.insert(volumeSquat)
            
            let volumeBench = ProgramExercise(
                exerciseName: "Bench Press",
                orderIndex: 1,
                startingWeight: benchWeight * 0.90,
                targetSets: 5,
                targetReps: 5,
                increment: 2.5,
                notes: "5x5 @ 90% of 5RM"
            )
            volumeBench.trainingDay = volumeDay
            volumeDay.exercises.append(volumeBench)
            context.insert(volumeBench)
            
            let volumeDeadlift = ProgramExercise(
                exerciseName: "Deadlift",
                orderIndex: 2,
                startingWeight: deadliftWeight * 0.90,
                targetSets: 1,
                targetReps: 5,
                increment: 5.0,
                notes: "1x5 @ 90% of 5RM"
            )
            volumeDeadlift.trainingDay = volumeDay
            volumeDay.exercises.append(volumeDeadlift)
            context.insert(volumeDeadlift)
            
            // RECOVERY DAY EXERCISES
            let recoverySquat = ProgramExercise(
                exerciseName: "Squat",
                orderIndex: 0,
                startingWeight: squatWeight * 0.90 * 0.80,
                targetSets: 2,
                targetReps: 5,
                increment: 5.0,
                notes: "2x5 @ 80% of Monday's weight"
            )
            recoverySquat.trainingDay = recoveryDay
            recoveryDay.exercises.append(recoverySquat)
            context.insert(recoverySquat)
            
            let recoveryPress = ProgramExercise(
                exerciseName: "Overhead Press",
                orderIndex: 1,
                startingWeight: pressWeight * 0.90,
                targetSets: 3,
                targetReps: 5,
                increment: 2.5,
                notes: "3x5 @ 90% of 5RM"
            )
            recoveryPress.trainingDay = recoveryDay
            recoveryDay.exercises.append(recoveryPress)
            context.insert(recoveryPress)
            
            // INTENSITY DAY EXERCISES
            let intensitySquat = ProgramExercise(
                exerciseName: "Squat",
                orderIndex: 0,
                startingWeight: squatWeight,
                targetSets: 1,
                targetReps: 5,
                increment: 5.0,
                notes: "1x5 PR attempt"
            )
            intensitySquat.trainingDay = intensityDay
            intensityDay.exercises.append(intensitySquat)
            context.insert(intensitySquat)
            
            let intensityBench = ProgramExercise(
                exerciseName: "Bench Press",
                orderIndex: 1,
                startingWeight: benchWeight,
                targetSets: 1,
                targetReps: 5,
                increment: 2.5,
                notes: "1x5 PR attempt"
            )
            intensityBench.trainingDay = intensityDay
            intensityDay.exercises.append(intensityBench)
            context.insert(intensityBench)
            
            let intensityDeadlift = ProgramExercise(
                exerciseName: "Deadlift",
                orderIndex: 2,
                startingWeight: deadliftWeight,
                targetSets: 1,
                targetReps: 5,
                increment: 5.0,
                notes: "1x5 PR attempt"
            )
            intensityDeadlift.trainingDay = intensityDay
            intensityDay.exercises.append(intensityDeadlift)
            context.insert(intensityDeadlift)
            
            // Generate workout sessions for the entire program
            generateTexasMethodSessions(
                program: program,
                volumeDay: volumeDay,
                recoveryDay: recoveryDay,
                intensityDay: intensityDay,
                totalWeeks: totalWeeks,
                context: context
            )
            
            return program
        }
        
        /// Generates Texas Method sessions with Volume/Recovery/Intensity structure
        private static func generateTexasMethodSessions(
            program: Program,
            volumeDay: TrainingDay,
            recoveryDay: TrainingDay,
            intensityDay: TrainingDay,
            totalWeeks: Int,
            context: ModelContext
        ) {
            let calendar = Calendar.current
            let startDate = program.startDate
            
            // Texas Method: 3 sessions per week
            // Monday: Volume Day
            // Wednesday: Recovery Day
            // Friday: Intensity Day
            
            var sessionNumber = 0
            
            for week in 1...totalWeeks {
                // Monday - Volume Day (Session 1)
                sessionNumber += 1
                let mondayDate = calendar.date(byAdding: .day, value: (week - 1) * 7, to: startDate) ?? startDate
                createTexasMethodSessionsForDay(
                    trainingDay: volumeDay,
                    week: week,
                    sessionNumber: sessionNumber,
                    date: mondayDate,
                    context: context
                )
                
                // Wednesday - Recovery Day (Session 2)
                sessionNumber += 1
                let wednesdayDate = calendar.date(byAdding: .day, value: (week - 1) * 7 + 2, to: startDate) ?? startDate
                createTexasMethodSessionsForDay(
                    trainingDay: recoveryDay,
                    week: week,
                    sessionNumber: sessionNumber,
                    date: wednesdayDate,
                    context: context
                )
                
                // Friday - Intensity Day (Session 3)
                sessionNumber += 1
                let fridayDate = calendar.date(byAdding: .day, value: (week - 1) * 7 + 4, to: startDate) ?? startDate
                createTexasMethodSessionsForDay(
                    trainingDay: intensityDay,
                    week: week,
                    sessionNumber: sessionNumber,
                    date: fridayDate,
                    context: context
                )
            }
        }
        
        /// Creates exercise sessions for a specific Texas Method training day
        private static func createTexasMethodSessionsForDay(
            trainingDay: TrainingDay,
            week: Int,
            sessionNumber: Int,
            date: Date,
            context: ModelContext
        ) {
            for exercise in trainingDay.exercises {
                let exerciseSession = ExerciseSession(
                    date: date,
                    weekNumber: week,
                    sessionNumber: sessionNumber,
                    plannedWeight: calculateTexasMethodWeight(
                        exercise: exercise,
                        week: week,
                        dayName: trainingDay.name
                    ),
                    plannedSets: exercise.targetSets,
                    plannedReps: exercise.targetReps
                )
                
                exerciseSession.exercise = exercise
                exerciseSession.trainingDay = trainingDay
                trainingDay.sessions.append(exerciseSession)
                context.insert(exerciseSession)
                
                // Create sets for this exercise session
                for setNumber in 1...exercise.targetSets {
                    let workoutSet = WorkoutSet(
                        setNumber: setNumber,
                        targetReps: exercise.targetReps,
                        targetWeight: exerciseSession.plannedWeight
                    )
                    workoutSet.session = nil
                    exerciseSession.sets.append(workoutSet)
                    context.insert(workoutSet)
                }
            }
        }
        
        /// Calculates progressive weight for Texas Method exercises
        private static func calculateTexasMethodWeight(
            exercise: ProgramExercise,
            week: Int,
            dayName: String
        ) -> Double {
            // Texas Method progression:
            // - Intensity Day (Friday): Add 5 lbs lower body, 2.5 lbs upper body each week
            // - Volume Day (Monday): 90% of current Intensity Day weight
            // - Recovery Day (Wednesday): 80% of current Volume Day weight (squats only)
            
            let weeksProgressed = week - 1
            var weight = exercise.startingWeight
            
            switch dayName {
            case "Intensity Day":
                // Intensity day progresses weekly
                weight = exercise.startingWeight + (exercise.increment * Double(weeksProgressed))
                
            case "Volume Day":
                // Volume day is 90% of intensity day weight
                let intensityWeight = exercise.startingWeight + (exercise.increment * Double(weeksProgressed))
                weight = intensityWeight * 0.90
                
            case "Recovery Day":
                // Recovery day depends on exercise
                if exercise.exerciseName == "Squat" {
                    // Recovery squat is 80% of volume day weight
                    let intensityWeight = exercise.startingWeight / 0.90 // Back-calculate intensity weight
                    let progressedIntensity = intensityWeight + (exercise.increment * Double(weeksProgressed))
                    let volumeWeight = progressedIntensity * 0.90
                    weight = volumeWeight * 0.80
                } else {
                    // Press on recovery day progresses normally
                    weight = exercise.startingWeight + (exercise.increment * Double(weeksProgressed))
                }
                
            default:
                weight = exercise.startingWeight
            }
            
            return weight
        }
    static func createMadcow(
            name: String,
            squatWeight: Double,
            benchWeight: Double,
            rowWeight: Double,
            pressWeight: Double,
            deadliftWeight: Double,
            totalWeeks: Int = 12,
            context: ModelContext
        ) -> Program {
            
            let program = Program(
                name: name,
                templateType: .madcow,
                totalWeeks: totalWeeks
            )
            context.insert(program)
            
            // Create Volume Day (Monday): Ramping 5x5
            let volumeDay = TrainingDay(name: "Volume Day", dayNumber: 1)
            volumeDay.program = program
            context.insert(volumeDay)
            
            // Create Light Day (Wednesday): 4x5 light squats, ramping press/deadlift
            let lightDay = TrainingDay(name: "Light Day", dayNumber: 2)
            lightDay.program = program
            context.insert(lightDay)
            
            // Create Intensity Day (Friday): Ramping 4x5, 1x3, 1x8
            let intensityDay = TrainingDay(name: "Intensity Day", dayNumber: 3)
            intensityDay.program = program
            context.insert(intensityDay)
            
            // VOLUME DAY EXERCISES
            let volumeSquat = ProgramExercise(
                exerciseName: "Squat",
                orderIndex: 0,
                startingWeight: squatWeight,
                targetSets: 5,
                targetReps: 5,
                increment: 5.0,
                notes: "5x5 ramping to top set"
            )
            volumeSquat.trainingDay = volumeDay
            volumeDay.exercises.append(volumeSquat)
            context.insert(volumeSquat)
            
            let volumeBench = ProgramExercise(
                exerciseName: "Bench Press",
                orderIndex: 1,
                startingWeight: benchWeight,
                targetSets: 5,
                targetReps: 5,
                increment: 2.5,
                notes: "5x5 ramping to top set"
            )
            volumeBench.trainingDay = volumeDay
            volumeDay.exercises.append(volumeBench)
            context.insert(volumeBench)
            
            let volumeRow = ProgramExercise(
                exerciseName: "Barbell Row",
                orderIndex: 2,
                startingWeight: rowWeight,
                targetSets: 5,
                targetReps: 5,
                increment: 5.0,
                notes: "5x5 ramping to top set"
            )
            volumeRow.trainingDay = volumeDay
            volumeDay.exercises.append(volumeRow)
            context.insert(volumeRow)
            
            // LIGHT DAY EXERCISES
            let lightSquat = ProgramExercise(
                exerciseName: "Squat",
                orderIndex: 0,
                startingWeight: squatWeight * 0.75,
                targetSets: 4,
                targetReps: 5,
                increment: 5.0,
                notes: "4x5 @ 75% of Monday's top set"
            )
            lightSquat.trainingDay = lightDay
            lightDay.exercises.append(lightSquat)
            context.insert(lightSquat)
            
            let lightPress = ProgramExercise(
                exerciseName: "Overhead Press",
                orderIndex: 1,
                startingWeight: pressWeight,
                targetSets: 4,
                targetReps: 5,
                increment: 2.5,
                notes: "4x5 ramping to top set"
            )
            lightPress.trainingDay = lightDay
            lightDay.exercises.append(lightPress)
            context.insert(lightPress)
            
            let lightDeadlift = ProgramExercise(
                exerciseName: "Deadlift",
                orderIndex: 2,
                startingWeight: deadliftWeight,
                targetSets: 4,
                targetReps: 5,
                increment: 5.0,
                notes: "4x5 ramping to top set"
            )
            lightDeadlift.trainingDay = lightDay
            lightDay.exercises.append(lightDeadlift)
            context.insert(lightDeadlift)
            
            // INTENSITY DAY EXERCISES
            // Note: Intensity day exercises will have 6 total sets per exercise
            // 4x5 ramping + 1x3 @ 105% + 1x8 @ 80%
            
            let intensitySquat = ProgramExercise(
                exerciseName: "Squat",
                orderIndex: 0,
                startingWeight: squatWeight,
                targetSets: 6,  // 4 ramping + 1 triple + 1 backoff
                targetReps: 5,  // Primary reps (will vary by set)
                increment: 5.0,
                notes: "4x5 ramping, 1x3 @ 105%, 1x8 @ 80%"
            )
            intensitySquat.trainingDay = intensityDay
            intensityDay.exercises.append(intensitySquat)
            context.insert(intensitySquat)
            
            let intensityBench = ProgramExercise(
                exerciseName: "Bench Press",
                orderIndex: 1,
                startingWeight: benchWeight,
                targetSets: 6,
                targetReps: 5,
                increment: 2.5,
                notes: "4x5 ramping, 1x3 @ 105%, 1x8 @ 80%"
            )
            intensityBench.trainingDay = intensityDay
            intensityDay.exercises.append(intensityBench)
            context.insert(intensityBench)
            
            let intensityRow = ProgramExercise(
                exerciseName: "Barbell Row",
                orderIndex: 2,
                startingWeight: rowWeight,
                targetSets: 6,
                targetReps: 5,
                increment: 5.0,
                notes: "4x5 ramping, 1x3 @ 105%, 1x8 @ 80%"
            )
            intensityRow.trainingDay = intensityDay
            intensityDay.exercises.append(intensityRow)
            context.insert(intensityRow)
            
            // Generate workout sessions for the entire program
            generateMadcowSessions(
                program: program,
                volumeDay: volumeDay,
                lightDay: lightDay,
                intensityDay: intensityDay,
                totalWeeks: totalWeeks,
                context: context
            )
            
            return program
        }
        
        /// Generates Madcow sessions with Volume/Light/Intensity structure
        private static func generateMadcowSessions(
            program: Program,
            volumeDay: TrainingDay,
            lightDay: TrainingDay,
            intensityDay: TrainingDay,
            totalWeeks: Int,
            context: ModelContext
        ) {
            let calendar = Calendar.current
            let startDate = program.startDate
            
            // Madcow 5x5: 3 sessions per week
            // Monday: Volume Day
            // Wednesday: Light Day
            // Friday: Intensity Day
            
            var sessionNumber = 0
            
            for week in 1...totalWeeks {
                // Monday - Volume Day (Session 1)
                sessionNumber += 1
                let mondayDate = calendar.date(byAdding: .day, value: (week - 1) * 7, to: startDate) ?? startDate
                createMadcowSessionsForDay(
                    trainingDay: volumeDay,
                    week: week,
                    sessionNumber: sessionNumber,
                    date: mondayDate,
                    dayType: .volume,
                    context: context
                )
                
                // Wednesday - Light Day (Session 2)
                sessionNumber += 1
                let wednesdayDate = calendar.date(byAdding: .day, value: (week - 1) * 7 + 2, to: startDate) ?? startDate
                createMadcowSessionsForDay(
                    trainingDay: lightDay,
                    week: week,
                    sessionNumber: sessionNumber,
                    date: wednesdayDate,
                    dayType: .light,
                    context: context
                )
                
                // Friday - Intensity Day (Session 3)
                sessionNumber += 1
                let fridayDate = calendar.date(byAdding: .day, value: (week - 1) * 7 + 4, to: startDate) ?? startDate
                createMadcowSessionsForDay(
                    trainingDay: intensityDay,
                    week: week,
                    sessionNumber: sessionNumber,
                    date: fridayDate,
                    dayType: .intensity,
                    context: context
                )
            }
        }
        
        /// Day type for Madcow programming
        private enum MadcowDayType {
            case volume
            case light
            case intensity
        }
        
        /// Creates exercise sessions for a specific Madcow training day
        private static func createMadcowSessionsForDay(
            trainingDay: TrainingDay,
            week: Int,
            sessionNumber: Int,
            date: Date,
            dayType: MadcowDayType,
            context: ModelContext
        ) {
            for exercise in trainingDay.exercises {
                // Calculate top set weight for this week
                let topSetWeight = calculateMadcowWeight(
                    exercise: exercise,
                    week: week,
                    dayType: dayType
                )
                
                // Create ONE ExerciseSession per exercise
                let exerciseSession = ExerciseSession(
                    date: date,
                    weekNumber: week,
                    sessionNumber: sessionNumber,
                    plannedWeight: topSetWeight,  // Use top set weight as reference
                    plannedSets: exercise.targetSets,
                    plannedReps: exercise.targetReps
                )
                
                exerciseSession.exercise = exercise
                exerciseSession.trainingDay = trainingDay
                trainingDay.sessions.append(exerciseSession)
                context.insert(exerciseSession)
                
                // Create WorkoutSets based on day type
                if dayType == .intensity {
                    // Intensity day: 4 ramping sets + 1 triple + 1 backoff
                    createIntensityDaySets(
                        exerciseSession: exerciseSession,
                        topSetWeight: topSetWeight,
                        context: context
                    )
                } else if dayType == .light && exercise.exerciseName == "Squat" {
                    // Light squats are straight sets (all same weight)
                    createStraightSets(
                        exerciseSession: exerciseSession,
                        weight: topSetWeight,
                        sets: exercise.targetSets,
                        reps: exercise.targetReps,
                        context: context
                    )
                } else {
                    // Volume day and light day (non-squat) use ramping sets
                    createRampingSets(
                        exerciseSession: exerciseSession,
                        topSetWeight: topSetWeight,
                        sets: exercise.targetSets,
                        reps: exercise.targetReps,
                        context: context
                    )
                }
            }
        }
        
        /// Creates ramping workout sets for an exercise session
        private static func createRampingSets(
            exerciseSession: ExerciseSession,
            topSetWeight: Double,
            sets: Int,
            reps: Int,
            context: ModelContext
        ) {
            // Ramping percentages
            let rampingPercentages: [Double] = [0.60, 0.69, 0.82, 0.91, 1.00]
            let percentages = Array(rampingPercentages.suffix(sets))
            
            for (index, percentage) in percentages.enumerated() {
                let setWeight = topSetWeight * percentage
                
                let workoutSet = WorkoutSet(
                    setNumber: index + 1,
                    targetReps: reps,
                    targetWeight: setWeight
                )
                workoutSet.session = nil
                exerciseSession.sets.append(workoutSet)
                context.insert(workoutSet)
            }
        }
        
        /// Creates straight (same weight) workout sets for an exercise session
        private static func createStraightSets(
            exerciseSession: ExerciseSession,
            weight: Double,
            sets: Int,
            reps: Int,
            context: ModelContext
        ) {
            for setNumber in 1...sets {
                let workoutSet = WorkoutSet(
                    setNumber: setNumber,
                    targetReps: reps,
                    targetWeight: weight
                )
                workoutSet.session = nil
                exerciseSession.sets.append(workoutSet)
                context.insert(workoutSet)
            }
        }
        
        /// Creates intensity day workout sets (ramping + triple + backoff)
        private static func createIntensityDaySets(
            exerciseSession: ExerciseSession,
            topSetWeight: Double,
            context: ModelContext
        ) {
            // 4 ramping sets
            let rampingPercentages: [Double] = [0.69, 0.82, 0.91, 1.00]
            
            for (index, percentage) in rampingPercentages.enumerated() {
                let setWeight = topSetWeight * percentage
                
                let workoutSet = WorkoutSet(
                    setNumber: index + 1,
                    targetReps: 5,
                    targetWeight: setWeight
                )
                workoutSet.session = nil
                exerciseSession.sets.append(workoutSet)
                context.insert(workoutSet)
            }
            
            // Heavy triple (1x3 @ 105%)
            let tripleWeight = topSetWeight * 1.05
            let tripleSet = WorkoutSet(
                setNumber: 5,
                targetReps: 3,
                targetWeight: tripleWeight
            )
            tripleSet.session = nil
            exerciseSession.sets.append(tripleSet)
            context.insert(tripleSet)
            
            // Back-off set (1x8 @ 80%)
            let backoffWeight = topSetWeight * 0.80
            let backoffSet = WorkoutSet(
                setNumber: 6,
                targetReps: 8,
                targetWeight: backoffWeight
            )
            backoffSet.session = nil
            exerciseSession.sets.append(backoffSet)
            context.insert(backoffSet)
        }
        
        /// Calculates progressive weight for Madcow exercises
        private static func calculateMadcowWeight(
            exercise: ProgramExercise,
            week: Int,
            dayType: MadcowDayType
        ) -> Double {
            // Madcow progression:
            // - Increase all lifts weekly by increment
            // - Light day squats are 75% of volume day
            // - Intensity day exercises progress same as volume day
            
            let weeksProgressed = week - 1
            var weight = exercise.startingWeight
            
            switch dayType {
            case .volume, .intensity:
                // Both volume and intensity progress weekly
                weight = exercise.startingWeight + (exercise.increment * Double(weeksProgressed))
                
            case .light:
                if exercise.exerciseName == "Squat" {
                    // Light squats are 75% of volume day weight
                    let volumeWeight = exercise.startingWeight + (exercise.increment * Double(weeksProgressed))
                    weight = volumeWeight * 0.75
                } else {
                    // Other exercises on light day progress normally
                    weight = exercise.startingWeight + (exercise.increment * Double(weeksProgressed))
                }
            }
            
            return weight
        }
    
}
