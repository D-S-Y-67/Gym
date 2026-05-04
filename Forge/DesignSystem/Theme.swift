import SwiftUI

/// Spacing, radii, and elevation tokens.
///
/// Colors are accessed directly via SwiftUI's semantic system colors
/// (`.primary`, `.secondary`, `Color(.systemBackground)`, `Color(.systemGroupedBackground)`).
/// Typography uses the system font stack via `.font(.title)`, `.headline`, etc.
/// **No hard-coded hex values anywhere in the app.**
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
}
