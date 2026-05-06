import SwiftUI
import SwiftData

/// Pre-finish review sheet. Shows the workout summary, lets you add notes,
/// and either saves (running PR detection) or discards. Dismissing the
/// sheet without saving leaves the workout in-progress.
struct FinishWorkoutSheet: View {

    @Bindable var workout: Workout
    let onSave: () -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingDiscardConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    summaryCard
                    notesCard
                }
                .padding(.vertical, Theme.Spacing.lg)
            }
            .background(Theme.Palette.surfaceBackground)
            .navigationTitle("Finish Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.success()
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(role: .destructive) {
                    showingDiscardConfirm = true
                } label: {
                    Label("Discard Workout", systemImage: "trash")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .padding(Theme.Spacing.md)
            }
            .confirmationDialog(
                "Discard this workout? This can't be undone.",
                isPresented: $showingDiscardConfirm,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    Haptics.warning()
                    onDiscard()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Summary")
                    .font(.headline)

                HStack {
                    summaryStat(label: "Duration", value: durationText)
                    Divider().frame(height: 32)
                    summaryStat(label: "Volume", value: volumeText)
                    Divider().frame(height: 32)
                    summaryStat(label: "Sets", value: "\(workout.totalCompletedSets)")
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Notes")
                    .font(.headline)
                TextField("How did it feel?", text: $workout.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func summaryStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var durationText: String {
        let total = Int(workout.duration())
        let m = total / 60
        let s = total % 60
        if m >= 60 {
            let h = m / 60
            let mm = m % 60
            return String(format: "%dh %02dm", h, mm)
        }
        return String(format: "%d:%02d", m, s)
    }

    private var volumeText: String {
        let v = Int(workout.totalVolume.rounded())
        if v >= 1_000 {
            return String(format: "%.1fk", workout.totalVolume / 1_000)
        }
        return "\(v)"
    }
}
