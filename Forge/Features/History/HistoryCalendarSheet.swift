import SwiftUI

/// Month-paging calendar showing dotted days where workouts were logged.
/// Read-only in PR 2 — tap a day jumps the user back to the History list
/// with no scroll behavior yet (added when we ship list anchoring).
struct HistoryCalendarSheet: View {

    let workouts: [Workout]
    @Environment(\.dismiss) private var dismiss
    @State private var anchor: Date = .now

    private let calendar = Calendar.current

    private var workoutDates: Set<DateComponents> {
        Set(workouts.map { calendar.dateComponents([.year, .month, .day], from: $0.startedAt) })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                monthHeader
                weekdayRow
                daysGrid
                Spacer()
                legend
            }
            .padding(Theme.Spacing.md)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            Button {
                Haptics.selection()
                anchor = calendar.date(byAdding: .month, value: -1, to: anchor) ?? anchor
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous month")

            Spacer()
            Text(anchor.formatted(.dateTime.year().month(.wide)))
                .font(.title3.weight(.semibold))
                .accessibilityLabel(anchor.formatted(.dateTime.year().month(.wide)))
            Spacer()

            Button {
                Haptics.selection()
                anchor = calendar.date(byAdding: .month, value: 1, to: anchor) ?? anchor
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
        }
    }

    private var weekdayRow: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private struct DayCell: Identifiable {
        let id = UUID()
        let date: Date?
        let inCurrentMonth: Bool
        let hasWorkout: Bool
    }

    private var daysGrid: some View {
        let cells = computeCells()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(cells) { cell in
                dayView(for: cell)
            }
        }
    }

    @ViewBuilder
    private func dayView(for cell: DayCell) -> some View {
        if let date = cell.date {
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.day()))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(cell.inCurrentMonth ? .primary : Color.secondary.opacity(0.5))
                Circle()
                    .fill(cell.hasWorkout ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel(for: date, hasWorkout: cell.hasWorkout))
        } else {
            Color.clear.frame(minHeight: 40)
        }
    }

    private func accessibilityLabel(for date: Date, hasWorkout: Bool) -> String {
        let dateString = date.formatted(.dateTime.year().month().day())
        return hasWorkout ? "\(dateString), workout logged" : dateString
    }

    private func computeCells() -> [DayCell] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: anchor),
              let monthStart = calendar.dateComponents([.year, .month], from: monthInterval.start) as DateComponents?,
              let firstDay = calendar.date(from: monthStart),
              let monthRange = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let firstWeekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7

        var cells: [DayCell] = []

        for _ in 0..<firstWeekdayOffset {
            cells.append(DayCell(date: nil, inCurrentMonth: false, hasWorkout: false))
        }

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                let comps = calendar.dateComponents([.year, .month, .day], from: date)
                let hasWorkout = workoutDates.contains(comps)
                cells.append(DayCell(date: date, inCurrentMonth: true, hasWorkout: hasWorkout))
            }
        }

        // Pad to a multiple of 7 for grid alignment.
        while cells.count % 7 != 0 {
            cells.append(DayCell(date: nil, inCurrentMonth: false, hasWorkout: false))
        }

        return cells
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
            Text("Workout day")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Theme.Spacing.sm)
    }
}
