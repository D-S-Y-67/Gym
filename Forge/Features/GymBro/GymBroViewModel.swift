import Foundation
import Observation

/// State holder for the GymBro chat tab. Owns the message log, the active
/// streaming task, and the error surface. View binds to it via `@State` and
/// observes its properties through the `@Observable` macro.
///
/// Lifecycle: created when `GymBroView` instantiates, lives for the lifetime
/// of the tab (not the app — switching tabs doesn't recreate the view).
/// Messages are not persisted; killing the app drops them.
@MainActor
@Observable
final class GymBroViewModel {

    // MARK: - Published state

    private(set) var messages: [ChatMessage] = []
    private(set) var isStreaming: Bool = false
    var errorMessage: String?

    // MARK: - Private

    private var streamTask: Task<Void, Never>?

    // MARK: - Actions

    /// Appends a user message and an empty assistant placeholder, then kicks
    /// off a streaming completion that fills the placeholder as deltas arrive.
    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        errorMessage = nil

        let userMessage = ChatMessage(role: .user, content: trimmed)
        let assistantPlaceholder = ChatMessage(role: .assistant, content: "")
        messages.append(userMessage)
        messages.append(assistantPlaceholder)

        let placeholderID = assistantPlaceholder.id
        let history = buildAPIMessages()

        isStreaming = true
        streamTask = Task { [weak self] in
            await self?.runStream(messages: history, placeholderID: placeholderID)
        }
    }

    /// Stops the current stream. Keeps any partial response that's already on screen.
    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        // If the assistant message is still empty (cancel before first token),
        // remove it so the user isn't left with a phantom blank bubble.
        if let last = messages.last, last.isStreamingPlaceholder {
            messages.removeLast()
        }
    }

    /// Clears the conversation. Cancels any in-flight stream first.
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
            // Swallow CancellationError — that's our own cancel(), not a real failure.
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
        // If we never got any content, drop the placeholder. If we got partial
        // content, leave it on screen so the user can read what arrived.
        if accumulated.isEmpty,
           let idx = messages.firstIndex(where: { $0.id == placeholderID }) {
            messages.remove(at: idx)
        }
    }

    // MARK: - History assembly

    /// Converts the displayed messages into the API's message format, prefixed
    /// with the GymBro system prompt. Skips the empty assistant placeholder
    /// (the one we're about to fill) since we're asking the API to produce it.
    private func buildAPIMessages() -> [QwenService.Message] {
        var apiMessages: [QwenService.Message] = [.system(AIPrompts.gymBro)]
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
