import SwiftUI
import SwiftData

/// App root. Hosts `MainTabView` and gates the first-launch onboarding
/// (PR 12) via `@AppStorage("hasCompletedOnboarding")`.
///
/// Grandfather rule: on first run after this PR ships, if the user already
/// has finished workouts, we mark onboarding complete silently — they
/// don't need a welcome tour for an app they're already using.
struct RootView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @Environment(\.modelContext) private var modelContext

    @State private var showingOnboarding = false
    @State private var didDecide = false

    var body: some View {
        MainTabView()
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView {
                    hasCompletedOnboarding = true
                    showingOnboarding = false
                }
            }
            .task {
                guard !didDecide else { return }
                didDecide = true
                if hasCompletedOnboarding { return }
                if existingFinishedWorkoutCount() > 0 {
                    // Returning user — skip onboarding silently.
                    hasCompletedOnboarding = true
                } else {
                    showingOnboarding = true
                }
            }
    }

    private func existingFinishedWorkoutCount() -> Int {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

#Preview {
    RootView()
}
