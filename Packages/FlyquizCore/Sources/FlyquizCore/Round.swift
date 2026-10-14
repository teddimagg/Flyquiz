import Foundation

public enum RoundMode: Hashable, Codable, Sendable {
    case stage(String)
    case blitz
    case daily(String)
    case review

    public var title: String {
        switch self {
        case .stage(let id):
            guard let stage = Campaign.stage(id), let chapter = Campaign.chapter(stage.chapterID) else { return "Stage" }
            return "\(chapter.title) \(stage.number)"
        case .blitz: return "Blitz"
        case .daily: return "Daily Challenge"
        case .review: return "Review"
        }
    }
}

public struct AnswerRecord: Hashable, Sendable {
    public let question: Question
    public let picked: Country
    public let responseTime: TimeInterval
    public let xp: Int
    public let comboAfter: Int

    public var isCorrect: Bool { picked == question.answer }
}

/// One play-through. Pure value type; the UI layer owns timing and animation.
public struct Round: Sendable {
    public static let blitzDuration: TimeInterval = 60
    public static let fastAnswer: TimeInterval = 2.5

    public let mode: RoundMode
    public private(set) var questions: [Question]
    public private(set) var answers: [AnswerRecord] = []
    public private(set) var combo = 0
    public private(set) var bestCombo = 0
    public private(set) var xp = 0

    public init(mode: RoundMode, questions: [Question]) {
        self.mode = mode
        self.questions = questions
    }

    public var index: Int { answers.count }
    public var current: Question? { index < questions.count ? questions[index] : nil }
    public var isFinished: Bool { current == nil }
    public var correctCount: Int { answers.filter(\.isCorrect).count }
    public var isEndless: Bool { mode == .blitz }

    public static func xp(forCorrectAnswerWithCombo combo: Int, responseTime: TimeInterval) -> Int {
        10 + min(max(combo - 1, 0), 5) * 2 + (responseTime < fastAnswer ? 5 : 0)
    }

    @discardableResult
    public mutating func answer(_ picked: Country, responseTime: TimeInterval) -> AnswerRecord? {
        guard let question = current else { return nil }
        let earned: Int
        if picked == question.answer {
            combo += 1
            bestCombo = max(bestCombo, combo)
            earned = Round.xp(forCorrectAnswerWithCombo: combo, responseTime: responseTime)
        } else {
            combo = 0
            earned = 0
        }
        xp += earned
        let record = AnswerRecord(question: question, picked: picked, responseTime: responseTime,
                                  xp: earned, comboAfter: combo)
        answers.append(record)
        return record
    }

    public mutating func append(_ more: [Question]) {
        questions += more
    }

    /// Ends an endless round early (Blitz timer ran out): drops unanswered questions.
    public mutating func finish() {
        questions = Array(questions.prefix(answers.count))
    }
}

// MARK: - Round builders

public enum RoundBuilder {
    public static func stage<R: RandomNumberGenerator>(_ stage: Stage, using rng: inout R) -> Round {
        let fresh = stage.countries.shuffled(using: &rng)
        let review = stage.reviewCodes.compactMap(Countries.country).shuffled(using: &rng)

        var picks = Array(fresh.prefix(stage.questionCount))
        var reviewIterator = review.makeIterator()
        var repeatPool = fresh.shuffled(using: &rng).makeIterator()
        while picks.count < stage.questionCount {
            if let next = reviewIterator.next() {
                picks.append(next)
            } else if let again = repeatPool.next() {
                picks.append(again)
            } else {
                repeatPool = fresh.shuffled(using: &rng).makeIterator()
            }
        }
        picks = spreadOut(picks.shuffled(using: &rng))

        let questions = picks.map { country in
            let kind: QuestionKind = Double.random(in: 0..<1, using: &rng) < stage.nameToFlagRatio ? .nameToFlag : .flagToName
            return QuestionFactory.make(answer: country, kind: kind, difficulty: stage.difficulty, using: &rng)
        }
        return Round(mode: .stage(stage.id), questions: questions)
    }

    public static func daily(dayKey: String) -> Round {
        var rng = SeededGenerator(string: "flyquiz-daily-\(dayKey)")
        let easy = Countries.all.filter { $0.tier <= 2 }.shuffled(using: &rng).prefix(3)
        let medium = Countries.all.filter { $0.tier == 3 }.shuffled(using: &rng).prefix(4)
        let hard = Countries.all.filter { $0.tier >= 4 }.shuffled(using: &rng).prefix(3)
        let picks = Array(easy) + Array(medium) + Array(hard)
        let questions = picks.enumerated().map { i, country in
            let kind: QuestionKind = Double.random(in: 0..<1, using: &rng) < 0.3 ? .nameToFlag : .flagToName
            return QuestionFactory.make(answer: country, kind: kind, difficulty: 1 + i / 3, using: &rng)
        }
        return Round(mode: .daily(dayKey), questions: questions)
    }

    /// First batch of an endless Blitz round. Call `blitzQuestions(startingAt:)` to extend.
    public static func blitz<R: RandomNumberGenerator>(using rng: inout R) -> Round {
        Round(mode: .blitz, questions: blitzQuestions(startingAt: 0, count: 15, avoiding: [], using: &rng))
    }

    /// Difficulty ramps with the question index: famous flags first, obscure ones later.
    public static func blitzQuestions<R: RandomNumberGenerator>(
        startingAt start: Int, count: Int, avoiding recent: [String], using rng: inout R
    ) -> [Question] {
        var avoid = Set(recent.suffix(30))
        var result: [Question] = []
        for i in start..<start + count {
            let maxTier = min(5, 1 + i / 5)
            let candidates = Countries.all.filter { $0.tier <= maxTier && !avoid.contains($0.code) }
            guard let country = (candidates.isEmpty ? Countries.all : candidates).randomElement(using: &rng) else { continue }
            avoid.insert(country.code)
            let kind: QuestionKind = i > 5 && Double.random(in: 0..<1, using: &rng) < 0.25 ? .nameToFlag : .flagToName
            result.append(QuestionFactory.make(answer: country, kind: kind, difficulty: min(4, 1 + i / 8), using: &rng))
        }
        return result
    }

    public static func review<R: RandomNumberGenerator>(codes: [String], using rng: inout R) -> Round {
        let questions = codes.compactMap(Countries.country).shuffled(using: &rng).map { country in
            let kind: QuestionKind = Double.random(in: 0..<1, using: &rng) < 0.4 ? .nameToFlag : .flagToName
            return QuestionFactory.make(answer: country, kind: kind, difficulty: 3, using: &rng)
        }
        return Round(mode: .review, questions: questions)
    }

    /// Avoids the same flag appearing twice in a row.
    static func spreadOut(_ items: [Country]) -> [Country] {
        var result = items
        guard result.count > 2 else { return result }
        for i in 1..<result.count where result[i] == result[i - 1] {
            if let j = result.indices.first(where: { j in
                j != i && result[j] != result[i]
                    && (j == 0 || result[j - 1] != result[i])
                    && (j + 1 >= result.count || result[j + 1] != result[i])
            }) {
                result.swapAt(i, j)
            }
        }
        return result
    }
}
