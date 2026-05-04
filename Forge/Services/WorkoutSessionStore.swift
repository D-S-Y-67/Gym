import Foundation
import SwiftData
import Observation

/// Single source of truth for the in-progress workout.
///
/// `active` is the `Workout` row whose `endedAt == nil`. There is at most
/// one such row at a time. On launch we look it up so a force-quit during
/// a session resumes seamlessly. All mutations write through to SwiftData
/// immediately (no separate "save" step on the active screen).
@MainActor
@Observable
final class WorkoutSessionStore {

    private(set) var active: Workout?

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        loadActive()
    }

    // MARK: - Loading

    private func loadActive() {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        active = (try? context.fetch(descriptor))?.first
    }

    // MARK: - Lifecycle

    func startEmpty(name: String = "") {
        guard active == nil else { return }
        let workout = Workout(name: name, startedAt: .now)
        context.insert(workout)
        active = workout
        try? context.save()
    }

    func start(from routine: Routine) {
        guard active == nil else { return }
        let workout = Workout(name: routine.name, startedAt: .now)
        context.insert(workout)

        for (idx, template) in routine.orderedExercises.enumerated() {
            guard let exercise = template.exercise else { continue }
            let we = WorkoutExercise(
                exerciseIndex: idx,
                restSeconds: exercise.defaultRestSeconds,
                exercise: exercise
            )
            we.parentWorkout = workout
            context.insert(we)
            workout.exercises.append(we)

            for setIdx in 0..<max(1, template.targetSets) {
                let set = ExerciseSet(setIndex: setIdx, reps: template.targetReps ?? 0)
                set.parentExercise = we
                context.insert(set)
                we.sets.append(set)
            }
        }

        routine.lastUsedAt = .now
        active = workout
        try? context.save()
    }

    func finish() -> Workout? {
        guard let workout = active else { return nil }
        workout.endedAt = .now
        try? context.save()
        active = nil
        return workout
    }

    func discard() {
        guard let workout = active else { return }
        context.delete(workout)
        try? context.save()
        active = nil
    }

    // MARK: - Editing

    func addExercise(_ exercise: Exercise) {
        guard let workout = active else { return }
        let we = WorkoutExercise(
            exerciseIndex: workout.exercises.count,
            restSeconds: exercise.defaultRestSeconds,
            exercise: exercise
        )
        we.parentWorkout = workout
        context.insert(we)
        workout.exercises.append(we)
        addEmptySet(to: we)
    }

    func removeExercise(_ workoutExercise: WorkoutExercise) {
        guard let workout = active else { return }
        workout.exercises.removeAll { $0.id == workoutExercise.id }
        context.delete(workoutExercise)
        // Re-pack indices.
        for (idx, ex) in workout.orderedExercises.enumerated() {
            ex.exerciseIndex = idx
        }
        try? context.save()
    }

    @discardableResult
    func addEmptySet(to workoutExercise: WorkoutExercise) -> ExerciseSet {
        let last = workoutExercise.orderedSets.last
        let set = ExerciseSet(
            setIndex: workoutExercise.sets.count,
            weight: last?.weight ?? 0,
            reps: last?.reps ?? 0
        )
        set.parentExercise = workoutExercise
        context.insert(set)
        workoutExercise.sets.append(set)
        try? context.save()
        return set
    }

    func deleteSet(_ set: ExerciseSet, from workoutExercise: WorkoutExercise) {
        workoutExercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        for (idx, s) in workoutExercise.orderedSets.enumerated() {
            s.setIndex = idx
        }
        try? context.save()
    }

    func setCompleted(_ set: ExerciseSet, to completed: Bool) {
        set.isCompleted = completed
        set.completedAt = completed ? .now : nil
        try? context.save()
    }

    func updateRestSeconds(_ workoutExercise: WorkoutExercise, to seconds: Int) {
        workoutExercise.restSeconds = max(0, seconds)
        try? context.save()
    }

    /// Persist any pending pending change. View edits to weight/reps/RPE
    /// flow directly into the @Model objects via two-way bindings, which
    /// SwiftData tracks automatically — but on focus loss / app background
    /// we call this to flush.
    func flush() {
        try? context.save()
    }
}
