import SwiftUI
import SwiftData

/// Read-only detail screen for a Library exercise. Shows the chips,
/// instructions, all-time PR (if any), and the user's last 5 completed
/// sets. When a workout is active, a sticky "Add to Workout" CTA at the
/// bottom inserts this exercise into the session and navigates to it.
struct ExerciseDetailView: View {

    let exercise: Exercise
    @Binding var workoutsPath: [WorkoutsRoute]
    @Binding var selectedTab: MainTabView.Tab

    @Environment(WorkoutSessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var prs: [PersonalRecord]
    @Query private var sets: [ExerciseSet]

    init(
        exercise: Exercise,
        workoutsPath: Binding<[WorkoutsRoute]>,
        selectedTab: Binding<MainTabView.Tab>
    ) {
        self.exercise = exercise
        self._workoutsPath = workoutsPath
        self._selectedTab = selectedTab
        let exerciseID = exercise.persistentModelID
        _prs = Query(
            filter: #Predicate<PersonalRecord> {
                $0.exercise?.persistentModelID == exerciseID
            },
            sort: [SortDescriptor(\PersonalRecord.value, order: .reverse)]
        )
        _sets = Query(
            filter: #Predicate<ExerciseSet> {
                $0.isCompleted == true
                && $0.parentExercise?.exercise?.persistentModelID == exerciseID
            },
            sort: [SortDescriptor(\ExerciseSet.completedAt, order: .reverse)]
        )
    }

    private var allTimePR: PersonalRecord? { prs.first }

    private var recentSets: [ExerciseSet] { Array(sets.prefix(5)) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerCard
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    instructionsCard(instructions)
                }
                if let pr = allTimePR {
                    prCard(pr)
                }
                if !recentSets.isEmpty {
                    recentSetsCard
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if session.active != nil {
                addToWorkoutBar
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        GlassCard(cornerRadius: Theme.Radius.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(exercise.name)
                    .font(.title2.weight(.semibold))
                HStack(spacing: Theme.Spacing.xs) {
                    pill(text: exercise.bodyPart, systemImage: "figure.strengthtraining.traditional")
                    pill(text: exercise.equipment, systemImage: "wrench.adjustable")
                    pill(text: capitalized(exercise.category), systemImage: "arrow.up.and.down")
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func instructionsCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("How to do it")
            GlassCard {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func prCard(_ pr: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Personal record")
            GlassCard {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Estimated 1RM  ·  \(formatWeight(pr.value)) lb")
                            .font(.headline.monospacedDigit())
                        Text("Set \(pr.achievedAt.formatted(.relative(presentation: .named)))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var recentSetsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Recent sets", caption: "Your last \(recentSets.count) completed")
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(recentSets.enumerated()), id: \.element.id) { index, set in
                        recentSetRow(set)
                        if index < recentSets.count - 1 {
                            Divider().padding(.leading, Theme.Spacing.md)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func recentSetRow(_ set: ExerciseSet) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(formatWeight(set.weight)) lb × \(set.reps)")
                    .font(.body.monospacedDigit())
                if let rpe = set.rpe {
                    Text("RPE \(formatRpe(rpe))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let completedAt = set.completedAt {
                Text(completedAt.formatted(.relative(presentation: .numeric)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private var addToWorkoutBar: some View {
        VStack(spacing: 0) {
            Divider()
            GlassButton("Add to Workout", systemImage: "plus", style: .primary) {
                handleAddToWorkout()
            }
            .padding(Theme.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func handleAddToWorkout() {
        guard session.active != nil else { return }
        Haptics.success()
        session.addExercise(exercise)
        // Switch to Workouts tab and reset path to the active workout.
        selectedTab = .workouts
        workoutsPath = [.active]
    }

    // MARK: - Helpers

    private func pill(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .foregroundStyle(.secondary)
        .background(
            Capsule().fill(Color(.tertiarySystemFill))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    private func capitalized(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.uppercased() + s.dropFirst()
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
