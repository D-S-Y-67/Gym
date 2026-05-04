import SwiftUI

/// App root. PR 2 swaps PR 1's `PreviewGallery` for the real `MainTabView`.
struct RootView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    RootView()
}
