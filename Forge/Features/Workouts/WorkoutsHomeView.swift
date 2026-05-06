import SwiftUI
import SwiftData

/// Home tab root (renamed from Workouts in PR 11).
///
/// Sections (top to bottom):
///   1. **Hero block** — full-bleed gradient with day numeral, scheduled
///      routine, gradient CTA, stats row.
///   2. **Routines** — up to 3 saved routines.
///   3. **Body** — heat-mapped figure preview, taps into BodyView.
///   4. **Library** — horizontal carousel of body-part cards. Surfaces
///      what was previously a top-level tab. Taps push LibraryView with
///      that body part pre-filtered.
///   5. **Activity** — most recent finished workout.
///
/// Plus a **floating circular Coach button** at bottom-trailing — a one-tap
/// shortcut to the workout-aware AI, presented as a sheet so the user
/// returns to Home with a swipe down.
struct WorkoutsHomeView: View {

    @Binding var path: [WorkoutsRoute]

    @Environment(WorkoutSessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    @State private var showingCoach = false

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

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
            VStack(spacing: 0) {
                heroBlock
                VStack(spacing: Theme.Spacing.lg) {
                    routinesSection
                    bodySection
                    librarySection
                    activitySection
                }
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.lg)
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottomTrailing) {
            floatingCoachButton
        }
        .sheet(isPresented: $showingCoach) {
            NavigationStack {
                CoachView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { showingCoach = false }
                        }
                    }
            }
        }
    }

    // MARK: - Floating Coach button

    private var floatingCoachButton: some View {
        Button {
            Haptics.tap()
            showingCoach = true
        } label: {
            Image(systemName: "sparkles")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(Theme.Palette.accentGradient(.accentColor))
                )
                .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
        }
        .accessibilityLabel("Ask Coach")
        .padding(.trailing, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
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

    // MARK: - Hero block (full-bleed)

    /// PR 9: the home tab opens with a full-width colored region instead
    /// of a card sitting in a stack. ForgeWordmark + huge day numeral +
    /// scheduled-routine info + gradient CTA + stats row, all on the
    /// accent gradient. The page below sits visually beneath this hero
    /// rather than co-equal with it.
    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            heroTopRow
            heroDayBlock
            heroBody
                .padding(.top, Theme.Spacing.xs)
            heroCTA
            heroDivider
            heroStatsRow
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xxl + Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Palette.heroGradient(.accentColor)
        )
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Theme.Radius.lg + 6,
                bottomTrailingRadius: Theme.Radius.lg + 6,
                style: .continuous
            )
        )
    }

    private var heroTopRow: some View {
        HStack(alignment: .center) {
            ForgeWordmark(size: 16)
                .foregroundStyle(.white)
            Spacer()
            if !weekPRs.isEmpty {
                heroPRPill
            }
        }
    }

    private var heroPRPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.caption2)
            Text("+\(weekPRs.count) THIS WEEK")
                .font(.caption2.weight(.heavy))
                .tracking(0.8)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 5)
        .foregroundStyle(.white)
        .background(.white.opacity(0.18), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
        .accessibilityLabel("\(weekPRs.count) personal record\(weekPRs.count == 1 ? "" : "s") this week")
    }

    private var heroDayBlock: some View {
        VStack(alignment: .leading, spacing: -4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide)).uppercased())
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Theme.Typo.heroNumeral(Date.now.formatted(.dateTime.day()))
                VStack(alignment: .leading, spacing: 0) {
                    Text(Date.now.formatted(.dateTime.month(.wide)).uppercased())
                        .font(.subheadline.weight(.heavy))
                        .tracking(1.5)
                    Text(Date.now.formatted(.dateTime.year()))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                }
                .padding(.bottom, 12)
                Spacer()
            }
        }
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.22))
            .frame(height: 1)
    }

    @ViewBuilder
    private var heroBody: some View {
        switch heroState {
        case .active(let workout):
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name.isEmpty ? "Workout in progress" : workout.name)
                    .font(.title2.weight(.bold))
                TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                    Text("\(durationString(workout.duration(asOf: context.date))) · \(workout.totalCompletedSets) sets logged")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
        case .scheduled(let routine):
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                    .font(.title2.weight(.bold))
                Text(scheduledSubtitle(for: routine))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }
        case .unscheduled:
            VStack(alignment: .leading, spacing: 4) {
                Text("No workout planned")
                    .font(.title2.weight(.bold))
                Text(hasAnySchedule
                    ? "Today's a rest day — or freestyle below."
                    : "Plan your week to get a heads-up each morning.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
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
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 2)
                    }
                    .accessibilityLabel("Plan your week")
                } else {
                    Button {
                        Haptics.tap()
                        path.append(.weeklySchedule)
                    } label: {
                        Text("View week →")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 2)
                    }
                }
            }
        }
    }

    /// On the colored hero, accent-on-accent disappears. Inverse the
    /// button: white pill with accent text. Lifts cleanly off the gradient.
    private func gradientButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var heroStatsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            heroStatColumn(
                value: "\(monthlyWorkouts.count)",
                label: "30-DAY"
            )
            heroStatDivider
            heroStatColumn(
                value: formatVolume(monthlyWorkouts.reduce(0) { $0 + $1.totalVolume }),
                label: "VOLUME"
            )
            heroStatDivider
            heroStatColumn(
                value: "\(weekPRs.count)",
                label: "WEEK PR"
            )
        }
    }

    private func heroStatColumn(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Theme.Typo.displayNumeral(value, size: 28)
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

    // MARK: - Body preview

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Body", caption: "Heat-mapped from your last 7 days") {
                Button("Open") {
                    Haptics.tap()
                    path.append(.body)
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityLabel("Open body view")
            }
            BodyPreviewCard {
                path.append(.body)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Library carousel (PR 11)

    /// Body-parts present in the seeded library, ordered upper-to-lower
    /// for natural left-to-right reading.
    private static let libraryOrder = [
        "Chest", "Back", "Shoulders", "Arms",
        "Forearms", "Core", "Legs", "Glutes", "Calves"
    ]

    private var libraryGroups: [(bodyPart: String, count: Int)] {
        let counts = Dictionary(grouping: allExercises, by: { $0.bodyPart })
            .mapValues { $0.count }
        let known = Self.libraryOrder.compactMap { name -> (String, Int)? in
            guard let count = counts[name], count > 0 else { return nil }
            return (name, count)
        }
        let extras = counts.keys
            .filter { !Self.libraryOrder.contains($0) && (counts[$0] ?? 0) > 0 }
            .sorted()
            .map { ($0, counts[$0] ?? 0) }
        return known + extras
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Library", caption: "Browse exercises by body part") {
                Button("All") {
                    Haptics.tap()
                    path.append(.library)
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityLabel("Open full library")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(libraryGroups.enumerated()), id: \.element.bodyPart) { _, group in
                        LibraryBodyPartCard(
                            bodyPart: group.bodyPart,
                            exerciseCount: group.count
                        ) {
                            Haptics.selection()
                            path.append(.library)
                        }
                    }
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
                    VStack(spacing: Theme.Spacing.md) {
                        ForgeMark(size: 36)
                            .foregroundStyle(.tertiary)
                        VStack(spacing: 4) {
                            Text("No workouts yet")
                                .font(.headline)
                            Text("Your first session goes here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
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

// MARK: - Library body-part card (carousel item)

/// Compact card used in the Home Library carousel. Shows the body-part
/// name with a stylized accent block and the exercise count. The whole
/// card is tappable.
private struct LibraryBodyPartCard: View {
    let bodyPart: String
    let exerciseCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.Palette.accentGradient(.accentColor))
                    Image(systemName: symbolName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bodyPart)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(exerciseCount)")
                        .font(.caption.monospacedDigit().weight(.heavy))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(width: 124, alignment: .leading)
            .appGlassBackground(cornerRadius: Theme.Radius.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(bodyPart), \(exerciseCount) exercises")
    }

    private var symbolName: String {
        switch bodyPart.lowercased() {
        case "chest":      return "figure.strengthtraining.traditional"
        case "back":       return "figure.rower"
        case "shoulders":  return "figure.boxing"
        case "arms":       return "dumbbell.fill"
        case "forearms":   return "hand.raised.fill"
        case "core":       return "figure.core.training"
        case "legs":       return "figure.run"
        case "glutes":     return "figure.walk"
        case "calves":     return "figure.step.training"
        default:           return "figure"
        }
    }
}
