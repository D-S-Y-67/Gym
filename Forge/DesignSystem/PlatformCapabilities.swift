import Foundation

/// Single source of truth for iOS-version-dependent capability checks.
///
/// **Rule:** the only `#available` checks in the app live here (and inside
/// the wrapper modifiers in `GlassComponents.swift` that branch on these flags).
/// Feature views must never branch on iOS version directly — they call
/// modifiers like `.appGlassBackground()` and let the design system decide.
enum PlatformCapabilities {

    /// Native Liquid Glass APIs (`.glassEffect`, `GlassEffectContainer`,
    /// `.buttonStyle(.glass)`, etc.) are available.
    static var supportsLiquidGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    /// `.symbolEffect(.wiggle)` and other expanded symbol effects.
    static var supportsExpandedSymbolEffects: Bool {
        if #available(iOS 18.0, *) { return true }
        return false
    }
}
