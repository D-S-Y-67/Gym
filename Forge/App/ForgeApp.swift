import SwiftUI
import SwiftData

@main
struct ForgeApp: App {

    @AppStorage(AppAccent.storageKey)
    private var accentRaw: String = AppAccent.blue.rawValue

    @State private var session: WorkoutSessionStore
    @State private var restTimer = RestTimer()

    private let container: ModelContainer

    private var accent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
    }

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Schema(AppSchema.allModels),
                configurations: ModelConfiguration()
            )
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
        self.container = container

        SeedData.seedIfNeeded(container.mainContext)
        _session = State(initialValue: WorkoutSessionStore(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(accent.color)
                .fontDesign(.rounded)
                .environment(session)
                .environment(restTimer)
        }
        .modelContainer(container)
    }
}
