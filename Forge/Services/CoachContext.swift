import Foundation
import SwiftData

/// Builds a markdown-flavored summary of the user's recent training, PRs,
/// and weekly schedule. Injected into the Coach system prompt on every
/// message so the model always sees current state.
///
/// Cap each section so a heavy user doesn't blow past the model's
/// context window. The Coach is supposed to recognize patterns, not
/// recite every set ever.
@MainActor
enum CoachContext {

    /// Days to look back for recent-workout context.
    private static let workoutWindowDays = 14
    /// Days to look back for recent PR context.
    private static let prWindowDays = 30
    /// Hard caps so the prompt stays bounded.
    private static let maxRecentWorkouts = 10
    private static let maxRecentPRs = 10
    private static let maxRoutines = 8

    /// Returns a multi-section markdown string ready to append to the
    /// Coach system prompt. Empty sections are omitted.
    static func build(modelContext: ModelContext) -> String {
        let workouts = fetchRecentWorkouts(modelContext)
        let prs = fetchRecentPRs(modelContext)
        let routines = fetchRoutines(modelContext)

        var sections: [String] = []
        sections.append(todayHeader(routines: routines))
        sections.append(weeklyScheduleSection(routines: routines))
        if !workouts.isEmpty {
            sections.append(recentWorkoutsSection(workouts))
        }
        if !prs.isEmpty {
            sections.append(recentPRsSection(prs))
        }
        if !routines.isEmpty {
            sections.append(routinesSection(routines))
        }

        if workouts.isEmpty && prs.isEmpty && routines.allSatisfy({ $0.scheduledDays.isEmpty }) {
            return [
                "## User context",
                "No logged workouts, no PRs detected, and no scheduled routines yet. Encourage the user to log a session and assign a routine to a weekday — once data exists, you'll have specifics to coach on."
            ].joined(separator: "\n")
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Sections

    private static func todayHeader(routines: [Routine]) -> String {
        let now = Date.now
        let weekday = Calendar.current.component(.weekday, from: now)
        let dateStr = now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
        let scheduledToday = routines.filter { $0.isScheduled(on: weekday) }.map { $0.name.isEmpty ? "Untitled" : $0.name }
        let line: String
        if scheduledToday.isEmpty {
            line = "\(dateStr) — no routine scheduled (rest day)"
        } else {
            line = "\(dateStr) — scheduled: \(scheduledToday.joined(separator: ", "))"
        }
        return "## Today\n\(line)"
    }

    private static func weeklyScheduleSection(routines: [Routine]) -> String {
        let calendar = Calendar.current
        let dayNames = calendar.standaloneWeekdaySymbols
        let firstDay = calendar.firstWeekday
        let ordered = (0..<7).map { ((firstDay - 1 + $0) % 7) + 1 }

        let lines = ordered.map { day -> String in
            let assigned = routines
                .filter { $0.isScheduled(on: day) }
                .map { $0.name.isEmpty ? "Untitled" : $0.name }
            let label = dayNames[(day - 1) % 7]
            if assigned.isEmpty {
                return "- \(label): Rest"
            }
            return "- \(label): \(assigned.joined(separator: ", "))"
        }
        return "## Weekly schedule\n" + lines.joined(separator: "\n")
    }

    private static func recentWorkoutsSection(_ workouts: [Workout]) -> String {
        let lines = workouts.prefix(maxRecentWorkouts).map { workout -> String in
            let date = workout.startedAt.formatted(.dateTime.year().month(.twoDigits).day().weekday(.abbreviated))
            let durMin = Int(workout.duration() / 60)
            let sets = workout.totalCompletedSets
            let volume = Int(workout.totalVolume.rounded())
            let name = workout.name.isEmpty ? "Workout" : workout.name
            let exercises = workout.orderedExercises
                .compactMap { $0.exercise?.name }
                .prefix(4)
                .joined(separator: ", ")
            let exerciseHint = exercises.isEmpty ? "" : " · \(exercises)"
            return "- \(date) — \(name) · \(durMin)m · \(sets) sets · \(volume) lb\(exerciseHint)"
        }
        return "## Recent workouts (last \(workoutWindowDays) days)\n" + lines.joined(separator: "\n")
    }

    private static func recentPRsSection(_ prs: [PersonalRecord]) -> String {
        let lines = prs.prefix(maxRecentPRs).map { pr -> String in
            let date = pr.achievedAt.formatted(.dateTime.year().month(.twoDigits).day())
            let name = pr.exercise?.name ?? "Unknown exercise"
            let value = String(format: "%.0f", pr.value)
            return "- \(name): \(value) lb e1RM (\(date))"
        }
        return "## Recent PRs (last \(prWindowDays) days)\n" + lines.joined(separator: "\n")
    }

    private static func routinesSection(_ routines: [Routine]) -> String {
        let calendar = Calendar.current
        let shortNames = calendar.shortStandaloneWeekdaySymbols
        let lines = routines.prefix(maxRoutines).map { routine -> String in
            let name = routine.name.isEmpty ? "Untitled" : routine.name
            let count = routine.exercises.count
            let days = routine.scheduledDays
                .sorted()
                .map { shortNames[($0 - 1) % 7] }
                .joined(separator: ", ")
            let scheduleHint = days.isEmpty ? "unscheduled" : "scheduled \(days)"
            return "- \(name) (\(count) exercise\(count == 1 ? "" : "s")) · \(scheduleHint)"
        }
        return "## Routines\n" + lines.joined(separator: "\n")
    }

    // MARK: - Fetches

    private static func fetchRecentWorkouts(_ context: ModelContext) -> [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -workoutWindowDays, to: .now) ?? .now
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil && $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func fetchRecentPRs(_ context: ModelContext) -> [PersonalRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -prWindowDays, to: .now) ?? .now
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.achievedAt >= cutoff },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func fetchRoutines(_ context: ModelContext) -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
