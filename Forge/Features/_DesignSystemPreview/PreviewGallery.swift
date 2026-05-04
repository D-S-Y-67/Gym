import SwiftUI

/// Renders every design-system primitive in a single scrollable screen so the
/// entire surface treatment can be visually verified on both an iOS 26
/// simulator (native Liquid Glass) and an iOS 17.5 simulator (materials).
///
/// This file is removed in PR 2 when `MainTabView` lands.
struct PreviewGallery: View {

    @AppStorage(AppAccent.storageKey)
    private var accentRaw: String = AppAccent.blue.rawValue

    @State private var hapticTrigger: Int = 0

    private var accent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
    }

    private var accentBinding: Binding<AppAccent> {
        Binding(
            get: { accent },
            set: { accentRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                AppGlassContainer {
                    VStack(spacing: Theme.Spacing.lg) {
                        platformBanner
                        cardsSection
                        buttonsSection
                        listRowsSection
                        accentSection
                        emptyStateSection
                    }
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Forge")
            .navigationBarTitleDisplayMode(.large)
            .sensoryFeedback(.selection, trigger: hapticTrigger)
        }
        .tint(accent.color)
    }

    // MARK: - Sections

    private var platformBanner: some View {
        GlassCard {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: PlatformCapabilities.supportsLiquidGlass
                      ? "sparkles"
                      : "square.stack.3d.up")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(PlatformCapabilities.supportsLiquidGlass
                         ? "Liquid Glass active"
                         : "Materials fallback active")
                        .font(.headline)
                    Text(PlatformCapabilities.supportsLiquidGlass
                         ? "iOS 26 — native .glassEffect on every surface."
                         : "iOS 17–25 — .regularMaterial + 1pt shadow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var cardsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SectionHeader("Cards", caption: "Primary content surface")
            GlassCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Coach")
                        .font(.headline)
                    Text("Your back volume is 32% below your 4-week average. Consider adding a row variant tomorrow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SectionHeader("Buttons", caption: "Three styles")
            VStack(spacing: Theme.Spacing.sm) {
                GlassButton("Start Workout", systemImage: "play.fill", style: .primary) {
                    hapticTrigger += 1
                }
                GlassButton("View Routine", systemImage: "list.bullet", style: .secondary) {
                    hapticTrigger += 1
                }
                GlassButton("Skip for now", style: .tertiary) {
                    hapticTrigger += 1
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var listRowsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SectionHeader("List rows")
            GlassCard(cornerRadius: Theme.Radius.lg, padding: 0) {
                VStack(spacing: 0) {
                    AppListRow(
                        icon: "dumbbell.fill",
                        title: "Bench Press",
                        subtitle: "5 × 5  ·  185 lb"
                    ) { hapticTrigger += 1 }
                    Divider().padding(.leading, 56)
                    AppListRow(
                        icon: "figure.strengthtraining.traditional",
                        title: "Barbell Row",
                        subtitle: "4 × 8  ·  155 lb"
                    ) { hapticTrigger += 1 }
                    Divider().padding(.leading, 56)
                    AppListRow(
                        icon: "trophy.fill",
                        title: "Personal Records",
                        subtitle: "3 new this week"
                    ) { hapticTrigger += 1 }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var accentSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SectionHeader("Accent color", caption: "Persists across launches")
            AccentPicker(selection: accentBinding)
                .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SectionHeader("Empty state")
            GlassCard(cornerRadius: Theme.Radius.lg) {
                EmptyStateView(
                    symbol: "calendar.badge.exclamationmark",
                    title: "No sessions logged this week",
                    message: "Start a workout or browse the library to begin.",
                    cta: .init(title: "Start Workout", systemImage: "play.fill") {
                        hapticTrigger += 1
                    }
                )
                .frame(minHeight: 240)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - AccentPicker

private struct AccentPicker: View {
    @Binding var selection: AppAccent

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(AppAccent.allCases) { accent in
                Button {
                    Haptics.selection()
                    selection = accent
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(selection == accent ? 0.9 : 0),
                                    lineWidth: 2
                                )
                                .padding(-4)
                        )
                        .animation(.spring(duration: 0.25), value: selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.label)
                .accessibilityAddTraits(selection == accent ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview("Default") {
    PreviewGallery()
}

#Preview("Dark mode") {
    PreviewGallery()
        .preferredColorScheme(.dark)
}

#Preview("Accessibility XL") {
    PreviewGallery()
        .environment(\.dynamicTypeSize, .accessibility3)
}
