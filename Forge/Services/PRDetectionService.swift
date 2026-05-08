import Foundation
import SwiftData

/// Detects new personal records on a finished workout.
///
/// PR 2 only tracks estimated 1-rep max (Epley). Each completed
/// non-warmup set is evaluated; if its e1RM beats the existing best
/// for that exercise by at least 0.5 lb, a new `PersonalRecord` row
/// is inserted and returned for the UI to surface.
@MainActor
struct PRDetectionService {

    /// Threshold to count as a new PR. Avoids float-precision drift
    /// from registering the same set twice.
    static let minimumImprovement: Double = 0.5

    @discardableResult
    static func detectPRs(for workout: Workout, in context: ModelContext) -> [PersonalRecord] {
        var newPRs: [PersonalRecord] = []

        // Best e1RM per exercise across this workout's completed sets.
        // Keyed by persistentModelID; stores the Exercise reference too
        // so we don't have to round-trip through `context.model(for:)`.
        var bestThisWorkout: [PersistentIdentifier: (value: Double, when: Date, exercise: Exercise)] = [:]

        for workoutExercise in workout.exercises {
            guard let exercise = workoutExercise.exercise else { continue }
            for set in workoutExercise.sets where set.isCompleted {
                guard let e1RM = set.estimated1RM else { continue }
                let when = set.completedAt ?? .now
                let id = exercise.persistentModelID
                let current = bestThisWorkout[id]?.value ?? 0
                if e1RM > current {
                    bestThisWorkout[id] = (e1RM, when, exercise)
                }
            }
        }

        for (_, candidate) in bestThisWorkout {
            let priorBest = bestPrior(
                e1RMFor: candidate.exercise,
                excluding: workout.id,
                in: context
            )
            if candidate.value >= priorBest + Self.minimumImprovement {
                let pr = PersonalRecord(
                    prType: "e1RM",
                    value: candidate.value,
                    achievedAt: candidate.when,
                    sourceWorkoutId: workout.id,
                    exercise: candidate.exercise
                )
                context.insert(pr)
                newPRs.append(pr)
            }
        }

        if !newPRs.isEmpty {
            try? context.save()
        }

        return newPRs
    }

    /// Highest e1RM previously recorded for the given exercise,
    /// excluding any record sourced from `workoutID` so re-running
    /// detection on the same workout doesn't compare against itself.
    private static func bestPrior(
        e1RMFor exercise: Exercise,
        excluding workoutID: UUID,
        in context: ModelContext
    ) -> Double {
        let exerciseID = exercise.persistentModelID
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { record in
                record.prType == "e1RM"
                && record.sourceWorkoutId != workoutID
            }
        )
        let allPRs = (try? context.fetch(descriptor)) ?? []
        return allPRs
            .filter { $0.exercise?.persistentModelID == exerciseID }
            .map(\.value)
            .max() ?? 0
    }
}
