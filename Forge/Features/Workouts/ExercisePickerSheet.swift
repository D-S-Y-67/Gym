import SwiftUI
import SwiftData

/// Modal sheet for adding an exercise to the active workout.
///
/// PR 3 upgrades:
/// - Search bar at the top — case-insensitive substring match on name.
/// - "Recent" section above the body-part groups, listing the last 5
///   distinct exercises the user has logged in the last 30 days.
/// - When the user is actively searching, sections collapse to a flat list.
struct ExercisePickerSheet: View {

    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @Query(
        filter: #Predicate<ExerciseSet> { $0.isCompleted == true },
        sort: [SortDescriptor(\ExerciseSet.completedAt, order: .reverse)]
    )
    private var completedSets: [ExerciseSet]

    @State private var searchText: String = ""

    let onPick: (Exercise) -> Void

    private static let bodyPartOrder = [
        "Chest", "Back", "Shoulders", "Arms",
        "Forearms", "Core", "Legs", "Glutes", "Calves"
    ]

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var isSearching: Bool { !trimmedQuery.isEmpty }

    private var searchResults: [Exercise] {
        guard isSearching else { return [] }
        return exercises.filter { $0.name.lowercased().contains(trimmedQuery) }
    }

    private var recentExercises: [Exercise] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        var seen = Set<PersistentIdentifier>()
        var result: [Exercise] = []
        for set in completedSets {
            guard let when = set.completedAt, when >= cutoff,
                  let exercise = set.parentExercise?.exercise else { continue }
            let id = exercise.persistentModelID
            if seen.insert(id).inserted {
                result.append(exercise)
                if result.count >= 5 { break }
            }
        }
        return result
    }

    private var grouped: [(bodyPart: String, list: [Exercise])] {
        let dict = Dictionary(grouping: exercises, by: \.bodyPart)
        let present = Set(dict.keys)
        let order = Self.bodyPartOrder.filter { present.contains($0) }
            + Array(present.subtracting(Self.bodyPartOrder)).sorted()
        return order.map { bp in
            (bp, (dict[bp] ?? []).sorted { $0.name < $1.name })
        }
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
                    list
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        }
    }

    @ViewBuilder
    private var list: some View {
        if isSearching {
            if searchResults.isEmpty {
                EmptyStateView(
                    symbol: "magnifyingglass",
                    title: "No matches",
                    message: "Nothing matched \"\(searchText)\". Try a different term."
                )
            } else {
                List {
                    Section {
                        ForEach(searchResults) { exercise in
                            pickerRow(exercise)
                        }
                    } header: {
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                    }
                }
                .listStyle(.insetGrouped)
            }
        } else {
            List {
                if !recentExercises.isEmpty {
                    Section("Recent") {
                        ForEach(recentExercises) { exercise in
                            pickerRow(exercise)
                        }
                    }
                }
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
