import SwiftUI

/// Useful, non-decorative empty state. SF Symbol + title + message + optional CTA.
/// Used in any list/screen where a meaningful "do this next" prompt belongs.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let cta: CTA?

    struct CTA {
        let title: String
        let systemImage: String?
        let action: () -> Void

        init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.systemImage = systemImage
            self.action = action
        }
    }

    init(symbol: String, title: String, message: String, cta: CTA? = nil) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.cta = cta
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let cta {
                GlassButton(cta.title, systemImage: cta.systemImage, style: .primary, action: cta.action)
                    .frame(maxWidth: 280)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
