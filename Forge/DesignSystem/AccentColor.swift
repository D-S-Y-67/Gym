import SwiftUI

/// Curated accent palette. Six options — enough to feel personal,
/// few enough that every choice still looks intentional.
///
/// PR 9 introduced **Ember** (a deep warm orange-red) as the new default.
/// It's the only entry that's not a stock SwiftUI color — it gives Forge
/// an immediate identity that the system palette can't.
enum AppAccent: String, CaseIterable, Identifiable, Sendable {
    case ember
    case blue
    case indigo
    case teal
    case mint
    case orange

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .ember:  return Color(red: 0.85, green: 0.32, blue: 0.18)  // #D9522D
        case .blue:   return .blue
        case .indigo: return .indigo
        case .teal:   return .teal
        case .mint:   return .mint
        case .orange: return .orange
        }
    }

    var label: String {
        switch self {
        case .ember:  return "Ember"
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

