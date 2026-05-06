import Foundation

/// In-memory chat message. Not a SwiftData model — GymBro is intentionally
/// non-persistent in v1 (sessions clear on app relaunch and on Disconnect).
struct ChatMessage: Identifiable, Equatable, Sendable {

    enum Role: Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    /// True for an assistant placeholder that hasn't received any tokens yet.
    /// Drives the typing indicator.
    var isStreamingPlaceholder: Bool {
        role == .assistant && content.isEmpty
    }
}
