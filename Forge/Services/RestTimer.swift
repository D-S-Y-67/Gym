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
    /// PR 16: one-shot guard so the 5s warning haptic doesn't refire if the
    /// user taps `+15s` and the timer crosses 5 again on the way back down.
    private var didFireWarning: Bool = false

    func start(duration: Int) {
        cancel()
        let clamped = max(1, duration)
        targetSeconds = clamped
        remainingSeconds = clamped
        startReference = .now
        isActive = true
        didFireWarning = false
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
            let previous = remainingSeconds
            remainingSeconds = max(0, remaining)
            // PR 16: light tap as the timer crosses into the last 5 seconds.
            if previous > 5 && remainingSeconds <= 5 && remainingSeconds > 0 && !didFireWarning {
                didFireWarning = true
                Haptics.tap()
            }
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
            // PR 16: ringer-respecting "tink" plays alongside the haptic
            // when the user has the toggle on (default true).
            if UserDefaults.standard.bool(forKey: "restTimerSound") {
                Sounds.restComplete()
            }
        }
    }
}
