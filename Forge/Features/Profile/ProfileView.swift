import SwiftUI

struct ProfileView: View {

    @AppStorage(AppAccent.storageKey)
    private var accentRaw: String = AppAccent.blue.rawValue

    @State private var showingKeySheet = false
    @State private var hasStoredKey: Bool = KeychainService.hasKey()

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
                appearanceSection
                aiSection
                aboutSection
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Color(.systemGroupedBackground))
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
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Appearance", caption: "Pick the accent that matches your vibe")
            GlassCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Accent color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    AccentPickerRow(selection: accentBinding)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(
                "AI",
                caption: hasStoredKey
                    ? "Powering Coach and GymBro"
                    : "Required for Coach and GymBro"
            )
            GlassCard(padding: 0) {
                AppListRow(
                    icon: hasStoredKey ? "key.fill" : "key",
                    title: hasStoredKey ? "Qwen connected" : "Connect AI",
                    subtitle: hasStoredKey
                        ? AIConfig.defaultModel
                        : "Add your API key to enable AI features",
                    action: { showingKeySheet = true }
                )
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
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
                        subtitle: "AI features arrive in the next update."
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

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(AppAccent.allCases) { accent in
                Button {
                    Haptics.selection()
                    selection = accent
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(selection == accent ? 0.9 : 0),
                                    lineWidth: 2
                                )
                                .padding(-4)
                        )
                        .animation(.spring(duration: 0.25), value: selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.label)
                .accessibilityAddTraits(selection == accent ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
