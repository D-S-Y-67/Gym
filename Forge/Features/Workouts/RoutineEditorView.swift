import SwiftUI
import SwiftData

/// Edit a routine's name, exercises, and per-exercise targets.
/// "Start Workout" at the bottom kicks off a session pre-populated
/// from this routine and resets the navigation path to land on
/// `ActiveWorkoutView`.
///
/// On disappear, an empty unnamed routine with no exercises is
/// auto-deleted so canceled "New Routine" attempts don't leave junk.
struct RoutineEditorView: View {

    @Bindable var routine: Routine
    @Binding var path: [WorkoutsRoute]

    @Environment(WorkoutSessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                nameCard
                exercisesCard
                addExerciseButton
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            startBar
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerSheet { exercise in
                addExercise(exercise)
            }
        }
        .onDisappear { cleanupIfEmpty() }
    }

    // MARK: - Sections

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Name")
            GlassCard {
                TextField("Routine name", text: $routine.name)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Exercises", caption: routine.exercises.isEmpty ? "Add at least one to start a workout from this routine" : nil)
            if routine.exercises.isEmpty {
                GlassCard {
                    Text("No exercises yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, Theme.Spacing.md)
            } else {
                GlassCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(routine.orderedExercises) { item in
                            RoutineExerciseRow(item: item) {
                                deleteExercise(item)
                            }
                            if item.id != routine.orderedExercises.last?.id {
                                Divider().padding(.leading, Theme.Spacing.md)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    private var addExerciseButton: some View {
        GlassButton("Add Exercise", systemImage: "plus", style: .secondary) {
            showingPicker = true
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var startBar: some View {
        VStack(spacing: 0) {
            Divider()
            GlassButton("Start Workout", systemImage: "play.fill", style: .primary) {
                startWorkout()
            }
            .disabled(routine.exercises.isEmpty || session.active != nil)
            .padding(Theme.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func addExercise(_ exercise: Exercise) {
        let item = RoutineExercise(
            exerciseIndex: routine.exercises.count,
            targetSets: 3,
            targetReps: nil,
            exercise: exercise
        )
        item.parentRoutine = routine
        modelContext.insert(item)
        routine.exercises.append(item)
        try? modelContext.save()
    }

    private func deleteExercise(_ item: RoutineExercise) {
        Haptics.warning()
        routine.exercises.removeAll { $0.id == item.id }
        modelContext.delete(item)
        for (idx, ex) in routine.orderedExercises.enumerated() {
            ex.exerciseIndex = idx
        }
        try? modelContext.save()
    }

    private func startWorkout() {
        guard !routine.exercises.isEmpty, session.active == nil else { return }
        Haptics.success()
        try? modelContext.save()
        session.start(from: routine)
        path = [.active]
    }

    private func cleanupIfEmpty() {
        if routine.name.trimmingCharacters(in: .whitespaces).isEmpty,
           routine.exercises.isEmpty {
            modelContext.delete(routine)
            try? modelContext.save()
        }
    }
}

// MARK: - Row

private struct RoutineExerciseRow: View {
    @Bindable var item: RoutineExercise
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.exercise?.name ?? "—")
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(item.exercise?.bodyPart ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            targetsControls
            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Routine exercise options")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private var targetsControls: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text("\(item.targetSets) × \(item.targetReps.map { String($0) } ?? "—")")
                .font(.footnote.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 56, alignment: .trailing)
                .accessibilityLabel("\(item.targetSets) sets, target reps \(item.targetReps.map { "\($0)" } ?? "unset")")
            Stepper("Target sets", value: $item.targetSets, in: 1...10)
                .labelsHidden()
                .accessibilityLabel("Target sets")
        }
    }
}
