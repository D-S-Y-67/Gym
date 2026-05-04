import Foundation
import SwiftData

/// Seeds the exercise table on first launch with a small starter set
/// (~20 common compounds + accessories). PR 3 expands this to the
/// full library; until then this is what the picker draws from.
///
/// `seedIfNeeded` is idempotent: it only inserts if the table is empty.
@MainActor
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        for spec in starterSet {
            context.insert(
                Exercise(
                    name: spec.name,
                    bodyPart: spec.bodyPart,
                    equipment: spec.equipment,
                    category: spec.category,
                    defaultRestSeconds: spec.defaultRestSeconds
                )
            )
        }
        try? context.save()
    }

    private struct Spec {
        let name: String
        let bodyPart: String
        let equipment: String
        let category: String
        let defaultRestSeconds: Int
    }

    private static let starterSet: [Spec] = [
        // Chest
        .init(name: "Bench Press",            bodyPart: "Chest",     equipment: "Barbell",  category: "push",      defaultRestSeconds: 150),
        .init(name: "Incline Dumbbell Press", bodyPart: "Chest",     equipment: "Dumbbell", category: "push",      defaultRestSeconds: 120),
        .init(name: "Push-Up",                bodyPart: "Chest",     equipment: "Bodyweight", category: "push",    defaultRestSeconds: 60),
        // Back
        .init(name: "Pull-Up",                bodyPart: "Back",      equipment: "Bodyweight", category: "pull",    defaultRestSeconds: 120),
        .init(name: "Chin-Up",                bodyPart: "Back",      equipment: "Bodyweight", category: "pull",    defaultRestSeconds: 120),
        .init(name: "Barbell Row",            bodyPart: "Back",      equipment: "Barbell",  category: "pull",      defaultRestSeconds: 120),
        .init(name: "Seated Cable Row",       bodyPart: "Back",      equipment: "Cable",    category: "pull",      defaultRestSeconds: 90),
        .init(name: "Lat Pulldown",           bodyPart: "Back",      equipment: "Cable",    category: "pull",      defaultRestSeconds: 90),
        // Shoulders
        .init(name: "Overhead Press",         bodyPart: "Shoulders", equipment: "Barbell",  category: "push",      defaultRestSeconds: 120),
        .init(name: "Lateral Raise",          bodyPart: "Shoulders", equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60),
        // Legs
        .init(name: "Back Squat",             bodyPart: "Legs",      equipment: "Barbell",  category: "squat",     defaultRestSeconds: 180),
        .init(name: "Front Squat",            bodyPart: "Legs",      equipment: "Barbell",  category: "squat",     defaultRestSeconds: 150),
        .init(name: "Romanian Deadlift",      bodyPart: "Legs",      equipment: "Barbell",  category: "hinge",     defaultRestSeconds: 150),
        .init(name: "Conventional Deadlift",  bodyPart: "Legs",      equipment: "Barbell",  category: "hinge",     defaultRestSeconds: 180),
        .init(name: "Hip Thrust",             bodyPart: "Legs",      equipment: "Barbell",  category: "hinge",     defaultRestSeconds: 120),
        .init(name: "Calf Raise",             bodyPart: "Legs",      equipment: "Machine",  category: "isolation", defaultRestSeconds: 60),
        // Arms
        .init(name: "Bicep Curl",             bodyPart: "Arms",      equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60),
        .init(name: "Hammer Curl",            bodyPart: "Arms",      equipment: "Dumbbell", category: "isolation", defaultRestSeconds: 60),
        .init(name: "Tricep Pushdown",        bodyPart: "Arms",      equipment: "Cable",    category: "isolation", defaultRestSeconds: 60),
        // Core
        .init(name: "Plank",                  bodyPart: "Core",      equipment: "Bodyweight", category: "core",    defaultRestSeconds: 60),
        .init(name: "Hanging Leg Raise",      bodyPart: "Core",      equipment: "Bodyweight", category: "core",    defaultRestSeconds: 60)
    ]
}
