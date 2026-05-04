import SwiftUI

/// PR 1 root: hosts the design-system `PreviewGallery` so both iOS 26
/// (Liquid Glass) and iOS 17 (materials fallback) simulators can be
/// visually verified before any feature work proceeds.
///
/// Replaced by the real `MainTabView` in PR 2 (workout logging).
struct RootView: View {
    var body: some View {
        PreviewGallery()
    }
}

#Preview {
    RootView()
}
