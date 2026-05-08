import SwiftUI

/// Solid-fill chip for filtering Library by body part. Accent fill when
/// selected, `.tertiarySystemFill` when not. No fake glass — chips are
/// navigational primitives, the filled state is the affordance.
struct BodyPartChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(chipBackground)
                .frame(minHeight: 36)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: isSelected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            Capsule().fill(Color.accentColor)
        } else {
            Capsule().fill(Color(.tertiarySystemFill))
        }
    }
}
