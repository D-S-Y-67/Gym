import SwiftUI
import SwiftData

/// History tab root. Strong-style list-first feed of finished workouts,
/// sectioned by month, newest first. Calendar accessible via toolbar.
struct HistoryListView: View {

    @Query(
        filter: #Predicate<Workout> { $0.endedAt != nil },
        sort: [SortDescriptor(\Workout.startedAt, order: .reverse)]
    )
    private var workouts: [Workout]

    @State private var showingCalendar = false

    private var monthGroups: [(label: String, key: String, workouts: [Workout])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: workouts) { workout -> String in
            let comps = calendar.dateComponents([.year, .month], from: workout.startedAt)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
        }
        return groups
            .map { key, list in
                let label: String
                if let first = list.first {
                    label = first.startedAt.formatted(.dateTime.year().month(.wide))
                } else {
                    label = key
                }
                return (label: label, key: key, workouts: list.sorted { $0.startedAt > $1.startedAt })
            }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        Group {
            if workouts.isEmpty {
                EmptyStateView(
                    symbol: "calendar",
                    title: "No history yet",
                    message: "Finished workouts show up here, sectioned by month."
                )
            } else {
                List {
                    ForEach(monthGroups, id: \.key) { group in
                        Section(group.label) {
                            ForEach(group.workouts) { workout in
                                NavigationLink(value: workout.persistentModelID) {
                                    HistoryRow(workout: workout)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showingCalendar = true
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Calendar view")
                .disabled(workouts.isEmpty)
            }
        }
        .sheet(isPresented: $showingCalendar) {
            HistoryCalendarSheet(workouts: workouts)
        }
    }
}

// MARK: - Row

private struct HistoryRow: View {
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
        HStack(spacing: Theme.Spacing.md) {
            VStack(spacing: 2) {
                Text(workout.startedAt.formatted(.dateTime.day()))
                    .font(.title3.weight(.semibold).monospacedDigit())
                Text(workout.startedAt.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(workout.name.isEmpty ? "Workout" : workout.name)
                        .foregroundStyle(.primary)
                    if !prs.isEmpty {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .accessibilityLabel("\(prs.count) personal record\(prs.count == 1 ? "" : "s")")
                    }
                }
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let durMin = Int(workout.duration() / 60)
        let volume = Int(workout.totalVolume.rounded())
        let exCount = workout.exercises.count
        let parts = [
            "\(durMin) min",
            "\(exCount) exercise\(exCount == 1 ? "" : "s")",
            "\(volume) lb"
        ]
        return parts.joined(separator: "  ·  ")
    }
}
