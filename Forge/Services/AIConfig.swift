import Foundation

/// Single source of truth for AI provider configuration. Swap the endpoint
/// or model in one place — `QwenService` and any per-feature config builds
/// on these values.
///
/// Default: apiyi.com OpenAI-compatible gateway with the `qwen3.5-flash`
/// dated snapshot. The `/v1` segment follows the OpenAI convention shared
/// by apiyi.
enum AIConfig {

    /// OpenAI-compatible chat-completions base URL.
    static let baseURL = URL(string: "https://api.apiyi.com/v1")!

    /// Default model used when callers don't specify.
    static let defaultModel = "qwen3.5-flash-2026-02-23"

    /// Path appended to `baseURL` for chat completions.
    static let chatCompletionsPath = "chat/completions"

    /// Default sampling temperature for general chat (GymBro). Coach
    /// analysis lowers this for more deterministic output.
    static let defaultTemperature: Double = 0.7

    /// Built once for the whole app — `URLSession.shared` is fine here, but
    /// a custom session lets us set sensible timeouts for the streaming case.
    static let defaultTimeout: TimeInterval = 60

    /// Maximum total time we'll wait on a streaming connection before giving up.
    static let streamingTimeout: TimeInterval = 300
}
