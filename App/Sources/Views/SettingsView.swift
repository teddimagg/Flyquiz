import FlyquizCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section {
                    Toggle("Haptics", isOn: $app.hapticsEnabled)
                }
                Section("Stats") {
                    LabeledContent("Rounds played", value: "\(app.progress.roundsPlayed)")
                    LabeledContent("Best streak", value: "\(app.progress.bestStreak) days")
                    LabeledContent("Blitz best", value: "\(app.progress.blitzBest)")
                    LabeledContent("Total XP", value: "\(app.progress.totalXP)")
                }
                Section {
                    Button("Reset progress", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Flyquiz \(Self.version)")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { app.resetProgress() }
            } message: {
                Text("XP, stars, streaks and your Flagdex will be wiped.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
