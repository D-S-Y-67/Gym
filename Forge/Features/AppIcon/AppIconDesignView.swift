import SwiftUI
import UIKit

/// PR 17: app-icon designer. Renders the Forge mark as actual glass plates
/// (translucent fill, top sheen, edge highlight) on an Ember gradient. The
/// canvas is laid out at 1024×1024 — Apple's required app-icon size — and
/// can be exported as a PNG via `ImageRenderer`. Drop the resulting file
/// into `Assets.xcassets/AppIcon.appiconset/` to ship it.
///
/// Why design-in-code: nothing here is rasterized at build time, so you
/// can iterate on colors, shapes, and highlights live and re-export.

// MARK: - Canvas

struct AppIconCanvas: View {
    /// Logical size; this is the design canvas. Caller scales as needed
    /// for on-screen preview (display) vs export (1024).
    let size: CGFloat

    init(size: CGFloat = 1024) {
        self.size = size
    }

    var body: some View {
        ZStack {
            background
            glassMark
                .frame(width: size * 0.78)
                .shadow(color: .black.opacity(0.32), radius: size * 0.05, y: size * 0.025)
            cornerSheen
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.235, style: .continuous))
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            // Deep Ember gradient, top-down — top brighter, bottom richer.
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.46, blue: 0.22),
                    Color(red: 0.65, green: 0.18, blue: 0.10),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft cool highlight to suggest a key light from upper-left.
            RadialGradient(
                colors: [Color.white.opacity(0.30), .clear],
                center: UnitPoint(x: 0.22, y: 0.18),
                startRadius: 0,
                endRadius: size * 0.62
            )

            // Faint warm accent in the lower-right for depth.
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.35).opacity(0.18), .clear],
                center: UnitPoint(x: 0.85, y: 0.85),
                startRadius: 0,
                endRadius: size * 0.45
            )
        }
    }

    // MARK: Mark

    /// Forge's barbell, redrawn as three glass elements: two plates flanking
    /// a bar. Each plate has a translucent fill, edge highlight, and a top
    /// sheen — meant to read as polished glass catching light.
    private var glassMark: some View {
        HStack(spacing: 0) {
            glassPlate
            glassBar
            glassPlate
        }
    }

    private var plateWidth: CGFloat { size * 0.20 }
    private var plateHeight: CGFloat { size * 0.62 }
    private var barWidth: CGFloat { size * 0.34 }
    private var barHeight: CGFloat { size * 0.13 }

    private var glassPlate: some View {
        ZStack {
            // Body — translucent vertical gradient.
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color.white.opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: plateWidth, height: plateHeight)

            // Edge stroke — brighter at the top, fading to barely-there at bottom.
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0.20)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: size * 0.004
                )
                .frame(width: plateWidth, height: plateHeight)

            // Top sheen — small bright capsule offset upward, blurred.
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: plateWidth * 0.7, height: plateHeight * 0.22)
                .offset(y: -plateHeight * 0.30)
                .blur(radius: size * 0.008)

            // Subtle warm refraction core — picks up the Ember background.
            Capsule()
                .fill(
                    Color(red: 1.0, green: 0.55, blue: 0.32)
                        .opacity(0.18)
                )
                .frame(width: plateWidth * 0.55, height: plateHeight * 0.55)
                .blur(radius: size * 0.025)
        }
    }

    private var glassBar: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            Color.white.opacity(0.50)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: barWidth, height: barHeight)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: barWidth, height: barHeight * 0.6)
                .offset(y: -barHeight * 0.2)
                .blur(radius: size * 0.004)
        }
    }

    // MARK: Corner sheen

    /// A diagonal arc of light across the upper-left, pushing the icon
    /// further into "polished glass" territory.
    private var cornerSheen: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size * 0.38))
            path.addQuadCurve(
                to: CGPoint(x: size * 0.55, y: 0),
                control: CGPoint(x: size * 0.10, y: size * 0.05)
            )
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Color.white.opacity(0.30), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .blendMode(.plusLighter)
    }
}

// MARK: - Design + export screen

struct AppIconDesignView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var sharedURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Live preview at on-screen size.
                    AppIconCanvas(size: 240)
                        .frame(width: 240, height: 240)
                        .shadow(color: .black.opacity(0.18), radius: 20, y: 10)
                        .padding(.top, Theme.Spacing.lg)

                    // Sample at iOS home-screen size to sanity-check legibility.
                    HStack(spacing: Theme.Spacing.lg) {
                        sampleAt(size: 60)
                        sampleAt(size: 76)
                        sampleAt(size: 120)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Theme.Typo.eyebrow("Export")
                        Text("Render at 1024×1024 and drop the PNG into Assets.xcassets → AppIcon.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    Button {
                        Haptics.tap()
                        export()
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Render & share PNG")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            Theme.Palette.accentGradient(.accentColor),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.Spacing.md)

                    if sharedURL != nil {
                        Text("Saved to a temp file. Pick AirDrop, Save to Files, or Mail in the share sheet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Palette.surfaceBackground)
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: Binding(
                get: { sharedURL.map(IdentifiableURL.init) },
                set: { _ in sharedURL = nil }
            )) { wrapper in
                ShareSheet(items: [wrapper.url])
            }
        }
    }

    private func sampleAt(size: CGFloat) -> some View {
        VStack(spacing: 6) {
            AppIconCanvas(size: size)
                .frame(width: size, height: size)
            Text("\(Int(size))pt")
                .font(.caption2.weight(.heavy).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func export() {
        let renderer = ImageRenderer(content: AppIconCanvas(size: 1024))
        renderer.scale = 1.0
        guard let image = renderer.uiImage,
              let data = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ForgeAppIcon-1024.png")
        try? data.write(to: url)
        sharedURL = url
        Haptics.success()
    }
}

// MARK: - Share sheet helpers

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.path }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview("Icon at 1024 (scaled)") {
    AppIconCanvas(size: 240)
        .frame(width: 240, height: 240)
        .padding()
}

#Preview("Design view") {
    AppIconDesignView()
}
