import Foundation

/// Single point of access to the Qwen (DashScope OpenAI-compatible) chat API.
///
/// Why an actor: gives the API surface a stable identity, avoids accidental
/// duplicate session creation, and lets us add per-instance state (conversation
/// caches, rate limiter) later without touching call sites. Stateless work is
/// `nonisolated` so building requests doesn't pay an actor hop.
///
/// Three entry points:
/// - `chat(messages:)` — non-streaming, with retry+backoff on 429/5xx
/// - `streamChat(messages:)` — token-by-token deltas via SSE, single attempt
/// - `testConnection(apiKey:)` — short round-trip used by `KeyEntrySheet`
actor QwenService {

    static let shared = QwenService()

    private init() {}

    // MARK: - Public types

    /// One turn in the chat. `role` is "system", "user", or "assistant".
    struct Message: Codable, Sendable, Equatable {
        let role: String
        let content: String

        static func system(_ content: String) -> Message { .init(role: "system", content: content) }
        static func user(_ content: String) -> Message { .init(role: "user", content: content) }
        static func assistant(_ content: String) -> Message { .init(role: "assistant", content: content) }
    }

    enum AIError: Error, LocalizedError, Sendable {
        case missingAPIKey
        case unauthorized
        case rateLimited
        case server(status: Int)
        case network(String)
        case decoding
        case streamParse
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Set your Qwen API key in Profile."
            case .unauthorized:
                return "Key was rejected. Double-check that you copied it correctly."
            case .rateLimited:
                return "Too many requests. Try again in a moment."
            case .server(let status):
                return "Qwen API error (\(status)). Try again later."
            case .network(let message):
                return message
            case .decoding, .streamParse, .invalidResponse:
                return "Couldn't read the response from Qwen."
            }
        }

        fileprivate var isRetryable: Bool {
            switch self {
            case .rateLimited, .server, .network: return true
            default: return false
            }
        }
    }

    // MARK: - Session

    nonisolated private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AIConfig.defaultTimeout
        config.timeoutIntervalForResource = AIConfig.streamingTimeout
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    // MARK: - Non-streaming chat

    /// Single-response completion. Retries on transient failures
    /// (429 / 5xx / network) up to 3 attempts with exponential backoff.
    func chat(
        messages: [Message],
        model: String = AIConfig.defaultModel,
        temperature: Double = AIConfig.defaultTemperature
    ) async throws -> String {
        guard let apiKey = KeychainService.load() else {
            throw AIError.missingAPIKey
        }
        return try await withRetry {
            try await self.performChat(
                apiKey: apiKey,
                messages: messages,
                model: model,
                temperature: temperature
            )
        }
    }

    /// One-shot connectivity test. Sends a minimal completion at temperature 0
    /// and returns successfully if the HTTP response is 2xx. Used by
    /// `KeyEntrySheet` before the user commits the key.
    func testConnection(apiKey: String, model: String = AIConfig.defaultModel) async throws {
        let probe = [Message.user("Reply with the single word: ok")]
        _ = try await performChat(
            apiKey: apiKey,
            messages: probe,
            model: model,
            temperature: 0
        )
    }

    private func performChat(
        apiKey: String,
        messages: [Message],
        model: String,
        temperature: Double
    ) async throws -> String {
        let request = try Self.buildRequest(
            apiKey: apiKey,
            messages: messages,
            model: model,
            temperature: temperature,
            stream: false
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.network(error.localizedDescription)
        }

        try Self.validate(response)

        do {
            let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content else {
                throw AIError.invalidResponse
            }
            return content
        } catch let aiError as AIError {
            throw aiError
        } catch {
            throw AIError.decoding
        }
    }

    // MARK: - Streaming chat

    /// Server-sent events stream. Yields content deltas (not whole messages).
    /// Caller cancels by cancelling the consuming Task.
    ///
    /// No retry: if a stream errors mid-flight the partial output has already
    /// been emitted, so a retry would replay tokens. Initial connection errors
    /// surface to the caller as a single `AIError`.
    nonisolated func streamChat(
        messages: [Message],
        model: String = AIConfig.defaultModel,
        temperature: Double = AIConfig.defaultTemperature
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let apiKey = KeychainService.load() else {
                        throw AIError.missingAPIKey
                    }
                    let request = try Self.buildRequest(
                        apiKey: apiKey,
                        messages: messages,
                        model: model,
                        temperature: temperature,
                        stream: true
                    )

                    let (bytes, response): (URLSession.AsyncBytes, URLResponse)
                    do {
                        (bytes, response) = try await self.session.bytes(for: request)
                    } catch {
                        throw AIError.network(error.localizedDescription)
                    }
                    try Self.validate(response)

                    let decoder = JSONDecoder()
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line
                            .dropFirst(5)
                            .trimmingCharacters(in: .whitespaces)
                        if payload.isEmpty { continue }
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8) else {
                            throw AIError.streamParse
                        }
                        do {
                            let chunk = try decoder.decode(ChatCompletionStreamChunk.self, from: data)
                            if let delta = chunk.choices.first?.delta.content, !delta.isEmpty {
                                continuation.yield(delta)
                            }
                        } catch {
                            throw AIError.streamParse
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Request building / validation

    nonisolated private static func buildRequest(
        apiKey: String,
        messages: [Message],
        model: String,
        temperature: Double,
        stream: Bool
    ) throws -> URLRequest {
        let url = AIConfig.baseURL.appendingPathComponent(AIConfig.chatCompletionsPath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if stream {
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        }

        let body = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            stream: stream
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    nonisolated private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        switch http.statusCode {
        case 200..<300: return
        case 401, 403: throw AIError.unauthorized
        case 429: throw AIError.rateLimited
        default: throw AIError.server(status: http.statusCode)
        }
    }

    // MARK: - Retry

    private func withRetry<T: Sendable>(
        maxAttempts: Int = 3,
        _ body: () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var delayMs: UInt64 = 500
        while true {
            attempt += 1
            do {
                return try await body()
            } catch let error as AIError where attempt < maxAttempts && error.isRetryable {
                try await Task.sleep(nanoseconds: delayMs * 1_000_000)
                delayMs *= 2
            }
        }
    }
}

// MARK: - Wire types

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [QwenService.Message]
    let temperature: Double
    let stream: Bool
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct ChatCompletionStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let role: String?
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}
