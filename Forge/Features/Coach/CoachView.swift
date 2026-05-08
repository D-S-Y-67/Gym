import SwiftUI
import SwiftData

/// Coach tab — workout-aware streaming chat.
///
/// Reuses `MessageBubble`, `ChatInputBar`, `RichMessageText` from the GymBro
/// feature. The difference is the system prompt: `CoachViewModel` injects
/// a fresh `CoachContext.build(...)` block on every send so the model sees
/// current workouts, PRs, and schedule.
///
/// Three states: no key → full-screen "Connect AI" CTA. Key set + no
/// messages → analytical hero + quick-action chips. In conversation →
/// streaming bubbles with auto-scroll.
struct CoachView: View {

    @State private var vm = CoachViewModel()
    @State private var draft: String = ""
    @State private var hasKey: Bool = KeychainService.hasKey()
    @State private var showingKeySheet = false

    @Environment(\.modelContext) private var modelContext

    private static let suggestions: [String] = [
        "Analyze this past week of training.",
        "Should I deload next week?",
        "Critique my current weekly split.",
        "Where am I stalling, and what should I change?"
    ]

    var body: some View {
        Group {
            if hasKey {
                chatContent
            } else {
                connectAIEmptyState
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingKeySheet) {
            KeyEntrySheet(hasStoredKey: $hasKey)
        }
        .onAppear {
            vm.attach(modelContext: modelContext)
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
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("Coach with context")
                    .font(.title3.weight(.semibold))
                Text("I can see your workouts, PRs, and weekly split. Ask anything analytical.")
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
            title: "Connect AI to coach",
            message: "Add your API key — needed to talk to Coach and GymBro.",
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
        static let id = "coach-bottom"
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
            .background(Theme.Palette.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { CoachView() }
}
