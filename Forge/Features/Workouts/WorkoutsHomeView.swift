import SwiftUI
import SwiftData

/// Workouts tab root. Surfaces the active session if one is in progress,
/// the user's saved routines, and recent workouts. Floating "Start Empty
/// Workout" CTA at the bottom (or "Resume" if there's an in-progress
/// session).
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

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if let active = session.active {
                    activeBanner(workout: active)
                }
                if !weekPRs.isEmpty {
                    prBanner
                }
                routinesSection
                recentSection
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            startBar
        }
    }

    // MARK: - Sections

    private func activeBanner(workout: Workout) -> some View {
        Button {
            Haptics.tap()
            if !path.contains(.active) { path.append(.active) }
        } label: {
            GlassCard(cornerRadius: Theme.Radius.lg) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "circle.dotted")
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active workout")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tint)
                            .textCase(.uppercase)
                        Text(workout.name.isEmpty ? "Workout in progress" : workout.name)
                            .font(.headline)
                        TimelineView(.periodic(from: workout.startedAt, by: 1)) { context in
                            Text("\(durationString(workout.duration(asOf: context.date)))  ·  \(workout.totalCompletedSets) sets")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityLabel("Resume active workout")
    }

    private var prBanner: some View {
        GlassCard(cornerRadius: Theme.Radius.lg) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weekPRs.count) personal record\(weekPRs.count == 1 ? "" : "s") this week")
                        .font(.headline)
                    Text(weekPRs.compactMap { $0.exercise?.name }.prefix(3).joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Routines", caption: routines.isEmpty ? nil : "Tap to edit or start") {
                Button("Manage") {
                    Haptics.tap()
                    path.append(.routines)
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityLabel("Manage routines")
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

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Recent")
            if finishedWorkouts.isEmpty {
                GlassCard {
                    EmptyStateView(
                        symbol: "calendar",
                        title: "No workouts yet",
                        message: "Tap “Start Empty Workout” to log your first session."
                    )
                    .frame(minHeight: 180)
                }
                .padding(.horizontal, Theme.Spacing.md)
            } else {
                GlassCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(finishedWorkouts.prefix(3))) { workout in
                            Button {
                                Haptics.selection()
                                path.append(.workoutDetail(workout.persistentModelID))
                            } label: {
                                RecentWorkoutRow(workout: workout)
                            }
                            .buttonStyle(.plain)
                            if workout.id != finishedWorkouts.prefix(3).last?.id {
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

    private var startBar: some View {
        VStack(spacing: 0) {
            Divider()
            GlassButton(
                session.active == nil ? "Start Empty Workout" : "Resume Workout",
                systemImage: "play.fill",
                style: .primary
            ) {
                handleStart()
            }
            .padding(Theme.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func handleStart() {
        if session.active == nil {
            session.startEmpty()
        }
        if !path.contains(.active) { path.append(.active) }
    }

    private func createNewRoutine() {
        Haptics.tap()
        let routine = Routine(name: "")
        modelContext.insert(routine)
        try? modelContext.save()
        path.append(.editRoutine(routine.persistentModelID))
    }

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
        return "\(durMin) min  ·  \(exCount) exercises  ·  \(volume) lb volume"
    }
}

private extension Workout {
    var exerciseCount: Int { exercises.count }
}
