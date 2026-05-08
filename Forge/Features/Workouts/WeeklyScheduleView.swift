import SwiftUI
import SwiftData

/// 7-day grid showing which routines are scheduled per weekday. Days are
/// ordered by the user's locale `firstWeekday` so US users see Sun-first
/// and most others see Mon-first. Today's card is highlighted.
///
/// Tap a routine in any day card to jump into the routine editor (the
/// existing path), where the "Start Workout" button kicks off the session.
struct WeeklyScheduleView: View {

    @Binding var path: [WorkoutsRoute]

    @Query(sort: [SortDescriptor(\Routine.name)])
    private var routines: [Routine]

    private let calendar = Calendar.current

    /// Weekday indices (1…7) in the user's locale order. e.g. US: [1,2,3,4,5,6,7],
    /// most of EU: [2,3,4,5,6,7,1].
    private var orderedDays: [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { ((first - 1 + $0) % 7) + 1 }
    }

    private var today: Int {
        calendar.component(.weekday, from: .now)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if routines.allSatisfy({ $0.scheduledDays.isEmpty }) {
                    emptyHero
                }
                ForEach(orderedDays, id: \.self) { day in
                    DayCard(
                        weekday: day,
                        isToday: day == today,
                        date: dateForUpcoming(weekday: day),
                        routines: routinesScheduled(on: day),
                        onTap: { routine in
                            Haptics.selection()
                            path.append(.editRoutine(routine.persistentModelID))
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("Week")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty state

    private var emptyHero: some View {
        EmptyStateView(
            symbol: "calendar.badge.exclamationmark",
            title: "No scheduled routines yet",
            message: "Open any routine and tap a day chip in its Schedule section to plan your week.",
            cta: .init(title: "Manage routines", systemImage: "list.bullet.rectangle.portrait") {
                Haptics.tap()
                path.append(.routines)
            }
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Helpers

    private func routinesScheduled(on weekday: Int) -> [Routine] {
        routines.filter { $0.isScheduled(on: weekday) }
    }

    /// Date of the next occurrence of `weekday` (today if it matches).
    /// Used as a small subtitle on each card so users see "Tue · May 13".
    private func dateForUpcoming(weekday: Int) -> Date {
        let now = Date()
        let currentDay = calendar.component(.weekday, from: now)
        let delta = (weekday - currentDay + 7) % 7
        return calendar.date(byAdding: .day, value: delta, to: now) ?? now
    }
}

// MARK: - DayCard

private struct DayCard: View {
    let weekday: Int
    let isToday: Bool
    let date: Date
    let routines: [Routine]
    let onTap: (Routine) -> Void

    private var weekdayName: String {
        let symbols = Calendar.current.standaloneWeekdaySymbols
        return symbols[(weekday - 1) % 7]
    }

    private var dateLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        GlassCard(cornerRadius: Theme.Radius.lg, padding: 0) {
            HStack(alignment: .top, spacing: 0) {
                if isToday {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 4)
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    header
                    if routines.isEmpty {
                        Text("Rest")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, Theme.Spacing.xs)
                    } else {
                        VStack(spacing: Theme.Spacing.xs) {
                            ForEach(routines) { routine in
                                RoutineRow(routine: routine) { onTap(routine) }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayName)
                    .font(.title3.weight(.semibold))
                Text(dateLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isToday {
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - RoutineRow

private struct RoutineRow: View {
    let routine: Routine
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("\(routine.exercises.count) exercise\(routine.exercises.count == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(minHeight: 44)
            .background(Theme.Palette.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
