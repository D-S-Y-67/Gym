import SwiftUI
import SwiftData

/// Routes pushed from the Profile tab. History lives here in PR 7 to keep
/// the tab bar at five (Workouts, Library, GymBro, Coach, Profile).
enum ProfileRoute: Hashable {
    case history
    case workoutDetail(PersistentIdentifier)
}

struct ProfileView: View {

    @AppStorage(AppAccent.storageKey)
    private var accentRaw: String = AppAccent.ember.rawValue

    @State private var showingKeySheet = false
    @State private var hasStoredKey: Bool = KeychainService.hasKey()

    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false
    @State private var healthAuthFailed: Bool = false

    @AppStorage("restTimerSound") private var restTimerSound: Bool = true

    @Environment(\.modelContext) private var modelContext

    private var accent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .ember
    }

    private var accentBinding: Binding<AppAccent> {
        Binding(
            get: { accent },
            set: { accentRaw = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                historySection
                settingsSection
                aboutSection
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingKeySheet) {
            KeyEntrySheet(hasStoredKey: $hasStoredKey)
        }
        .onChange(of: showingKeySheet) { _, isPresented in
            if !isPresented {
                hasStoredKey = KeychainService.hasKey()
            }
        }
        .navigationDestination(for: ProfileRoute.self) { route in
            switch route {
            case .history:
                HistoryListView()
            case .workoutDetail(let id):
                workoutDetailDestination(id: id)
            }
        }
        .navigationDestination(for: PersistentIdentifier.self) { id in
            workoutDetailDestination(id: id)
        }
    }

    @ViewBuilder
    private func workoutDetailDestination(id: PersistentIdentifier) -> some View {
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

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("History")
            GlassCard(padding: 0) {
                NavigationLink(value: ProfileRoute.history) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Workout history")
                                .foregroundStyle(.primary)
                            Text("Every session you've logged")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm + 4)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    /// PR 8 merged "Appearance" and "AI" into one Settings card so the
    /// profile reads as three sections (History, Settings, About) instead
    /// of four. AI key sits on top, accent picker below — same content, less
    /// visual fragmentation.
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(
                "Settings",
                caption: hasStoredKey
                    ? "AI is connected — pick your accent below."
                    : "Add your AI key, then choose an accent."
            )
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    AppListRow(
                        icon: hasStoredKey ? "key.fill" : "key",
                        title: hasStoredKey ? "Qwen connected" : "Connect AI",
                        subtitle: hasStoredKey
                            ? AIConfig.defaultModel
                            : "Add your API key to enable AI features",
                        action: { showingKeySheet = true }
                    )
                    Divider().padding(.leading, 56)
                    healthRow
                    Divider().padding(.leading, 56)
                    restSoundRow
                    Divider().padding(.leading, 56)
                    accentRow
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var healthRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health")
                    .foregroundStyle(.primary)
                Text(healthSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $healthKitEnabled)
                .labelsHidden()
                .tint(.accentColor)
                .onChange(of: healthKitEnabled) { _, isOn in
                    if isOn {
                        Task { await requestHealthAuth() }
                    } else {
                        healthAuthFailed = false
                    }
                }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .frame(minHeight: 44)
    }

    private var healthSubtitle: String {
        if !HealthKitService.shared.isAvailable {
            return "Not available on this device"
        }
        if healthAuthFailed {
            return "Permission denied — enable in iOS Settings"
        }
        return healthKitEnabled
            ? "Saving workouts to Health"
            : "Save workouts to Health and credit your rings"
    }

    @MainActor
    private func requestHealthAuth() async {
        do {
            let granted = try await HealthKitService.shared.requestAuthorization()
            if !granted {
                healthAuthFailed = true
                healthKitEnabled = false
            } else {
                healthAuthFailed = false
            }
        } catch {
            healthAuthFailed = true
            healthKitEnabled = false
        }
    }

    /// PR 16: rest-timer sound preference. iOS plays the system sound
    /// through the ringer pipeline, so the silent switch already silences
    /// it. This toggle is for users who want it off even on ring.
    private var restSoundRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest timer sound")
                    .foregroundStyle(.primary)
                Text("Plays a tink when your rest hits zero")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $restTimerSound)
                .labelsHidden()
                .tint(.accentColor)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .frame(minHeight: 44)
    }

    private var accentRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "paintpalette.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            Text("Accent")
                .foregroundStyle(.primary)
            Spacer()
            AccentPickerRow(selection: accentBinding)
                .fixedSize()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .frame(minHeight: 44)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("About")
            GlassCard {
                VStack(spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForgeWordmark(size: 22)
                            .foregroundStyle(.tint)
                        Spacer()
                        Text(appVersionString)
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    Text("Workouts, AI coach, weekly schedule — all on device. Built for serious lifters.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var appVersionString: String {
        let dict = Bundle.main.infoDictionary ?? [:]
        let version = (dict["CFBundleShortVersionString"] as? String) ?? "0.0"
        let build = (dict["CFBundleVersion"] as? String) ?? "0"
        return "\(version) (\(build))"
    }
}

struct AccentPickerRow: View {
    @Binding var selection: AppAccent
    var size: CGFloat = 26

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(AppAccent.allCases) { accent in
                Button {
                    Haptics.selection()
                    selection = accent
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(selection == accent ? 0.9 : 0),
                                    lineWidth: 2
                                )
                                .padding(-3)
                        )
                        .animation(.spring(duration: 0.25), value: selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.label)
                .accessibilityAddTraits(selection == accent ? .isSelected : [])
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
