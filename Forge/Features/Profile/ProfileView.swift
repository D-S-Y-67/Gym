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
    private var accentRaw: String = AppAccent.blue.rawValue

    @State private var showingKeySheet = false
    @State private var hasStoredKey: Bool = KeychainService.hasKey()

    @Environment(\.modelContext) private var modelContext

    private var accent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
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
                    accentRow
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
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
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    AppListRow(
                        icon: "info.circle",
                        title: "Version",
                        subtitle: appVersionString,
                        trailing: { EmptyView() }
                    )
                    Divider().padding(.leading, 56)
                    AppListRow(
                        icon: "heart",
                        title: "Built for serious lifters",
                        subtitle: "Workouts, AI coach, weekly schedule — all on device."
                    )
                }
                .padding(.vertical, Theme.Spacing.xs)
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
