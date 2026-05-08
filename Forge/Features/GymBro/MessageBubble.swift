import SwiftUI

/// One chat message rendered as an iMessage-style bubble.
/// User messages right-aligned in the accent color; assistant messages
/// left-aligned in a neutral surface. Empty assistant placeholders show
/// an animated typing indicator.
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            switch message.role {
            case .user:
                Spacer(minLength: 48)
                bubble
            case .assistant:
                bubble
                Spacer(minLength: 48)
            }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        if message.isStreamingPlaceholder {
            TypingIndicator()
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(assistantBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        } else {
            content
                .font(.body)
                .foregroundStyle(textColor)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .accessibilityLabel(accessibilityLabel)
        }
    }

    /// Plain text for user messages (their own input doesn't need rich
    /// rendering); markdown + LaTeX for assistant replies.
    @ViewBuilder
    private var content: some View {
        switch message.role {
        case .user:
            Text(message.content)
                .textSelection(.enabled)
        case .assistant:
            RichMessageText(content: message.content)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch message.role {
        case .user:
            Color.accentColor
        case .assistant:
            assistantBackground
        }
    }

    @ViewBuilder
    private var assistantBackground: some View {
        Theme.Palette.surfaceSubtle
    }

    private var textColor: Color {
        switch message.role {
        case .user: return .white
        case .assistant: return .primary
        }
    }

    private var accessibilityLabel: String {
        switch message.role {
        case .user: return "You said: \(message.content)"
        case .assistant: return "GymBro said: \(message.content)"
        }
    }
}

/// Three pulsing dots, used while waiting for the first token of an assistant reply.
private struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(phase == index ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .frame(height: 18)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
        .accessibilityLabel("GymBro is typing")
    }
}

#Preview("Bubbles") {
    ScrollView {
        VStack(spacing: Theme.Spacing.sm) {
            MessageBubble(message: .init(role: .user, content: "How should I deload after a heavy block?"))
            MessageBubble(message: .init(role: .assistant, content: "Drop volume to 50–60% and intensity to ~70% for one week. Keep movement quality high. The goal is fatigue dissipation, not stimulus."))
            MessageBubble(message: .init(role: .assistant, content: ""))
            MessageBubble(message: .init(role: .user, content: "Cool, thanks."))
        }
        .padding(Theme.Spacing.md)
    }
}
