import SwiftUI

/// First-launch onboarding. Three swipeable pages on a full-bleed accent
/// gradient: Welcome → AI → Orient. Sets `hasCompletedOnboarding` in
/// AppStorage on completion or skip; never re-shown.
///
/// Visual language matches PR 9: ForgeMark / ForgeWordmark, Ember accent,
/// rounded display type, eyebrow caps. White-on-accent throughout so the
/// whole flow reads as one branded moment.
struct OnboardingView: View {

    let onComplete: () -> Void

    @State private var page: Int = 0
    @State private var showingKeySheet = false
    @State private var hasStoredKey: Bool = KeychainService.hasKey()

    var body: some View {
        ZStack {
            Theme.Palette.heroGradient(.accentColor)
                .ignoresSafeArea()

            TabView(selection: $page) {
                welcomeScreen
                    .tag(0)
                aiScreen
                    .tag(1)
                orientScreen
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
        .overlay(alignment: .topTrailing) {
            if page < 2 {
                Button("Skip") {
                    Haptics.tap()
                    complete()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, Theme.Spacing.lg)
                .padding(.trailing, Theme.Spacing.lg)
            }
        }
        .sheet(isPresented: $showingKeySheet, onDismiss: {
            hasStoredKey = KeychainService.hasKey()
        }) {
            KeyEntrySheet(hasStoredKey: $hasStoredKey)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Page 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.lg) {
                ForgeMark(size: 88)
                    .foregroundStyle(.white)
                ForgeWordmark(size: 18)
                    .foregroundStyle(.white.opacity(0.9))
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Built to lift.")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Workouts, weekly schedule, AI coach.\nAll on device.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            primaryButton(title: "Continue") {
                advance()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.md)
        }
    }

    // MARK: - Page 2: AI

    private var aiScreen: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer().frame(height: Theme.Spacing.xxl)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("TWO COACHES")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
                Text("One barbell.")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                personaRow(
                    title: "GymBro",
                    subtitle: "Direct training partner. Programming, technique, recovery.",
                    symbol: "bubble.left.and.text.bubble.right.fill"
                )
                personaRow(
                    title: "Coach",
                    subtitle: "Reads your workouts, schedule, PRs. Cites your real numbers.",
                    symbol: "chart.line.uptrend.xyaxis.circle.fill"
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                if hasStoredKey {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("AI Connected")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        Color.white.opacity(0.16),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
                    primaryButton(title: "Continue") { advance() }
                } else {
                    primaryButton(title: "Connect AI Key") {
                        Haptics.tap()
                        showingKeySheet = true
                    }
                    Button("Maybe later") {
                        Haptics.tap()
                        advance()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.md)
        }
    }

    private func personaRow(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Color.white.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.10),
            in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Page 3: Orient

    private var orientScreen: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer().frame(height: Theme.Spacing.xxl)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("QUICK TOUR")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Three taps.\nThat's it.")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.md) {
                tourRow(
                    number: "1",
                    title: "Home",
                    body: "Your day, your routines, the body map."
                )
                tourRow(
                    number: "2",
                    title: "AI",
                    body: "Chat with GymBro or Coach anytime."
                )
                tourRow(
                    number: "3",
                    title: "Sparkles button",
                    body: "Bottom-right of Home — instant Coach about your workouts."
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            primaryButton(title: "Open Forge") {
                Haptics.success()
                complete()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.md)
        }
    }

    private func tourRow(number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(number)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Color.white.opacity(0.16),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Shared

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func advance() {
        withAnimation(.spring(duration: 0.4)) {
            page += 1
        }
    }

    private func complete() {
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
