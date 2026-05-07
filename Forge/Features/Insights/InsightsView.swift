import SwiftUI
import SwiftData
import Charts

/// Workouts → "Insights" sub-screen. Charts the user's training over time.
/// Hero language matches PR 9 (full-bleed Ember gradient, big numeral, eyebrow
/// caps), then two charts and a body-part distribution table beneath.
///
/// Reuses `MuscleVolumeMap` from `BodyView.swift` for the body-part section.
/// Pushed via `WorkoutsRoute.insights` from the tappable hero stats row on Home.
struct InsightsView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var window: TimeWindow = .twelveWeeks

    enum TimeWindow: String, CaseIterable, Identifiable {
        case fourWeeks, twelveWeeks
        var id: String { rawValue }
        var label: String { self == .fourWeeks ? "4 weeks" : "12 weeks" }
        var weeks: Int { self == .fourWeeks ? 4 : 12 }
    }

    private var fetchedWorkouts: [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -91, to: .now) ?? .now
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil && $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var fetchedPRs: [PersonalRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -window.weeks * 7, to: .now) ?? .now
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.achievedAt >= cutoff },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock
                VStack(spacing: Theme.Spacing.lg) {
                    volumeCard
                    heatmapCard
                    bodyPartsCard
                }
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var weeksActive: Int {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .weekOfYear, value: -11, to: .now) ?? .now
        let recent = fetchedWorkouts.filter { $0.startedAt >= cutoff }
        let weekKeys = Set(recent.map { workoutWeekKey($0.startedAt) })
        return min(weekKeys.count, 12)
    }

    private func workoutWeekKey(_ date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(comps.yearForWeekOfYear ?? 0)-\(comps.weekOfYear ?? 0)"
    }

    private var sessionsInWindow: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -window.weeks * 7, to: .now) ?? .now
        return fetchedWorkouts.filter { $0.startedAt >= cutoff }.count
    }

    private var volumeInWindow: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -window.weeks * 7, to: .now) ?? .now
        return fetchedWorkouts
            .filter { $0.startedAt >= cutoff }
            .flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("INSIGHTS")
                .font(.caption.weight(.heavy))
                .tracking(2.4)
                .foregroundStyle(.white.opacity(0.85))

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Theme.Typo.heroNumeral("\(weeksActive)")
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 0) {
                    Text("/ 12")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.65))
                        .monospacedDigit()
                    Text("WEEKS ACTIVE")
                        .font(.caption.weight(.heavy))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 12)
                Spacer()
            }

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
                .padding(.vertical, Theme.Spacing.xs)

            HStack(alignment: .top, spacing: 0) {
                heroStat(value: "\(sessionsInWindow)", label: "SESSIONS")
                heroStatDivider
                heroStat(value: formatVolume(volumeInWindow), label: "VOLUME LB")
                heroStatDivider
                heroStat(value: "\(fetchedPRs.count)", label: "PRS")
            }

            Picker("Window", selection: $window) {
                ForEach(TimeWindow.allCases) { window in
                    Text(window.label).tag(window)
                }
            }
            .pickerStyle(.segmented)
            .colorScheme(.dark)
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xxl + Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.heroGradient(.accentColor))
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Theme.Radius.lg + 6,
                bottomTrailingRadius: Theme.Radius.lg + 6,
                style: .continuous
            )
        )
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Theme.Typo.displayNumeral(value, size: 26)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var heroStatDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.22))
            .frame(width: 1, height: 36)
    }

    // MARK: - Volume per week

    private struct WeeklyEntry: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volume: Double
    }

    private var weeklyVolume: [WeeklyEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weeks = window.weeks
        return (0..<weeks).reversed().map { offset in
            let weekStart = cal.date(byAdding: .day, value: -7 * offset - 6, to: today) ?? today
            let weekEnd = cal.date(byAdding: .day, value: -7 * offset + 1, to: today) ?? today
            let volume = fetchedWorkouts
                .filter { $0.startedAt >= weekStart && $0.startedAt < weekEnd }
                .flatMap { $0.exercises }
                .flatMap { $0.sets }
                .filter { $0.isCompleted }
                .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            return WeeklyEntry(weekStart: weekStart, volume: volume)
        }
    }

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Theme.Typo.eyebrow("Volume per week")
                .padding(.horizontal, Theme.Spacing.md)
            GlassCard {
                Chart {
                    ForEach(weeklyVolume) { entry in
                        BarMark(
                            x: .value("Week", entry.weekStart, unit: .weekOfYear),
                            y: .value("Volume", entry.volume)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: max(1, window.weeks / 4))) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary.opacity(0.18))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary.opacity(0.18))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatVolume(v))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Workout heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Theme.Typo.eyebrow("Workout map · last 13 weeks")
                .padding(.horizontal, Theme.Spacing.md)
            GlassCard {
                WorkoutHeatmap(workouts: fetchedWorkouts)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Body parts

    private var bodyVolumeMap: MuscleVolumeMap {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let recent = fetchedWorkouts.filter { $0.startedAt >= cutoff }
        return MuscleVolumeMap(workouts: recent)
    }

    private var bodyPartsCard: some View {
        let visible = MuscleRegion.allCases
            .sorted { bodyVolumeMap.volume($0) > bodyVolumeMap.volume($1) }

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Theme.Typo.eyebrow("Body parts · last 30 days")
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, region in
                        regionRow(region: region)
                        if index < visible.count - 1 {
                            Divider().padding(.leading, Theme.Spacing.md)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func regionRow(region: MuscleRegion) -> some View {
        let volume = bodyVolumeMap.volume(region)
        let intensity = bodyVolumeMap.intensity(region)
        return HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Color.accentColor.opacity(0.15 + 0.85 * intensity))
                .frame(width: 12, height: 12)
            Text(region.displayName)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            if volume > 0 {
                Text(formatVolume(volume))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                Text("lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .frame(minHeight: 40)
    }

    // MARK: - Formatting

    private func formatVolume(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Heatmap

/// 13-week × 7-day GitHub-style activity grid. Each cell tints by the day's
/// completed-set volume, faint accent for zero up to full Ember at the
/// max-volume day. Cells are 14×14 with 3pt gaps — fits iPhone SE width.
private struct WorkoutHeatmap: View {

    let workouts: [Workout]

    private var cellsByDay: [Date: Double] {
        let cal = Calendar.current
        var out: [Date: Double] = [:]
        for workout in workouts {
            let day = cal.startOfDay(for: workout.startedAt)
            let volume = workout.exercises
                .flatMap { $0.sets }
                .filter { $0.isCompleted }
                .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            out[day, default: 0] += volume
        }
        return out
    }

    private var maxVolume: Double {
        cellsByDay.values.max() ?? 0
    }

    private var dates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<91).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
    }

    var body: some View {
        let rowSpec = Array(repeating: GridItem(.fixed(16), spacing: 3), count: 7)
        LazyHGrid(rows: rowSpec, spacing: 3) {
            ForEach(dates, id: \.self) { date in
                cell(for: date)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cell(for date: Date) -> some View {
        let key = Calendar.current.startOfDay(for: date)
        let volume = cellsByDay[key] ?? 0
        let intensity = maxVolume > 0 ? volume / maxVolume : 0
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.accentColor.opacity(0.12 + 0.88 * intensity))
            .frame(width: 16, height: 16)
            .accessibilityLabel("\(date.formatted(.dateTime.month().day())): \(Int(volume)) lb")
    }
}

#Preview {
    NavigationStack { InsightsView() }
}
