import Foundation
import Observation
import SwiftData

/// State holder for the Coach chat tab. Mirrors GymBroViewModel but builds
/// a fresh system prompt on every send by appending CoachContext (recent
/// workouts, PRs, schedule) to the static persona.
///
/// Why rebuild per send and not once at view init:
/// - The user can log a new workout, hit a PR, or change their schedule
///   between messages. The Coach should reflect the *current* state, not
///   a snapshot from when the tab was opened.
@MainActor
@Observable
final class CoachViewModel {

    private(set) var messages: [ChatMessage] = []
    private(set) var isStreaming: Bool = false
    var errorMessage: String?

    /// Set by the view via `attach(modelContext:)`. Without it, sends fail
    /// with a clear error rather than crashing.
    private var modelContext: ModelContext?

    private var streamTask: Task<Void, Never>?

    // MARK: - Wiring

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        guard let modelContext else {
            errorMessage = "Couldn't read your training data. Reopen the Coach tab."
            return
        }

        errorMessage = nil

        let userMessage = ChatMessage(role: .user, content: trimmed)
        let assistantPlaceholder = ChatMessage(role: .assistant, content: "")
        messages.append(userMessage)
        messages.append(assistantPlaceholder)

        let placeholderID = assistantPlaceholder.id
        let history = buildAPIMessages(modelContext: modelContext)

        isStreaming = true
        streamTask = Task { [weak self] in
            await self?.runStream(messages: history, placeholderID: placeholderID)
        }
    }

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        if let last = messages.last, last.isStreamingPlaceholder {
            messages.removeLast()
        }
    }

    func clear() {
        cancelStream()
        messages.removeAll()
        errorMessage = nil
    }

    // MARK: - Stream loop

    private func runStream(messages history: [QwenService.Message], placeholderID: UUID) async {
        var accumulated = ""
        do {
            let stream = QwenService.shared.streamChat(messages: history)
            for try await delta in stream {
                if Task.isCancelled { break }
                accumulated += delta
                updatePlaceholder(id: placeholderID, content: accumulated)
            }
        } catch {
            if !(error is CancellationError) {
                handleStreamFailure(error, placeholderID: placeholderID, accumulated: accumulated)
            }
        }
        isStreaming = false
        streamTask = nil
    }

    private func updatePlaceholder(id: UUID, content: String) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[idx].content = content
    }

    private func handleStreamFailure(_ error: Error, placeholderID: UUID, accumulated: String) {
        errorMessage = error.localizedDescription
        if accumulated.isEmpty,
           let idx = messages.firstIndex(where: { $0.id == placeholderID }) {
            messages.remove(at: idx)
        }
    }

    // MARK: - History assembly

    /// Static persona + fresh user-context block + the visible chat history.
    /// The empty assistant placeholder (the one we're about to fill) is
    /// excluded since we're asking the API to generate it.
    private func buildAPIMessages(modelContext: ModelContext) -> [QwenService.Message] {
        let systemPrompt = AIPrompts.coach + "\n\n---\n\n" + CoachContext.build(modelContext: modelContext)
        var apiMessages: [QwenService.Message] = [.system(systemPrompt)]
        for message in messages where !message.content.isEmpty {
            switch message.role {
            case .user:
                apiMessages.append(.user(message.content))
            case .assistant:
                apiMessages.append(.assistant(message.content))
            }
        }
        return apiMessages
    }
}
