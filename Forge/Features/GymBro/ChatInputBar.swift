import SwiftUI

/// Bottom composer: multi-line text field plus a send / stop button. Mounted
/// via `safeAreaInset(edge: .bottom)` so it floats above the keyboard.
struct ChatInputBar: View {

    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !isStreaming && !trimmed.isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
            TextField("Ask GymBro…", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .focused($focused)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .submitLabel(.send)
                .onSubmit {
                    if canSend { onSend() }
                }

            Button {
                if isStreaming {
                    onStop()
                } else {
                    onSend()
                }
            } label: {
                Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(buttonBackground)
                    .clipShape(Circle())
            }
            .disabled(!isStreaming && !canSend)
            .accessibilityLabel(isStreaming ? "Stop response" : "Send message")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.bar)
    }

    private var buttonBackground: Color {
        if isStreaming { return .red }
        return canSend ? .accentColor : Color.secondary.opacity(0.4)
    }
}

#Preview("Idle") {
    StatefulPreview("") { binding in
        ChatInputBar(text: binding, isStreaming: false, onSend: {}, onStop: {})
    }
}

#Preview("Streaming") {
    StatefulPreview("") { binding in
        ChatInputBar(text: binding, isStreaming: true, onSend: {}, onStop: {})
    }
}

private struct StatefulPreview<Content: View>: View {
    @State private var value: String
    let content: (Binding<String>) -> Content
    init(_ initial: String, @ViewBuilder content: @escaping (Binding<String>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
