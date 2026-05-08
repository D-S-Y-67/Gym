import Foundation
import HealthKit

/// Wrapper around `HKHealthStore` for Forge's write-only HealthKit sync.
///
/// **v1 scope:** push completed Forge workouts as `HKWorkout` of type
/// `.traditionalStrengthTraining`. No reads (no NSHealthShareUsageDescription
/// is requested). Reading external workouts, bodyweight, etc. is a v2 add.
///
/// All methods are no-ops if HealthKit isn't available (iPad without Health,
/// Designed-for-iPad on Mac, etc.) or if the user hasn't authorized writes.
/// Errors are swallowed and logged — the local Forge workout is unaffected.
@MainActor
final class HealthKitService {

    static let shared = HealthKitService()

    private let store = HKHealthStore()

    private init() {}

    /// True when HealthKit is supported on the current device.
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Current sharing authorization for `HKWorkoutType`.
    var workoutAuthorizationStatus: HKAuthorizationStatus {
        guard isAvailable else { return .notDetermined }
        return store.authorizationStatus(for: HKObjectType.workoutType())
    }

    /// Requests share for `HKWorkoutType` only (no reads in v1). Returns
    /// `true` if the user granted (or had previously granted), `false`
    /// otherwise — including cases where HK is unavailable or the user
    /// declined.
    func requestAuthorization() async throws -> Bool {
        guard isAvailable else { return false }
        let workoutType = HKObjectType.workoutType()
        try await store.requestAuthorization(toShare: [workoutType], read: [])
        return store.authorizationStatus(for: workoutType) == .sharingAuthorized
    }

    /// Push a finished Forge workout as an `HKWorkout`. Silently no-ops
    /// if HK is unavailable, the user hasn't authorized writes, or the
    /// workout doesn't have an `endedAt` yet.
    func saveWorkout(_ workout: Workout) async {
        guard isAvailable else { return }
        guard let endedAt = workout.endedAt else { return }

        let workoutType = HKObjectType.workoutType()
        guard store.authorizationStatus(for: workoutType) == .sharingAuthorized else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        do {
            try await builder.beginCollection(at: workout.startedAt)
            try await builder.endCollection(at: endedAt)
            _ = try await builder.finishWorkout()
        } catch {
            // Don't surface — the local Forge workout already saved fine,
            // and HK errors during write aren't actionable for the user.
            print("[HealthKit] saveWorkout failed: \(error.localizedDescription)")
        }
    }
}
