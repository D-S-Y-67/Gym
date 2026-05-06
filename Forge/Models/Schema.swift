import Foundation
import SwiftData

// MARK: - SwiftData schema
//
// PR 2 expands PR 1's stubs into the full workout-logging schema.
// Pre-1.0 we don't ship a migration plan: any breaking change deletes
// the local store. Once we hit TestFlight a `SchemaMigrationPlan` lands
// alongside the first model change.

@Model
final class Workout {
    var id: UUID = UUID()
    var name: String = ""
    var startedAt: Date = Date.now
    var endedAt: Date?
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.parentWorkout)
    var exercises: [WorkoutExercise] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        startedAt: Date = .now,
        endedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
    }

    var isFinished: Bool { endedAt != nil }

    var orderedExercises: [WorkoutExercise] {
        exercises.sorted { $0.exerciseIndex < $1.exerciseIndex }
    }

    var totalCompletedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    var totalVolume: Double {
        exercises.reduce(0.0) { partial, ex in
            partial + ex.sets.filter { $0.isCompleted && !$0.isWarmup }
                .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    /// Live duration if not finished, otherwise final duration.
    func duration(asOf reference: Date = .now) -> TimeInterval {
        let end = endedAt ?? reference
        return max(0, end.timeIntervalSince(startedAt))
    }
}

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var bodyPart: String = ""
    var equipment: String = ""
    /// Movement pattern: "push" | "pull" | "squat" | "hinge" | "carry" | "core" | "isolation"
    var category: String = "isolation"
    var defaultRestSeconds: Int = 90
    var instructions: String?

    @Relationship(deleteRule: .nullify, inverse: \PersonalRecord.exercise)
    var personalRecords: [PersonalRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        bodyPart: String,
        equipment: String,
        category: String = "isolation",
        defaultRestSeconds: Int = 90,
        instructions: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.category = category
        self.defaultRestSeconds = defaultRestSeconds
        self.instructions = instructions
    }
}

@Model
final class WorkoutExercise {
    var id: UUID = UUID()
    var exerciseIndex: Int = 0
    var restSeconds: Int = 90
    var exercise: Exercise?
    var parentWorkout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.parentExercise)
    var sets: [ExerciseSet] = []

    init(
        id: UUID = UUID(),
        exerciseIndex: Int = 0,
        restSeconds: Int = 90,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.exerciseIndex = exerciseIndex
        self.restSeconds = restSeconds
        self.exercise = exercise
    }

    var orderedSets: [ExerciseSet] {
        sets.sorted { $0.setIndex < $1.setIndex }
    }
}

@Model
final class ExerciseSet {
    var id: UUID = UUID()
    var setIndex: Int = 0
    var weight: Double = 0
    var reps: Int = 0
    var rpe: Double?
    var isWarmup: Bool = false
    var isCompleted: Bool = false
    var completedAt: Date?
    var parentExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        setIndex: Int = 0,
        weight: Double = 0,
        reps: Int = 0,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.setIndex = setIndex
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    /// Epley estimated 1-rep max. Returns nil for invalid sets
    /// (warmups, zero weight/reps, or absurdly high reps).
    var estimated1RM: Double? {
        guard !isWarmup, weight > 0, reps >= 1, reps <= 30 else { return nil }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}

@Model
final class Routine {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var lastUsedAt: Date?

    /// Calendar weekday indices (1 = Sunday … 7 = Saturday) on which this
    /// routine is scheduled. Empty = unscheduled. PR 6 weekly view.
    var scheduledDays: [Int] = []

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.parentRoutine)
    var exercises: [RoutineExercise] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = .now,
        lastUsedAt: Date? = nil,
        scheduledDays: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.scheduledDays = scheduledDays
    }

    var orderedExercises: [RoutineExercise] {
        exercises.sorted { $0.exerciseIndex < $1.exerciseIndex }
    }

    func isScheduled(on weekday: Int) -> Bool {
        scheduledDays.contains(weekday)
    }

    var isScheduledToday: Bool {
        isScheduled(on: Calendar.current.component(.weekday, from: .now))
    }
}

@Model
final class RoutineExercise {
    var id: UUID = UUID()
    var exerciseIndex: Int = 0
    var targetSets: Int = 3
    var targetReps: Int?
    var exercise: Exercise?
    var parentRoutine: Routine?

    init(
        id: UUID = UUID(),
        exerciseIndex: Int = 0,
        targetSets: Int = 3,
        targetReps: Int? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.exerciseIndex = exerciseIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.exercise = exercise
    }
}

@Model
final class PersonalRecord {
    var id: UUID = UUID()
    /// PR 2 only emits "e1RM". Future: "maxWeight" | "maxReps" | "maxVolume".
    var prType: String = "e1RM"
    var value: Double = 0
    var achievedAt: Date = Date.now
    var sourceWorkoutId: UUID?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        prType: String = "e1RM",
        value: Double = 0,
        achievedAt: Date = .now,
        sourceWorkoutId: UUID? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.prType = prType
        self.value = value
        self.achievedAt = achievedAt
        self.sourceWorkoutId = sourceWorkoutId
        self.exercise = exercise
    }
}

// MARK: - Schema helpers

enum AppSchema {
    /// Every model registered with the SwiftData container.
    /// Update this list (and only this list) when adding new models.
    static let allModels: [any PersistentModel.Type] = [
        Workout.self,
        WorkoutExercise.self,
        ExerciseSet.self,
        Exercise.self,
        Routine.self,
        RoutineExercise.self,
        PersonalRecord.self
    ]
}
