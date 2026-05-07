import SwiftUI

/// Spacing, radii, elevation, color tokens, and typography helpers.
///
/// PR 1 launched with system-default colors. PR 8 introduces a small custom
/// palette (warm-neutral surfaces) and typography helpers (eyebrow, display
/// numeral) so the app stops reading as "iOS Settings template." The
/// frosted-glass `GlassCard` material is preserved — that's working as identity.
enum Theme {

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let pill: CGFloat = 999
    }

    /// Used only by the iOS 17–25 fallback path. On iOS 26 the native glass
    /// material conveys depth itself and these are not consulted.
    enum Elevation {
        static let cardShadowRadius: CGFloat = 1
        static let cardShadowOpacity: Double = 0.08
        static let cardShadowYOffset: CGFloat = 1
    }

    /// Custom surface palette. Warm off-white in light mode, near-black with
    /// a faintly cool undertone in dark mode. The intent is to shift the
    /// app's overall feel away from the cool blue-grey of stock iOS.
    enum Palette {
        /// Replaces `Color(.systemGroupedBackground)` for screen backgrounds.
        static let surfaceBackground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
                : UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1)
        })

        /// Replaces `Color(.systemBackground)` for elevated cards.
        static let surfaceCard = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1)
                : .white
        })

        /// Replaces `Color(.secondarySystemBackground)` and
        /// `Color(.tertiarySystemBackground)` for sub-cards / chips / bubbles.
        static let surfaceSubtle = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
                : UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1)
        })

        /// Subtle two-stop gradient applied to primary CTAs and the hero
        /// card's top ribbon. The 0.78 stop keeps the lighter end legible
        /// over white text without going washed-out.
        static func accentGradient(_ accent: Color) -> LinearGradient {
            LinearGradient(
                colors: [accent, accent.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Richer gradient used by the full-bleed home hero. Goes from the
        /// raw accent at top to a darker bottom edge so the page below
        /// reads as "tucked under" the hero rather than co-equal with it.
        static func heroGradient(_ accent: Color) -> LinearGradient {
            LinearGradient(
                stops: [
                    .init(color: accent, location: 0),
                    .init(color: accent.opacity(0.92), location: 0.55),
                    .init(color: accent.opacity(0.72), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Reusable typographic moments. The "eyebrow" gives section headers a
    /// magazine feel; "displayNumeral" makes hero stats look like a lifter's
    /// notebook, not a generic data row.
    enum Typo {
        static func eyebrow(_ text: String) -> some View {
            Text(text.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }

        static func displayNumeral(_ text: String, size: CGFloat = 28) -> some View {
            Text(text)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .monospacedDigit()
        }

        /// The big hero day number on the Workouts home (e.g. "06").
        /// Rounded, very heavy, monospaced so it stays steady at the
        /// minute mark.
        static func heroNumeral(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 88, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }

        /// Non-numeric large rounded display text used by hero headlines
        /// that aren't numerals (AIHub "Two coaches.", Onboarding tagline,
        /// StarterPrograms title). Centralized so all heroes share size +
        /// weight + design without scattering raw `.system(size:)` calls.
        static func heroHeadline(_ text: String, size: CGFloat = 44) -> some View {
            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }
}

