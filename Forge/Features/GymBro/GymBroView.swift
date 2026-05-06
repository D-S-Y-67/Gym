import SwiftUI

/// GymBro tab — free-form streaming chat with the QwenService.
///
/// Three states:
/// 1. No API key → full-screen "Connect AI" empty state
/// 2. Key set, no messages → suggestion chips above the input bar
/// 3. Conversation in progress → message list, streaming bubble, stop button
struct GymBroView: View {

    @State private var vm = GymBroViewModel()
    @State private var draft: String = ""
    @State private var hasKey: Bool = KeychainService.hasKey()
    @State private var showingKeySheet = false

    private static let suggestions: [String] = [
        "How do I break a bench plateau?",
        "What's a sensible deload protocol?",
        "How many sets per muscle per week for hypertrophy?",
        "Cues for keeping my back tight in the squat?"
    ]

    var body: some View {
        Group {
            if hasKey {
                chatContent
            } else {
                connectAIEmptyState
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("GymBro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingKeySheet) {
            KeyEntrySheet(hasStoredKey: $hasKey)
        }
        .onChange(of: showingKeySheet) { _, isPresented in
            if !isPresented {
                let nowHasKey = KeychainService.hasKey()
                if hasKey != nowHasKey { hasKey = nowHasKey }
                if !nowHasKey { vm.clear() }
            }
        }
        .alert(
            "Something went wrong",
            isPresented: errorAlertBinding,
            presenting: vm.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if hasKey, !vm.messages.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    Haptics.warning()
                    vm.clear()
                    draft = ""
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Clear chat")
            }
        }
    }

    // MARK: - States

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if vm.messages.isEmpty {
                    emptyChatHero
                        .padding(.top, Theme.Spacing.xl)
                } else {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(vm.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(BottomAnchor.id)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.sm)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: vm.messages.last?.id) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: vm.messages.last?.content) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatInputBar(
                text: $draft,
                isStreaming: vm.isStreaming,
                onSend: send,
                onStop: { vm.cancelStream() }
            )
        }
    }

    private var emptyChatHero: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("Ask GymBro anything")
                    .font(.title3.weight(.semibold))
                Text("Programming, technique, recovery, nutrition basics — your senior-lifter friend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Self.suggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        draft = suggestion
                        send()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var connectAIEmptyState: some View {
        EmptyStateView(
            symbol: "key",
            title: "Connect AI to chat",
            message: "Add your API key in Profile or here — needed to talk to GymBro and Coach.",
            cta: .init(title: "Connect AI", systemImage: "key.fill") {
                Haptics.tap()
                showingKeySheet = true
            }
        )
    }

    // MARK: - Helpers

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Haptics.tap()
        vm.send(text)
        draft = ""
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.18)) {
            proxy.scrollTo(BottomAnchor.id, anchor: .bottom)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )
    }

    private enum BottomAnchor {
        static let id = "gymbro-bottom"
    }
}

private struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Theme.Spacing.sm)
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { GymBroView() }
}
