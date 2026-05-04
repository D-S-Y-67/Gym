import SwiftUI

/// Curated accent palette. Five options — enough to feel personal,
/// few enough that every choice still looks intentional.
enum AppAccent: String, CaseIterable, Identifiable, Sendable {
    case blue
    case indigo
    case teal
    case mint
    case orange

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .indigo: return .indigo
        case .teal:   return .teal
        case .mint:   return .mint
        case .orange: return .orange
        }
    }

    var label: String {
        switch self {
        case .blue:   return "Blue"
        case .indigo: return "Indigo"
        case .teal:   return "Teal"
        case .mint:   return "Mint"
        case .orange: return "Orange"
        }
    }

    /// Persistence key for `@AppStorage`. Single string so views can read
    /// the preference without coupling to a wrapper class.
    static let storageKey = "appAccent"
}
