import SwiftUI
import SwiftData

/// All saved routines, newest-used first. Tap a row to edit; swipe to
/// delete; tap "+" to create a new one.
struct RoutinesListView: View {

    @Binding var path: [WorkoutsRoute]
    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: [
            SortDescriptor(\Routine.lastUsedAt, order: .reverse),
            SortDescriptor(\Routine.createdAt, order: .reverse)
        ]
    )
    private var routines: [Routine]

    var body: some View {
        Group {
            if routines.isEmpty {
                EmptyStateView(
                    symbol: "list.bullet.rectangle.portrait",
                    title: "No routines yet",
                    message: "Pick a starter program or build your own.",
                    cta: .init(title: "Browse Starter Programs", systemImage: "square.grid.2x2.fill") {
                        Haptics.tap()
                        path.append(.programs)
                    }
                )
            } else {
                List {
                    ForEach(routines) { routine in
                        Button {
                            Haptics.selection()
                            path.append(.editRoutine(routine.persistentModelID))
                        } label: {
                            RoutineRow(routine: routine)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Routines")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createNew()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New routine")
            }
        }
    }

    // MARK: - Actions

    private func createNew() {
        Haptics.tap()
        let routine = Routine(name: "")
        modelContext.insert(routine)
        try? modelContext.save()
        path.append(.editRoutine(routine.persistentModelID))
    }

    private func delete(at offsets: IndexSet) {
        Haptics.warning()
        for index in offsets {
            modelContext.delete(routines[index])
        }
        try? modelContext.save()
    }
}

private struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), \(subtitle)")
    }

    private var displayName: String {
        routine.name.isEmpty ? "Untitled routine" : routine.name
    }

    private var subtitle: String {
        let count = routine.exercises.count
        let exercisesText = count == 1 ? "1 exercise" : "\(count) exercises"
        if let last = routine.lastUsedAt {
            return "\(exercisesText)  ·  Last used \(last.formatted(.relative(presentation: .numeric)))"
        }
        return exercisesText
    }
}
