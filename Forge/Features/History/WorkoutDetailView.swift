import SwiftUI
import SwiftData

/// Read-only summary of a finished workout. Shows the duration, volume,
/// PRs achieved, the exercise/set breakdown, and any notes.
struct WorkoutDetailView: View {

    let workout: Workout

    @Query private var prs: [PersonalRecord]

    init(workout: Workout) {
        self.workout = workout
        let workoutID = workout.id
        _prs = Query(
            filter: #Predicate<PersonalRecord> { $0.sourceWorkoutId == workoutID }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                summaryCard
                if !prs.isEmpty {
                    prsCard
                }
                exercisesCard
                if !workout.notes.trimmingCharacters(in: .whitespaces).isEmpty {
                    notesCard
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Summary")
            GlassCard {
                HStack {
                    summaryStat(label: "Date", value: workout.startedAt.formatted(date: .abbreviated, time: .omitted))
                    Divider().frame(height: 32)
                    summaryStat(label: "Duration", value: durationText)
                    Divider().frame(height: 32)
                    summaryStat(label: "Volume", value: volumeText)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var prsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Personal records")
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(prs) { pr in
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(.tint)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pr.exercise?.name ?? "—")
                                    .foregroundStyle(.primary)
                                Text("Estimated 1RM  ·  \(formatWeight(pr.value)) lb")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .accessibilityElement(children: .combine)
                        if pr.id != prs.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Exercises")
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(workout.orderedExercises) { item in
                    exerciseBlock(item)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func exerciseBlock(_ item: WorkoutExercise) -> some View {
        GlassCard(cornerRadius: Theme.Radius.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(item.exercise?.name ?? "Exercise")
                    .font(.headline)
                Text(item.exercise?.bodyPart ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Divider()
                ForEach(item.orderedSets) { set in
                    setRow(set)
                }
            }
        }
    }

    private func setRow(_ set: ExerciseSet) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(set.isWarmup ? "W" : "\(set.setIndex + 1)")
                .font(.callout.monospacedDigit().weight(.semibold))
                .frame(width: 24)
            Text("\(formatWeight(set.weight)) lb × \(set.reps)")
                .font(.body.monospacedDigit())
            if let rpe = set.rpe {
                Text("· RPE \(formatRpe(rpe))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Completed")
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Not completed")
            }
        }
        .padding(.vertical, 2)
        .opacity(set.isCompleted ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Notes")
            GlassCard {
                Text(workout.notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func summaryStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.callout.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        if !workout.name.isEmpty { return workout.name }
        return workout.startedAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var durationText: String {
        let total = Int(workout.duration())
        let m = total / 60
        let s = total % 60
        if m >= 60 {
            return String(format: "%dh %02dm", m / 60, m % 60)
        }
        return String(format: "%d:%02d", m, s)
    }

    private var volumeText: String {
        let v = workout.totalVolume
        if v >= 1_000 {
            return String(format: "%.1fk lb", v / 1_000)
        }
        return "\(Int(v.rounded())) lb"
    }

    private func formatWeight(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.01 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", value)
    }

    private func formatRpe(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.01 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", value)
    }
}
