import SwiftUI
import SwiftData

/// Library tab root. Search bar + body-part chip filter + scrollable list
/// (sectioned by body part, or flat when filtering / searching).
struct LibraryView: View {

    @Binding var path: [LibraryRoute]

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var searchText: String = ""
    @State private var selectedBodyPart: String? = nil

    /// Opinionated display order — flows from upper to lower body so the
    /// chip row reads naturally rather than alphabetically.
    private static let bodyPartOrder = [
        "Chest", "Back", "Shoulders", "Arms",
        "Forearms", "Core", "Legs", "Glutes", "Calves"
    ]

    private var filtered: [Exercise] {
        var list = allExercises
        if let bp = selectedBodyPart {
            list = list.filter { $0.bodyPart == bp }
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let lower = trimmed.lowercased()
            list = list.filter { $0.name.lowercased().contains(lower) }
        }
        return list
    }

    /// Body parts present in the current data, ordered per `bodyPartOrder`,
    /// with any unknown values appended alphabetically.
    private var availableBodyParts: [String] {
        let present = Set(allExercises.map(\.bodyPart))
        let known = Self.bodyPartOrder.filter { present.contains($0) }
        let extras = present.subtracting(known).sorted()
        return known + extras
    }

    private var groupedFiltered: [(bodyPart: String, list: [Exercise])] {
        let present = Set(filtered.map(\.bodyPart))
        let order = Self.bodyPartOrder.filter { present.contains($0) }
            + Array(present.subtracting(Self.bodyPartOrder)).sorted()
        return order.map { bp in
            (bp, filtered.filter { $0.bodyPart == bp })
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Group {
            if allExercises.isEmpty {
                EmptyStateView(
                    symbol: "tray",
                    title: "No exercises seeded",
                    message: "The starter set should always be present. Reinstalling the app should fix this."
                )
            } else {
                content
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                chipRow
                if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No matches",
                        message: searchHelpMessage
                    )
                    .padding(.top, Theme.Spacing.xl)
                } else if selectedBodyPart != nil || isSearching {
                    flatList
                } else {
                    groupedList
                }
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Pieces

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                BodyPartChip(label: "All", isSelected: selectedBodyPart == nil) {
                    selectedBodyPart = nil
                }
                ForEach(availableBodyParts, id: \.self) { bp in
                    BodyPartChip(label: bp, isSelected: selectedBodyPart == bp) {
                        selectedBodyPart = (selectedBodyPart == bp) ? nil : bp
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
        }
    }

    private var flatList: some View {
        VStack(spacing: Theme.Spacing.sm) {
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise)
                        if index < filtered.count - 1 {
                            Divider().padding(.leading, Theme.Spacing.md)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var groupedList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ForEach(groupedFiltered, id: \.bodyPart) { entry in
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    SectionHeader(entry.bodyPart, caption: "\(entry.list.count) exercises")
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(entry.list.enumerated()), id: \.element.id) { index, exercise in
                                exerciseRow(exercise)
                                if index < entry.list.count - 1 {
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
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            Haptics.selection()
            path.append(.exerciseDetail(exercise.persistentModelID))
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .foregroundStyle(.primary)
                    Text(exercise.equipment)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm + 4)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(exercise.name), \(exercise.equipment)")
        }
        .buttonStyle(.plain)
    }

    private var searchHelpMessage: String {
        if isSearching, let bp = selectedBodyPart {
            return "Nothing matched \"\(searchText)\" in \(bp). Try a different term or tap “All”."
        }
        if isSearching {
            return "Nothing matched \"\(searchText)\". Try a different term."
        }
        if let bp = selectedBodyPart {
            return "No \(bp) exercises in the library yet."
        }
        return "Try a different filter."
    }
}
