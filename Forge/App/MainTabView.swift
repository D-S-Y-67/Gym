import SwiftUI
import SwiftData

/// Routes pushed inside the Workouts tab. Hashable via `PersistentIdentifier`
/// so SwiftData models can be referenced without violating Sendable.
enum WorkoutsRoute: Hashable {
    case active
    case routines
    case editRoutine(PersistentIdentifier)
    case workoutDetail(PersistentIdentifier)
}

/// Root tab bar. PR 2 ships 3 tabs; Library / Coach / GymBro slot in
/// as their respective PRs land.
///
/// Each tab owns its own `NavigationStack` so paths are independent.
/// The Workouts tab uses an explicit `[WorkoutsRoute]` so child views
/// can pop to root and push the active workout in one step (e.g. when
/// starting a session from a routine deep in the editor).
struct MainTabView: View {

    enum Tab: Hashable {
        case workouts, history, profile
    }

    @State private var selection: Tab = .workouts
    @State private var workoutsPath: [WorkoutsRoute] = []
    @State private var historyPath = NavigationPath()

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $selection) {
            workoutsTab
            historyTab
            profileTab
        }
    }

    // MARK: - Workouts

    private var workoutsTab: some View {
        NavigationStack(path: $workoutsPath) {
            WorkoutsHomeView(path: $workoutsPath)
                .navigationDestination(for: WorkoutsRoute.self) { route in
                    workoutsDestination(for: route)
                }
        }
        .tabItem { Label("Workouts", systemImage: "dumbbell") }
        .tag(Tab.workouts)
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
        }
    }

    // MARK: - History

    private var historyTab: some View {
        NavigationStack(path: $historyPath) {
            HistoryListView()
                .navigationDestination(for: PersistentIdentifier.self) { id in
                    if let workout = modelContext.model(for: id) as? Workout {
                        WorkoutDetailView(workout: workout)
                    } else {
                        EmptyStateView(
                            symbol: "exclamationmark.triangle",
                            title: "Workout missing",
                            message: "It may have been deleted."
                        )
                    }
                }
        }
        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
        .tag(Tab.history)
    }

    // MARK: - Profile

    private var profileTab: some View {
        NavigationStack {
            ProfileView()
        }
        .tabItem { Label("Profile", systemImage: "person") }
        .tag(Tab.profile)
    }
}
