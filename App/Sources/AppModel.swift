import FlyquizCore
import SwiftUI

@MainActor
@Observable
final class AppModel {
    private(set) var progress: PlayerProgress
    var session: GameSession?

    var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: Self.hapticsKey)
            Haptics.shared.enabled = hapticsEnabled
        }
    }

    private static let hapticsKey = "hapticsEnabled"
    private let store = ProgressStore()

    init() {
        progress = ProgressStore().load()
        hapticsEnabled = UserDefaults.standard.object(forKey: Self.hapticsKey) as? Bool ?? true
        Haptics.shared.enabled = hapticsEnabled
    }

    var todayKey: String { DayKey.key(for: .now) }

    func play(_ mode: RoundMode) {
        guard let round = makeRound(mode) else { return }
        Haptics.shared.prepare()
        if let session {
            session.start(round)
        } else {
            session = GameSession(round: round) { [weak self] finished in
                self?.complete(finished)
            }
        }
    }

    func quitSession() {
        session?.stop()
        session = nil
    }

    func resetProgress() {
        progress = PlayerProgress()
        store.save(progress)
    }

    private func complete(_ round: Round) -> RoundOutcome? {
        let outcome = progress.apply(round, at: .now)
        store.save(progress)
        return outcome
    }

    private func makeRound(_ mode: RoundMode) -> Round? {
        var rng = SystemRandomNumberGenerator()
        switch mode {
        case .stage(let id):
            guard let stage = Campaign.stage(id) else { return nil }
            return RoundBuilder.stage(stage, using: &rng)
        case .blitz:
            return RoundBuilder.blitz(using: &rng)
        case .daily(let key):
            return RoundBuilder.daily(dayKey: key)
        case .review:
            let codes = progress.reviewCodes(at: .now)
            guard !codes.isEmpty else { return nil }
            return RoundBuilder.review(codes: codes, using: &rng)
        }
    }
}

struct ProgressStore {
    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("progress.json")
    }()

    func load() -> PlayerProgress {
        guard let data = try? Data(contentsOf: url),
              let progress = try? JSONDecoder().decode(PlayerProgress.self, from: data)
        else { return PlayerProgress() }
        return progress
    }

    func save(_ progress: PlayerProgress) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(progress).write(to: url, options: .atomic)
        } catch {
            assertionFailure("Failed to save progress: \(error)")
        }
    }
}
