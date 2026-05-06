import SwiftUI
import SwiftData

/// Workouts tab root. PR 8 collapsed the previous five-section stack
/// (active banner, PR banner, Today, Routines, Recent) into:
///
///   1. **Hero card** — date eyebrow + scheduled-routine name + gradient
///      CTA + 3-stat row + optional PR pill. State machine over
///      `active / scheduled / unscheduled`.
///   2. **Routines** — up to 3 saved routines (existing behavior).
///   3. **Activity** — most recent finished workout (just one), with a
///      "View all" button that pushes the History list under Profile.
struct WorkoutsHomeView: View {

    @Binding var path: [WorkoutsRoute]

    @Environment(WorkoutSessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Workout> { $0.endedAt != nil },
        sort: [SortDescriptor(\Workout.startedAt, order: .reverse)]
    )
    private var finishedWorkouts: [Workout]

    @Query(
        sort: [
            SortDescriptor(\Routine.lastUsedAt, order: .reverse),
            SortDescriptor(\Routine.createdAt, order: .reverse)
        ]
    )
    private var routines: [Routine]

    @Query(sort: [SortDescriptor(\PersonalRecord.achievedAt, order: .reverse)])
    private var recentPRs: [PersonalRecord]

    private var weekPRs: [PersonalRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return recentPRs.filter { $0.achievedAt >= cutoff }
    }

    private var monthlyWorkouts: [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return finishedWorkouts.filter { $0.startedAt >= cutoff }
    }

    private var todayRoutines: [Routine] {
        routines.filter { $0.isScheduledToday }
    }

    private var hasAnySchedule: Bool {
        routines.contains { !$0.scheduledDays.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                heroCard
                routinesSection
                activitySection
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Hero state

    private enum HeroState {
        case active(Workout)
        case scheduled(Routine)
        case unscheduled
    }

    private var heroState: HeroState {
        if let active = session.active {
            return .active(active)
        }
        if let firstScheduled = todayRoutines.first {
            return .scheduled(firstScheduled)
        }
        return .unscheduled
    }

    // MARK: - Hero card

    private var heroCard: some View {
        GlassCard(cornerRadius: Theme.Radius.lg, padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                heroTopBar
                heroBody
                heroCTA
                Divider()
                heroStatsRow
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var heroTopBar: some View {
        HStack(alignment: .firstTextBaseline) {
            Theme.Typo.eyebrow(heroEyebrowText)
            Spacer()
            if !weekPRs.isEmpty {
                prPill
            }
        }
    }

    private var heroEyebrowText: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var prPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.caption2)
            Text("+\(weekPRs.count) THIS WEEK")
                .font(.caption2.weight(.bold))
                .tracking(0.6)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .foregroundStyle(.tint)
        .background(Color.accentColor.opacity(0.15), in: Capsule())
        .accessibilityLabel("\(weekPRs.count) personal record\(weekPRs.count == 1 ? "" : "s") this week")
    }

    @ViewBuilder
    private var heroBody: some View {
        switch heroState {
        case .active(let workout):
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name.isEmpty ? "Workout in progress" : workout.name)
                    .font(.title.weight(.bold))
                TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                    Text("\(durationString(workout.duration(asOf: context.date))) · \(workout.totalCompletedSets) sets logged")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        case .scheduled(let routine):
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                    .font(.title.weight(.bold))
                Text(scheduledSubtitle(for: routine))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .unscheduled:
            VStack(alignment: .leading, spacing: 4) {
                Text("No workout planned")
                    .font(.title.weight(.bold))
                Text(hasAnySchedule
                    ? "Today's a rest day — or freestyle below."
                    : "Plan your week to get a heads-up each morning.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func scheduledSubtitle(for routine: Routine) -> String {
        let count = routine.exercises.count
        let exercisesText = "\(count) exercise\(count == 1 ? "" : "s")"
        if let last = routine.lastUsedAt {
            return "\(exercisesText) · last \(last.formatted(.relative(presentation: .named)))"
        }
        return exercisesText
    }

    @ViewBuilder
    private var heroCTA: some View {
        switch heroState {
        case .active:
            gradientButton(title: "Resume Workout", icon: "play.fill") {
                Haptics.tap()
                if !path.contains(.active) { path.append(.active) }
            }
        case .scheduled(let routine):
            gradientButton(title: "Start Workout", icon: "play.fill") {
                startScheduled(routine)
            }
        case .unscheduled:
            VStack(spacing: Theme.Spacing.sm) {
                gradientButton(title: "Start Empty Workout", icon: "play.fill") {
                    handleStartEmpty()
                }
                if !hasAnySchedule {
                    Button {
                        Haptics.tap()
                        path.append(.weeklySchedule)
                    } label: {
                        Text("Plan your week →")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                    .accessibilityLabel("Plan your week")
                } else {
                    Button {
                        Haptics.tap()
                        path.append(.weeklySchedule)
                    } label: {
                        Text("View week →")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
    }

    private func gradientButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                Theme.Palette.accentGradient(.accentColor),
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var heroStatsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            statColumn(
                value: "\(monthlyWorkouts.count)",
                label: "30-DAY"
            )
            Divider().frame(height: 36)
            statColumn(
                value: formatVolume(monthlyWorkouts.reduce(0) { $0 + $1.totalVolume }),
                label: "VOLUME"
            )
            Divider().frame(height: 36)
            statColumn(
                value: "\(weekPRs.count)",
                label: "WEEK PR"
            )
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Theme.Typo.displayNumeral(value, size: 22)
                .foregroundStyle(.primary)
            Theme.Typo.eyebrow(label)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Routines section

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Routines", caption: routines.isEmpty ? nil : "Tap to edit or start") {
                HStack(spacing: Theme.Spacing.md) {
                    if hasAnySchedule {
                        Button("Week") {
                            Haptics.tap()
                            path.append(.weeklySchedule)
                        }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel("View week")
                    }
                    Button("Manage") {
                        Haptics.tap()
                        path.append(.routines)
                    }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("Manage routines")
                }
            }

            if routines.isEmpty {
                GlassCard {
                    Button {
                        createNewRoutine()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Create your first routine")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.tint)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.Spacing.md)
            } else {
                GlassCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(routines.prefix(3))) { routine in
                            Button {
                                Haptics.selection()
                                path.append(.editRoutine(routine.persistentModelID))
                            } label: {
                                HStack(spacing: Theme.Spacing.md) {
                                    Image(systemName: "list.bullet.rectangle.portrait")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                                            .foregroundStyle(.primary)
                                        Text("\(routine.exercises.count) exercises")
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
                            }
                            .buttonStyle(.plain)
                            if routine.id != routines.prefix(3).last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Activity section (last finished workout)

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Activity")
            if finishedWorkouts.isEmpty {
                GlassCard {
                    EmptyStateView(
                        symbol: "figure.run",
                        title: "No workouts yet",
                        message: "Your first session goes here."
                    )
                    .frame(minHeight: 140)
                }
                .padding(.horizontal, Theme.Spacing.md)
            } else if let last = finishedWorkouts.first {
                GlassCard(padding: 0) {
                    Button {
                        Haptics.selection()
                        path.append(.workoutDetail(last.persistentModelID))
                    } label: {
                        RecentWorkoutRow(workout: last)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Actions

    private func handleStartEmpty() {
        Haptics.tap()
        if session.active == nil {
            session.startEmpty()
        }
        if !path.contains(.active) { path.append(.active) }
    }

    private func startScheduled(_ routine: Routine) {
        guard !routine.exercises.isEmpty, session.active == nil else {
            // Routine has no exercises or a session is already active —
            // fall back to the editor so the user can resolve.
            path.append(.editRoutine(routine.persistentModelID))
            return
        }
        Haptics.success()
        session.start(from: routine)
        path = [.active]
    }

    private func createNewRoutine() {
        Haptics.tap()
        let routine = Routine(name: "")
        modelContext.insert(routine)
        try? modelContext.save()
        path.append(.editRoutine(routine.persistentModelID))
    }

    // MARK: - Formatting

    private func durationString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func formatVolume(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Recent row

private struct RecentWorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(spacing: 2) {
                Text(workout.startedAt.formatted(.dateTime.day()))
                    .font(.title3.weight(.semibold).monospacedDigit())
                Text(workout.startedAt.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name.isEmpty ? "Workout" : workout.name)
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
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let durMin = Int(workout.duration() / 60)
        let volume = Int(workout.totalVolume.rounded())
        let exCount = workout.exerciseCount
        return "\(durMin) min · \(exCount) exercises · \(volume) lb volume"
    }
}

private extension Workout {
    var exerciseCount: Int { exercises.count }
}
