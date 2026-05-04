import Foundation
import Observation

/// Drives the rest-timer overlay shown on the active-workout screen.
///
/// Lifecycle:
/// - `start(duration:)` resets to `duration` and begins counting down.
/// - `+15s` / `-15s` adjust both `targetSeconds` and `remainingSeconds`.
/// - At 0 the timer fires `Haptics.success()` and clears `isActive`.
/// - `skip()` cancels immediately (no haptic).
///
/// Implementation detail: a single `Task` ticks once per second using
/// `Task.sleep`. We don't use `Timer` because `Task` plays nicely with
/// Swift concurrency and `@MainActor` isolation.
@MainActor
@Observable
final class RestTimer {

    private(set) var targetSeconds: Int = 0
    private(set) var remainingSeconds: Int = 0
    private(set) var isActive: Bool = false
    private var startReference: Date?
    private var tickTask: Task<Void, Never>?

    func start(duration: Int) {
        cancel()
        let clamped = max(1, duration)
        targetSeconds = clamped
        remainingSeconds = clamped
        startReference = .now
        isActive = true
        tickTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func add(seconds: Int) {
        guard isActive else { return }
        targetSeconds += seconds
        remainingSeconds = max(0, remainingSeconds + seconds)
        if remainingSeconds == 0 { finish(triggerHaptic: false) }
    }

    func skip() {
        finish(triggerHaptic: false)
    }

    /// Cancels without changing flags — used when the host view is dismissed.
    func cancel() {
        tickTask?.cancel()
        tickTask = nil
        isActive = false
        remainingSeconds = 0
        targetSeconds = 0
        startReference = nil
    }

    private func runLoop() async {
        while !Task.isCancelled, isActive, let started = startReference {
            // Recompute from wall clock so backgrounding doesn't drift.
            let elapsed = Int(Date.now.timeIntervalSince(started).rounded())
            let remaining = targetSeconds - elapsed
            remainingSeconds = max(0, remaining)
            if remaining <= 0 {
                finish(triggerHaptic: true)
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    private func finish(triggerHaptic: Bool) {
        tickTask?.cancel()
        tickTask = nil
        isActive = false
        remainingSeconds = 0
        startReference = nil
        if triggerHaptic {
            Haptics.success()
        }
    }
}
