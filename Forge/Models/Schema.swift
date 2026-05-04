import Foundation
import SwiftData

// MARK: - SwiftData schema stubs
//
// These types exist so the `ModelContainer` in `ForgeApp` has a complete
// schema from day one. Fields are intentionally minimal — each feature PR
// will expand the relevant model with the properties and relationships it
// actually needs (sets per workout, exercises per routine, chat threads, etc.).
// Keeping them as stubs avoids schema migrations during early development
// while still letting us reference the types throughout the app.

@Model
final class Workout {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var notes: String

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        endedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var bodyPart: String
    var equipment: String

    init(
        id: UUID = UUID(),
        name: String = "",
        bodyPart: String = "",
        equipment: String = ""
    ) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.equipment = equipment
    }
}

@Model
final class ExerciseSet {
    var id: UUID
    var weight: Double
    var reps: Int
    var rpe: Double?
    var completedAt: Date

    init(
        id: UUID = UUID(),
        weight: Double = 0,
        reps: Int = 0,
        rpe: Double? = nil,
        completedAt: Date = .now
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.completedAt = completedAt
    }
}

@Model
final class Routine {
    var id: UUID
    var name: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var role: String          // "user" | "assistant" | "system"
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        role: String = "user",
        content: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}
