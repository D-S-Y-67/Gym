import SwiftUI
import SwiftData

/// Routes pushed inside the Workouts tab. Hashable via `PersistentIdentifier`
/// so SwiftData models can be referenced without violating Sendable.
enum WorkoutsRoute: Hashable {
    case active
    case routines
    case editRoutine(PersistentIdentifier)
    case workoutDetail(PersistentIdentifier)
    case weeklySchedule
    case body
}

/// Routes pushed inside the Library tab.
enum LibraryRoute: Hashable {
    case exerciseDetail(PersistentIdentifier)
}

/// Root tab bar. PR 7 ships 5 tabs: Workouts, Library, GymBro, Coach, Profile.
/// History folded into Profile to keep the tab bar at five with Coach added.
///
/// Each tab owns its own `NavigationStack` so paths are independent.
/// The Workouts tab uses an explicit `[WorkoutsRoute]` so child views
/// can pop to root and push the active workout in one step (e.g. when
/// starting a session from a routine deep in the editor).
struct MainTabView: View {

    enum Tab: Hashable {
        case workouts, library, gymBro, coach, profile
    }

    @State private var selection: Tab = .workouts
    @State private var workoutsPath: [WorkoutsRoute] = []
    @State private var libraryPath: [LibraryRoute] = []
    @State private var profilePath = NavigationPath()

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $selection) {
            workoutsTab
            libraryTab
            gymBroTab
            coachTab
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
        case .weeklySchedule:
            WeeklyScheduleView(path: $workoutsPath)
        case .body:
            BodyView()
        }
    }

    // MARK: - Library

    private var libraryTab: some View {
        NavigationStack(path: $libraryPath) {
            LibraryView(path: $libraryPath)
                .navigationDestination(for: LibraryRoute.self) { route in
                    switch route {
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
        }
        .tabItem { Label("Library", systemImage: "books.vertical") }
        .tag(Tab.library)
    }

    // MARK: - GymBro

    private var gymBroTab: some View {
        NavigationStack {
            GymBroView()
        }
        .tabItem { Label("GymBro", systemImage: "bubble.left.and.text.bubble.right") }
        .tag(Tab.gymBro)
    }

    // MARK: - Coach

    private var coachTab: some View {
        NavigationStack {
            CoachView()
        }
        .tabItem { Label("Coach", systemImage: "figure.strengthtraining.traditional") }
        .tag(Tab.coach)
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
