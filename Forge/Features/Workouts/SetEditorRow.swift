import SwiftUI
import SwiftData

/// One row in a `WorkoutExerciseSection` sets table.
/// Set number, weight, reps, optional RPE, and a completion checkmark.
///
/// All edits flow through `@Bindable` directly into the SwiftData model;
/// the parent's `WorkoutSessionStore.flush()` runs on backgrounding.
struct SetEditorRow: View {

    @Bindable var set: ExerciseSet
    let onToggleCompleted: () -> Void

    private static let rpeOptions: [Double] = [6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10]

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            setBadge
            weightField
            timesSeparator
            repsField
            rpeMenu
            Spacer(minLength: 0)
            completionToggle
        }
        .padding(.vertical, Theme.Spacing.xs)
        .opacity(set.isWarmup ? 0.7 : 1.0)
        .animation(.spring(duration: 0.2), value: set.isCompleted)
    }

    // MARK: - Pieces

    private var setBadge: some View {
        Text(set.isWarmup ? "W" : "\(set.setIndex + 1)")
            .font(.callout.weight(.semibold).monospacedDigit())
            .foregroundStyle(set.isWarmup ? .secondary : .primary)
            .frame(width: 28, height: 28)
            .background(
                Circle().fill(Color(.tertiarySystemBackground))
            )
            .accessibilityLabel(set.isWarmup ? "Warm-up set" : "Working set \(set.setIndex + 1)")
    }

    private var weightField: some View {
        TextField("0", value: $set.weight, format: .number.precision(.fractionLength(0...1)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 64)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
            .accessibilityLabel("Weight in pounds")
            .accessibilityValue("\(Int(set.weight)) pounds")
    }

    private var timesSeparator: some View {
        Text("×")
            .font(.callout)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }

    private var repsField: some View {
        TextField("0", value: $set.reps, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 48)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
            .accessibilityLabel("Reps")
            .accessibilityValue("\(set.reps) reps")
    }

    private var rpeMenu: some View {
        Menu {
            Button("None") { set.rpe = nil }
            ForEach(Self.rpeOptions, id: \.self) { value in
                Button(rpeText(value)) { set.rpe = value }
            }
        } label: {
            Text(rpeLabel)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(set.rpe == nil ? .secondary : .primary)
                .frame(minWidth: 44)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .accessibilityLabel(set.rpe == nil ? "RPE, not set" : "RPE \(rpeText(set.rpe!))")
    }

    private var completionToggle: some View {
        Button {
            onToggleCompleted()
        } label: {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(set.isCompleted ? Color.accentColor : Color.secondary)
                .symbolRenderingMode(.hierarchical)
                .contentShape(Rectangle())
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(set.isCompleted ? "Completed" : "Mark complete")
        .accessibilityAddTraits(set.isCompleted ? .isSelected : [])
    }

    private var rpeLabel: String {
        if let rpe = set.rpe {
            return rpeText(rpe)
        }
        return "RPE"
    }

    private func rpeText(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.01 {
            return "\(Int(rounded))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}
