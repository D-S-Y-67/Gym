import SwiftUI
import SwiftData

/// One exercise's block within `ActiveWorkoutView`: header (name, rest
/// setting, overflow menu) plus the sets table and an "Add Set" row.
struct WorkoutExerciseSection: View {

    @Bindable var workoutExercise: WorkoutExercise
    let onToggleSet: (ExerciseSet) -> Void
    let onAddSet: () -> Void
    let onDeleteSet: (ExerciseSet) -> Void
    let onChangeRest: (Int) -> Void
    let onRemove: () -> Void

    private let restPresets: [Int] = [0, 30, 60, 90, 120, 150, 180, 240]

    var body: some View {
        GlassCard(cornerRadius: Theme.Radius.lg, padding: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                header
                Divider()
                ForEach(workoutExercise.orderedSets) { set in
                    SetEditorRow(set: set) { onToggleSet(set) }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteSet(set)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                addSetButton
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workoutExercise.exercise?.name ?? "Exercise")
                    .font(.headline)
                Text(workoutExercise.exercise?.bodyPart ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            restMenu
            overflowMenu
        }
    }

    private var restMenu: some View {
        Menu {
            ForEach(restPresets, id: \.self) { seconds in
                Button(formatRest(seconds)) { onChangeRest(seconds) }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.footnote)
                Text(formatRest(workoutExercise.restSeconds))
                    .font(.footnote.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(.tertiarySystemBackground))
            )
        }
        .accessibilityLabel("Rest timer, \(formatRest(workoutExercise.restSeconds))")
    }

    private var overflowMenu: some View {
        Menu {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove Exercise", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Exercise options")
    }

    private var addSetButton: some View {
        Button {
            Haptics.tap()
            onAddSet()
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                Text("Add Set")
                Spacer()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.tint)
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add set")
    }

    private func formatRest(_ seconds: Int) -> String {
        if seconds == 0 { return "Off" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return remainder == 0 ? "\(minutes)m" : "\(minutes)m \(remainder)s"
    }
}
