import SwiftUI

// MARK: - Glass background modifier

extension View {
    /// Surface treatment that adopts native Liquid Glass on iOS 26 and falls
    /// back to `.regularMaterial` + a subtle 1pt shadow on iOS 17–25.
    /// Layout, padding, and corner radius are identical across versions —
    /// only the surface fill differs.
    func appGlassBackground(
        cornerRadius: CGFloat = Theme.Radius.md
    ) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    }
}

private struct GlassBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                )
                .shadow(
                    color: Color.black.opacity(Theme.Elevation.cardShadowOpacity),
                    radius: Theme.Elevation.cardShadowRadius,
                    x: 0,
                    y: Theme.Elevation.cardShadowYOffset
                )
        }
    }
}

// MARK: - Glass container

/// Wraps content in `GlassEffectContainer` on iOS 26 (which optimizes glass
/// rendering and enables glass-to-glass morphing). Falls back to a plain
/// `ZStack` on older iOS — visually a no-op, but preserves layout semantics
/// so the wrapped views behave identically.
struct AppGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat = Theme.Spacing.sm, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            ZStack { content }
        }
    }
}

// MARK: - GlassCard

/// Primary content surface. Use for the Coach card, list-row groups,
/// sheet headers, and similar elevated regions.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = Theme.Radius.md,
        padding: CGFloat = Theme.Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGlassBackground(cornerRadius: cornerRadius)
    }
}

// MARK: - GlassButton

enum GlassButtonStyle {
    /// High-emphasis CTA. iOS 26: `.glassProminent`. Fallback: `.borderedProminent`.
    case primary
    /// Medium-emphasis. iOS 26: `.glass`. Fallback: `.bordered`.
    case secondary
    /// Low-emphasis text button — same on both versions.
    case tertiary
}

/// Standard call-to-action button. Always tinted with the user's accent color,
/// always emits a haptic tap, always at least 44pt tall for touch targets.
struct GlassButton: View {
    let title: String
    let systemImage: String?
    let style: GlassButtonStyle
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        style: GlassButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .modifier(GlassButtonStyling(style: style))
        .accessibilityLabel(title)
    }
}

private struct GlassButtonStyling: ViewModifier {
    let style: GlassButtonStyle

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .primary:
            if #available(iOS 26.0, *) {
                content
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
            } else {
                content
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        case .secondary:
            if #available(iOS 26.0, *) {
                content
                    .buttonStyle(.glass)
                    .controlSize(.large)
            } else {
                content
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        case .tertiary:
            content
                .buttonStyle(.borderless)
        }
    }
}

// MARK: - SectionHeader

/// Large title with an optional caption and trailing accessory.
struct SectionHeader<Trailing: View>: View {
    let title: String
    let caption: String?
    let trailing: Trailing

    init(
        _ title: String,
        caption: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.caption = caption
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                if let caption {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, caption: String? = nil) {
        self.init(title, caption: caption, trailing: { EmptyView() })
    }
}

// MARK: - AppListRow

/// Tappable list row with an optional leading SF Symbol, optional subtitle,
/// optional trailing accessory, and an optional action. Renders identically
/// on both iOS versions (the surrounding card supplies the surface treatment).
struct AppListRow<Trailing: View>: View {
    let icon: String?
    let title: String
    let subtitle: String?
    let trailing: Trailing
    let action: (() -> Void)?

    init(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        if let action {
            Button {
                Haptics.selection()
                action()
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        } else {
            rowContent
                .accessibilityElement(children: .combine)
        }
    }

    private var rowContent: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 28, height: 28, alignment: .center)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            trailing
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

extension AppListRow where Trailing == EmptyView {
    init(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            icon: icon,
            title: title,
            subtitle: subtitle,
            trailing: { EmptyView() },
            action: action
        )
    }
}
