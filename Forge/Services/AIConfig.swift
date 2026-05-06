import Foundation

/// Single source of truth for AI provider configuration. Swap the endpoint
/// or model in one place — `QwenService` and any per-feature config builds
/// on these values.
///
/// Default: Mainland China DashScope OpenAI-compatible endpoint with
/// `qwen-plus` (balanced quality + cost). To switch:
/// - International region → set `baseURL` to
///   `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
/// - Bigger model → `qwen3-max-latest`
/// - Cheaper model → `qwen-turbo`
enum AIConfig {

    /// OpenAI-compatible chat-completions base URL.
    static let baseURL = URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1")!

    /// Default model used when callers don't specify.
    static let defaultModel = "qwen-plus"

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
