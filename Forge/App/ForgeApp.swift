import SwiftUI
import SwiftData

@main
struct ForgeApp: App {

    @AppStorage(AppAccent.storageKey)
    private var accentRaw: String = AppAccent.blue.rawValue

    private var accent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(accent.color)
        }
        .modelContainer(for: [
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            Routine.self,
            ChatMessage.self
        ])
    }
}
