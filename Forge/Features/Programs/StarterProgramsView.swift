import SwiftUI
import SwiftData

/// Bundled starter programs. PR 15 closes the empty-Routines cold-start:
/// new users see a curated catalog (PPL, Upper/Lower, Full-body 3x, 5x5)
/// and adopt a program with one tap, materializing real `Routine` rows
/// pre-scheduled to weekdays.
///
/// Catalog is static — exercise names must match the seeded `Exercise`
/// library exactly (case-insensitive). Verified at v1 against
/// `SeedData.swift`. New programs added here ship without a migration.

// MARK: - Model

struct StarterProgram: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let daysPerWeek: Int
    let routines: [Template]

    struct Template: Hashable {
        let name: String
        let scheduledDays: [Int]      // 1=Sun … 7=Sat
        let exercises: [Item]
    }

    struct Item: Hashable {
        let exerciseName: String
        let targetSets: Int
        let targetReps: Int?
    }
}

// MARK: - Catalog

extension StarterProgram {
    static let catalog: [StarterProgram] = [
        // 6-day Push / Pull / Legs
        StarterProgram(
            id: "ppl-6",
            name: "Push / Pull / Legs",
            tagline: "Six days. Classic split for size.",
            daysPerWeek: 6,
            routines: [
                Template(
                    name: "Push",
                    scheduledDays: [2, 5],   // Mon, Thu
                    exercises: [
                        .init(exerciseName: "Bench Press",            targetSets: 4, targetReps: 6),
                        .init(exerciseName: "Overhead Press",         targetSets: 4, targetReps: 8),
                        .init(exerciseName: "Incline Dumbbell Press", targetSets: 3, targetReps: 10),
                        .init(exerciseName: "Lateral Raise",          targetSets: 3, targetReps: 12),
                        .init(exerciseName: "Tricep Pushdown",        targetSets: 3, targetReps: 12),
                    ]
                ),
                Template(
                    name: "Pull",
                    scheduledDays: [3, 6],   // Tue, Fri
                    exercises: [
                        .init(exerciseName: "Conventional Deadlift", targetSets: 3, targetReps: 5),
                        .init(exerciseName: "Pull-Up",               targetSets: 4, targetReps: 8),
                        .init(exerciseName: "Barbell Row",           targetSets: 4, targetReps: 8),
                        .init(exerciseName: "Face Pull",             targetSets: 3, targetReps: 15),
                        .init(exerciseName: "Bicep Curl",            targetSets: 3, targetReps: 12),
                    ]
                ),
                Template(
                    name: "Legs",
                    scheduledDays: [4, 7],   // Wed, Sat
                    exercises: [
                        .init(exerciseName: "Back Squat",        targetSets: 4, targetReps: 6),
                        .init(exerciseName: "Romanian Deadlift", targetSets: 3, targetReps: 10),
                        .init(exerciseName: "Leg Press",         targetSets: 3, targetReps: 12),
                        .init(exerciseName: "Lying Leg Curl",    targetSets: 3, targetReps: 12),
                        .init(exerciseName: "Calf Raise",        targetSets: 4, targetReps: 15),
                    ]
                ),
            ]
        ),

        // 4-day Upper / Lower
        StarterProgram(
            id: "upper-lower-4",
            name: "Upper / Lower",
            tagline: "Four days. Strength and size, balanced.",
            daysPerWeek: 4,
            routines: [
                Template(
                    name: "Upper",
                    scheduledDays: [2, 5],   // Mon, Thu
                    exercises: [
                        .init(exerciseName: "Bench Press",     targetSets: 4, targetReps: 6),
                        .init(exerciseName: "Barbell Row",     targetSets: 4, targetReps: 8),
                        .init(exerciseName: "Overhead Press",  targetSets: 3, targetReps: 8),
                        .init(exerciseName: "Pull-Up",         targetSets: 3, targetReps: 8),
                        .init(exerciseName: "Bicep Curl",      targetSets: 3, targetReps: 12),
                        .init(exerciseName: "Tricep Pushdown", targetSets: 3, targetReps: 12),
                    ]
                ),
                Template(
                    name: "Lower",
                    scheduledDays: [3, 6],   // Tue, Fri
                    exercises: [
                        .init(exerciseName: "Back Squat",        targetSets: 4, targetReps: 6),
                        .init(exerciseName: "Romanian Deadlift", targetSets: 3, targetReps: 10),
                        .init(exerciseName: "Leg Press",         targetSets: 3, targetReps: 12),
                        .init(exerciseName: "Lying Leg Curl",    targetSets: 3, targetReps: 12),
                        .init(exerciseName: "Calf Raise",        targetSets: 4, targetReps: 15),
                    ]
                ),
            ]
        ),

        // 3-day Full-body (rotating A/B/C)
        StarterProgram(
            id: "full-3",
            name: "Full-Body 3x",
            tagline: "Three days. Hit everything, three times a week.",
            daysPerWeek: 3,
            routines: [
                Template(
                    name: "Full A",
                    scheduledDays: [2],   // Mon
                    exercises: [
                        .init(exerciseName: "Back Squat",  targetSets: 3, targetReps: 5),
                        .init(exerciseName: "Bench Press", targetSets: 3, targetReps: 5),
                        .init(exerciseName: "Barbell Row", targetSets: 3, targetReps: 8),
                        .init(exerciseName: "Pull-Up",     targetSets: 3, targetReps: 8),
                    ]
                ),
                Template(
                    name: "Full B",
                    scheduledDays: [4],   // Wed
                    exercises: [
                        .init(exerciseName: "Conventional Deadlift",  targetSets: 3, targetReps: 5),
                        .init(exerciseName: "Overhead Press",         targetSets: 3, targetReps: 8),
                        .init(exerciseName: "Incline Dumbbell Press", targetSets: 3, targetReps: 10),
                        .init(exerciseName: "Barbell Row",            targetSets: 3, targetReps: 8),
                    ]
                ),
                Template(
                    name: "Full C",
                    scheduledDays: [6],   // Fri
                    exercises: [
                        .init(exerciseName: "Back Squat",  targetSets: 3, targetReps: 5),
                        .init(exerciseName: "Bench Press", targetSets: 3, targetReps: 5),
                        .init(exerciseName: "Barbell Row", targetSets: 3, targetReps: 8),
                        .init(exerciseName: "Bicep Curl",  targetSets: 3, targetReps: 12),
                    ]
                ),
            ]
        ),

        // 5×5 alternating (Stronglifts-style)
        StarterProgram(
            id: "5x5",
            name: "5×5",
            tagline: "Three days. Linear progression on the basics.",
            daysPerWeek: 3,
            routines: [
                Template(
                    name: "Workout A",
                    scheduledDays: [2, 6],   // Mon, Fri
                    exercises: [
                        .init(exerciseName: "Back Squat",  targetSets: 5, targetReps: 5),
                        .init(exerciseName: "Bench Press", targetSets: 5, targetReps: 5),
                        .init(exerciseName: "Barbell Row", targetSets: 5, targetReps: 5),
                    ]
                ),
                Template(
                    name: "Workout B",
                    scheduledDays: [4],      // Wed
                    exercises: [
                        .init(exerciseName: "Back Squat",            targetSets: 5, targetReps: 5),
                        .init(exerciseName: "Overhead Press",        targetSets: 5, targetReps: 5),
                        .init(exerciseName: "Conventional Deadlift", targetSets: 1, targetReps: 5),
                    ]
                ),
            ]
        ),
    ]
}

// MARK: - List view

struct StarterProgramsView: View {

    @State private var selected: StarterProgram?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock
                VStack(spacing: Theme.Spacing.md) {
                    ForEach(StarterProgram.catalog) { program in
                        ProgramCard(program: program) {
                            Haptics.selection()
                            selected = program
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(item: $selected) { program in
            StarterProgramDetailView(program: program)
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                ForgeWordmark(size: 16)
                    .foregroundStyle(.white)
                Spacer()
                Text("PROGRAMS")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Theme.Typo.heroHeadline("Pick a split.")
                .foregroundStyle(.white)

            Text("Each program drops a few routines into your week — pre-scheduled, ready to start.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
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
}

// MARK: - Card

private struct ProgramCard: View {
    let program: StarterProgram
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Theme.Typo.eyebrow(routineNamesLine)
                    Text(program.name)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(program.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        Text("\(program.daysPerWeek)")
                            .font(.caption.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.tint)
                        Text("DAYS / WEEK")
                            .font(.caption2.weight(.heavy))
                            .tracking(1.2)
                            .foregroundStyle(.tint)
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGlassBackground(cornerRadius: Theme.Radius.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var routineNamesLine: String {
        program.routines
            .map { $0.name.uppercased() }
            .joined(separator: " · ")
    }
}

// MARK: - Detail

struct StarterProgramDetailView: View {

    let program: StarterProgram

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var didAdopt = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    ForEach(program.routines, id: \.self) { template in
                        routineCard(template)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.lg)
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            adoptBar
        }
        .alert("Program adopted", isPresented: $didAdopt) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your routines are scheduled. Open the Week view to see them in place.")
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                ForgeWordmark(size: 16)
                    .foregroundStyle(.white)
                Spacer()
                Text("PROGRAM")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Theme.Typo.heroHeadline(program.name)
                .foregroundStyle(.white)

            Text(program.tagline)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
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

    private func routineCard(_ template: StarterProgram.Template) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(template.name)
                    .font(.headline.weight(.bold))
                Spacer()
                Theme.Typo.eyebrow(scheduleLine(template.scheduledDays))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)

            Divider().padding(.horizontal, Theme.Spacing.md)

            VStack(spacing: 0) {
                ForEach(Array(template.exercises.enumerated()), id: \.offset) { idx, item in
                    exerciseRow(item)
                    if idx < template.exercises.count - 1 {
                        Divider().padding(.leading, Theme.Spacing.md)
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appGlassBackground(cornerRadius: Theme.Radius.lg)
    }

    private func exerciseRow(_ item: StarterProgram.Item) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(item.exerciseName)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(item.targetSets) × \(item.targetReps.map(String.init) ?? "—")")
                .font(.footnote.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(minHeight: 40)
    }

    private func scheduleLine(_ days: [Int]) -> String {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        return days.sorted().map { symbols[($0 - 1) % 7] }.joined(separator: " · ")
    }

    private var adoptBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                Haptics.tap()
                adopt()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Adopt program")
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    Theme.Palette.accentGradient(.accentColor),
                    in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    private func adopt() {
        let byName = Dictionary(uniqueKeysWithValues: allExercises.map {
            ($0.name.lowercased(), $0)
        })

        for template in program.routines {
            let routine = Routine(
                name: template.name,
                scheduledDays: template.scheduledDays
            )
            modelContext.insert(routine)
            for (idx, item) in template.exercises.enumerated() {
                guard let exercise = byName[item.exerciseName.lowercased()] else { continue }
                let routineExercise = RoutineExercise(
                    exerciseIndex: idx,
                    targetSets: item.targetSets,
                    targetReps: item.targetReps,
                    exercise: exercise
                )
                routineExercise.parentRoutine = routine
                modelContext.insert(routineExercise)
                routine.exercises.append(routineExercise)
            }
        }
        try? modelContext.save()
        Haptics.success()
        didAdopt = true
    }
}

#Preview("Catalog") {
    NavigationStack { StarterProgramsView() }
}
