import SwiftUI

/// Routes inside the AI tab. Each chat is its own pushed sub-screen so the
/// landing hub remains the canonical entry point.
enum AIRoute: Hashable {
    case gymBro
    case coach
}

/// AI tab landing screen. PR 11 collapsed the previous separate GymBro
/// and Coach tabs into a single "AI" tab that opens here. Two cards —
/// "GymBro" (generalist training partner) and "Coach" (workout-aware
/// strength analyst) — each pushes the existing chat view.
///
/// Visual language matches PR 9: full-bleed accent gradient hero, eyebrow
/// caps, rounded display headline, ForgeMark on the hero. The two cards
/// below are differentiated by tone (warm vs deep) so they don't read as
/// duplicates.
struct AIHubView: View {

    @Binding var path: [AIRoute]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock
                VStack(spacing: Theme.Spacing.md) {
                    PersonaCard(
                        eyebrow: "Generalist",
                        title: "GymBro",
                        subtitle: "Direct, no fluff. Programming, technique, recovery — your senior-lifter friend.",
                        accentTint: .accentColor.opacity(0.92),
                        symbol: "bubble.left.and.text.bubble.right.fill",
                        action: {
                            Haptics.selection()
                            path.append(.gymBro)
                        }
                    )
                    PersonaCard(
                        eyebrow: "Workout-aware",
                        title: "Coach",
                        subtitle: "Reads your logged workouts, weekly schedule, and PRs. Cites your actual numbers.",
                        accentTint: .accentColor.opacity(0.72),
                        symbol: "chart.line.uptrend.xyaxis.circle.fill",
                        action: {
                            Haptics.selection()
                            path.append(.coach)
                        }
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                ForgeWordmark(size: 16)
                    .foregroundStyle(.white)
                Spacer()
                Text("AI")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: -2) {
                Theme.Typo.heroHeadline("Two coaches.", size: 36)
                    .foregroundStyle(.white)
                Theme.Typo.heroHeadline("One barbell.", size: 36)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Text("Pick the conversation you want.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xxl + Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.heroGradient(.accentColor))
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Theme.Radius.lg + 6,
                bottomTrailingRadius: Theme.Radius.lg + 6,
                style: .continuous
            )
        )
    }
}

// MARK: - PersonaCard

/// Big tappable card for one of the AI personas. Distinct accent tint so
/// GymBro and Coach don't look identical when stacked.
private struct PersonaCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let accentTint: Color
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: symbol)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(accentTint)
                    .frame(width: 52, height: 52)
                    .background(accentTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Theme.Typo.eyebrow(eyebrow)
                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGlassBackground(cornerRadius: Theme.Radius.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        AIHubView(path: .constant([]))
    }
}
