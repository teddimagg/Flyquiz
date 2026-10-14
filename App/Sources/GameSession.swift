import FlyquizCore
import SwiftUI

/// Drives one round on screen: timing, feedback delays and the Blitz clock.
@MainActor
@Observable
final class GameSession: Identifiable {
    enum Phase: Equatable {
        case asking
        case feedback
        case finished
    }

    let id = UUID()
    private(set) var round: Round
    private(set) var phase: Phase = .asking
    /// The question on screen. Stays put during feedback while `round` has already moved on.
    private(set) var question: Question?
    private(set) var picked: Country?
    private(set) var outcome: RoundOutcome?
    private(set) var lastAward = 0
    private(set) var awardCount = 0
    private(set) var mistakeCount = 0
    private(set) var blitzEnds: Date?

    private let onFinish: (Round) -> RoundOutcome?
    @ObservationIgnored private var shownAt = Date()
    @ObservationIgnored private var advanceTask: Task<Void, Never>?
    @ObservationIgnored private var clockTask: Task<Void, Never>?
    @ObservationIgnored private var rng = SystemRandomNumberGenerator()

    /// Snappy pacing: a correct answer barely pauses; a wrong one lingers just long enough to learn.
    static let correctDelay: Duration = .milliseconds(380)
    static let wrongDelay: Duration = .milliseconds(1100)
    static let blitzWrongDelay: Duration = .milliseconds(650)

    init(round: Round, onFinish: @escaping (Round) -> RoundOutcome?) {
        self.round = round
        self.onFinish = onFinish
        start(round)
    }

    func start(_ round: Round) {
        stop()
        self.round = round
        outcome = nil
        picked = nil
        mistakeCount = 0
        awardCount = 0
        question = round.current
        phase = .asking
        shownAt = Date()
        blitzEnds = nil
        if round.isEndless { startClock() }
    }

    func stop() {
        advanceTask?.cancel()
        clockTask?.cancel()
        advanceTask = nil
        clockTask = nil
    }

    var combo: Int { round.combo }
    var answeredCount: Int { round.answers.count }
    var progress: Double {
        round.questions.isEmpty ? 0 : Double(round.answers.count) / Double(round.questions.count)
    }

    func pick(_ country: Country) {
        guard phase == .asking, question != nil else { return }
        let responseTime = Date().timeIntervalSince(shownAt)
        guard let record = round.answer(country, responseTime: responseTime) else { return }
        picked = country
        phase = .feedback

        let delay: Duration
        if record.isCorrect {
            Haptics.shared.correct(combo: record.comboAfter)
            lastAward = record.xp
            awardCount += 1
            delay = Self.correctDelay
        } else {
            Haptics.shared.wrong()
            mistakeCount += 1
            delay = round.isEndless ? Self.blitzWrongDelay : Self.wrongDelay
        }

        if round.isEndless, round.questions.count - round.index < 5 {
            let recent = round.questions.map(\.answer.code)
            round.append(RoundBuilder.blitzQuestions(startingAt: round.questions.count, count: 10,
                                                     avoiding: recent, using: &rng))
        }

        advanceTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.advance()
        }
    }

    /// Tap anywhere during feedback to move on immediately.
    func skipFeedback() {
        guard phase == .feedback else { return }
        advanceTask?.cancel()
        advance()
    }

    private func advance() {
        guard phase == .feedback else { return }
        picked = nil
        if round.isFinished {
            finish()
        } else {
            question = round.current
            phase = .asking
            shownAt = Date()
        }
    }

    private func startClock() {
        blitzEnds = Date().addingTimeInterval(Round.blitzDuration)
        clockTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Round.blitzDuration))
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    private func finish() {
        guard phase != .finished else { return }
        stop()
        if round.isEndless { round.finish() }
        outcome = onFinish(round)
        phase = .finished
        if let outcome, outcome.leveledUp || outcome.stars == 3 || outcome.isNewBest {
            Haptics.shared.celebrate()
        }
    }
}
