import SwiftUI
import UIKit
import AudioToolbox

/// Lightweight haptic helpers for use inside button action closures and
/// non-view contexts. Inside views that already track state changes, prefer
/// `.sensoryFeedback(_:trigger:)` directly — it's more idiomatic SwiftUI.
///
/// `UIImpact/Notification/Selection`FeedbackGenerator are main-actor isolated
/// on iOS 17+, so this enum is `@MainActor` to keep call sites clean under
/// Swift 6 strict concurrency.
@MainActor
enum Haptics {

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

/// System-sound feedback. Plays through the iOS ringer pipeline so the
/// silent switch silences it automatically — pair with a haptic so the
/// signal still lands when the phone is on silent.
enum Sounds {
    /// Short "tink" played when the rest timer hits zero.
    static func restComplete() {
        AudioServicesPlaySystemSound(1057)
    }
}
