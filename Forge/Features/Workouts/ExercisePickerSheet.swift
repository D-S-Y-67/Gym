import SwiftUI
import SwiftData

/// Modal sheet for adding an exercise to the active workout.
/// PR 2 uses the small seeded set, grouped by `bodyPart`. PR 3
/// expands to the full library with search and movement-pattern filters.
struct ExercisePickerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let onPick: (Exercise) -> Void

    private var grouped: [(bodyPart: String, list: [Exercise])] {
        Dictionary(grouping: exercises, by: \.bodyPart)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    EmptyStateView(
                        symbol: "tray",
                        title: "No exercises seeded",
                        message: "Reinstall the app or report this — the starter set should always be present."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.bodyPart) { entry in
                            Section(entry.bodyPart) {
                                ForEach(entry.list) { exercise in
                                    pickerRow(exercise)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func pickerRow(_ exercise: Exercise) -> some View {
        Button {
            Haptics.selection()
            onPick(exercise)
            dismiss()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.name)
                    .foregroundStyle(.primary)
                Spacer()
                Text(exercise.equipment)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.equipment)")
    }
}
