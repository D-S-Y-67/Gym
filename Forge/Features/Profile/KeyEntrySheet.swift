import SwiftUI

/// Modal sheet for entering, testing, and removing the Qwen API key.
///
/// Owns its own `apiKey` draft. Pre-fills nothing on appear (we never re-show
/// the stored key — the field is for new entries / replacements only). Dismiss
/// with Cancel keeps the existing stored key untouched.
struct KeyEntrySheet: View {

    /// Bound to the parent so the Profile row updates immediately on Save / Disconnect.
    @Binding var hasStoredKey: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var testState: TestState = .idle
    @State private var saveError: String?

    private enum TestState: Equatable {
        case idle
        case running
        case success
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-…", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Stored in iOS Keychain on this device. Used only with the Qwen API.")
                }

                Section {
                    Button {
                        Task { await runTest() }
                    } label: {
                        HStack {
                            if testState == .running {
                                ProgressView().controlSize(.small)
                            }
                            Text(testState == .running ? "Testing…" : "Test Connection")
                        }
                    }
                    .disabled(apiKey.trimmed.isEmpty || testState == .running)

                    testResultRow
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                if hasStoredKey {
                    Section {
                        Button(role: .destructive) {
                            disconnect()
                        } label: {
                            Label("Disconnect", systemImage: "xmark.circle")
                        }
                    } footer: {
                        Text("Removes the stored key from this device.")
                    }
                }
            }
            .navigationTitle("Connect AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(apiKey.trimmed.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var testResultRow: some View {
        switch testState {
        case .idle, .running:
            EmptyView()
        case .success:
            Label("Connection works", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.footnote)
        case .failure(let message):
            VStack(alignment: .leading, spacing: 4) {
                Label("Test failed", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
    }

    // MARK: - Actions

    private func runTest() async {
        let trimmed = apiKey.trimmed
        guard !trimmed.isEmpty else { return }
        testState = .running
        do {
            try await QwenService.shared.testConnection(apiKey: trimmed)
            testState = .success
            Haptics.success()
        } catch {
            testState = .failure(error.localizedDescription)
            Haptics.warning()
        }
    }

    private func save() {
        let trimmed = apiKey.trimmed
        guard !trimmed.isEmpty else { return }
        do {
            try KeychainService.save(trimmed)
            hasStoredKey = true
            saveError = nil
            Haptics.success()
            dismiss()
        } catch {
            saveError = error.localizedDescription
            Haptics.error()
        }
    }

    private func disconnect() {
        do {
            try KeychainService.delete()
            hasStoredKey = false
            apiKey = ""
            testState = .idle
            saveError = nil
            Haptics.warning()
        } catch {
            saveError = error.localizedDescription
            Haptics.error()
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#Preview("Empty") {
    StatefulPreviewWrapper(false) { hasKey in
        KeyEntrySheet(hasStoredKey: hasKey)
    }
}

#Preview("Connected") {
    StatefulPreviewWrapper(true) { hasKey in
        KeyEntrySheet(hasStoredKey: hasKey)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
