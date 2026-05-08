import SwiftUI

/// Bottom-anchored rest-timer pill, driven by the shared `RestTimer`
/// environment object. Visible only while `timer.isActive`.
struct RestTimerOverlay: View {

    @Environment(RestTimer.self) private var timer

    var body: some View {
        if timer.isActive {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text(formatTime(timer.remainingSeconds))
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(duration: 0.2), value: timer.remainingSeconds)
                    .accessibilityLabel("\(timer.remainingSeconds) seconds remaining")

                Spacer(minLength: Theme.Spacing.sm)

                Button("−15s") { timer.add(seconds: -15) }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Subtract 15 seconds")

                Button("+15s") { timer.add(seconds: 15) }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Add 15 seconds")

                Button("Skip") {
                    Haptics.tap()
                    timer.skip()
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel("Skip rest")
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .appGlassBackground(cornerRadius: Theme.Radius.lg)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
