import SwiftUI
import SwiftData

/// The logging screen. Displayed when there's an active (unfinished)
/// workout. All writes flow through `WorkoutSessionStore`; the rest
/// timer is shared via `RestTimer` in the environment.
///
/// Navigating back to the tab without tapping "Finish" leaves the
/// workout in progress — it will still be active on next launch.
struct ActiveWorkoutView: View {

    @Environment(WorkoutSessionStore.self) private var session
    @Environment(RestTimer.self) private var restTimer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingPicker = false
    @State private var showingFinish = false

    var body: some View {
        Group {
            if let workout = session.active {
                content(for: workout)
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func content(for workout: Workout) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(workout.orderedExercises) { workoutExercise in
                    WorkoutExerciseSection(
                        workoutExercise: workoutExercise,
                        onToggleSet: { handleToggle(set: $0, in: workoutExercise) },
                        onAddSet: { session.addEmptySet(to: workoutExercise) },
                        onDeleteSet: { session.deleteSet($0, from: workoutExercise) },
                        onChangeRest: { session.updateRestSeconds(workoutExercise, to: $0) },
                        onRemove: { session.removeExercise(workoutExercise) }
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)

                addExerciseButton
                    .padding(.horizontal, Theme.Spacing.md)

                if workout.exercises.isEmpty {
                    EmptyStateView(
                        symbol: "dumbbell",
                        title: "No exercises yet",
                        message: "Tap “Add Exercise” to start logging.",
                        cta: .init(title: "Add Exercise", systemImage: "plus") {
                            showingPicker = true
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                    VStack(spacing: 0) {
                        Text(workout.name.isEmpty ? "Workout" : workout.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(durationString(workout.duration(asOf: context.date)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    showingFinish = true
                }
                .fontWeight(.semibold)
                .disabled(workout.totalCompletedSets == 0)
            }
        }
        .safeAreaInset(edge: .bottom) {
            RestTimerOverlay()
                .animation(.spring(duration: 0.3), value: restTimer.isActive)
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerSheet { exercise in
                session.addExercise(exercise)
            }
        }
        .sheet(isPresented: $showingFinish) {
            FinishWorkoutSheet(
                workout: workout,
                onSave: { saveWorkout(workout) },
                onDiscard: { discardWorkout() }
            )
        }
        .onDisappear { session.flush() }
    }

    private var addExerciseButton: some View {
        GlassButton("Add Exercise", systemImage: "plus", style: .secondary) {
            showingPicker = true
        }
    }

    // MARK: - Actions

    private func handleToggle(set: ExerciseSet, in workoutExercise: WorkoutExercise) {
        let willBeCompleted = !set.isCompleted
        session.setCompleted(set, to: willBeCompleted)
        if willBeCompleted {
            Haptics.success()
            if workoutExercise.restSeconds > 0 {
                restTimer.start(duration: workoutExercise.restSeconds)
            }
        }
    }

    private func saveWorkout(_ workout: Workout) {
        PRDetectionService.detectPRs(for: workout, in: modelContext)
        _ = session.finish()
        restTimer.skip()
        dismiss()
    }

    private func discardWorkout() {
        session.discard()
        restTimer.skip()
        dismiss()
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
