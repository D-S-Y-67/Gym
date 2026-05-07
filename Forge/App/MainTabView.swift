import SwiftUI
import SwiftData

/// Routes pushed inside the Home tab. Hashable via `PersistentIdentifier`
/// so SwiftData models can be referenced without violating Sendable.
///
/// PR 11 collapsed `LibraryRoute.exerciseDetail` into this enum since
/// Library is no longer a separate tab. All Home → sub-screen pushes go
/// through this single homogeneous path.
enum WorkoutsRoute: Hashable {
    case active
    case routines
    case editRoutine(PersistentIdentifier)
    case workoutDetail(PersistentIdentifier)
    case weeklySchedule
    case body
    case library
    case exerciseDetail(PersistentIdentifier)
    case insights
}

/// Root tab bar. PR 11 collapsed five tabs to three: **Home · AI · Profile**.
///
/// - Library is no longer a tab — its content surfaces on Home as a
///   horizontal carousel and the full screen is reachable via push from
///   Home (`WorkoutsRoute.library`).
/// - GymBro and Coach merged into a single AI hub. The AI tab opens
///   `AIHubView`, which pushes either chat onto its own NavigationStack.
/// - Coach is also a one-tap shortcut from Home via a floating circular
///   button that presents `CoachView` as a sheet.
struct MainTabView: View {

    enum Tab: Hashable {
        case home, ai, profile
    }

    @State private var selection: Tab = .home
    @State private var workoutsPath: [WorkoutsRoute] = []
    @State private var aiPath: [AIRoute] = []
    @State private var profilePath = NavigationPath()

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $selection) {
            homeTab
            aiTab
            profileTab
        }
    }

    // MARK: - Home (was Workouts)

    private var homeTab: some View {
        NavigationStack(path: $workoutsPath) {
            WorkoutsHomeView(path: $workoutsPath)
                .navigationDestination(for: WorkoutsRoute.self) { route in
                    workoutsDestination(for: route)
                }
        }
        .tabItem { Label("Home", systemImage: "dumbbell") }
        .tag(Tab.home)
    }

    @ViewBuilder
    private func workoutsDestination(for route: WorkoutsRoute) -> some View {
        switch route {
        case .active:
            ActiveWorkoutView()
        case .routines:
            RoutinesListView(path: $workoutsPath)
        case .editRoutine(let id):
            if let routine = modelContext.model(for: id) as? Routine {
                RoutineEditorView(routine: routine, path: $workoutsPath)
            } else {
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: "Routine missing",
                    message: "It may have been deleted. Go back and try again."
                )
            }
        case .workoutDetail(let id):
            if let workout = modelContext.model(for: id) as? Workout {
                WorkoutDetailView(workout: workout)
            } else {
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: "Workout missing",
                    message: "It may have been deleted."
                )
            }
        case .weeklySchedule:
            WeeklyScheduleView(path: $workoutsPath)
        case .body:
            BodyView()
        case .insights:
            InsightsView()
        case .library:
            LibraryView { id in
                workoutsPath.append(.exerciseDetail(id))
            }
        case .exerciseDetail(let id):
            if let exercise = modelContext.model(for: id) as? Exercise {
                ExerciseDetailView(
                    exercise: exercise,
                    workoutsPath: $workoutsPath,
                    selectedTab: $selection
                )
            } else {
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: "Exercise missing",
                    message: "It may have been deleted."
                )
            }
        }
    }

    // MARK: - AI (GymBro + Coach)

    private var aiTab: some View {
        NavigationStack(path: $aiPath) {
            AIHubView(path: $aiPath)
                .navigationDestination(for: AIRoute.self) { route in
                    switch route {
                    case .gymBro:
                        GymBroView()
                    case .coach:
                        CoachView()
                    }
                }
        }
        .tabItem { Label("AI", systemImage: "sparkles") }
        .tag(Tab.ai)
    }

    // MARK: - Profile

    private var profileTab: some View {
        NavigationStack(path: $profilePath) {
            ProfileView()
        }
        .tabItem { Label("Profile", systemImage: "person") }
        .tag(Tab.profile)
    }
}
