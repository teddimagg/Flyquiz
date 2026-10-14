import Foundation

/// Spaced-repetition state for a single flag (Leitner boxes 0…4).
public struct FlagStat: Codable, Hashable, Sendable {
    public static let masteredBox = 4

    public var box: Int = 0
    public var seen: Int = 0
    public var correct: Int = 0
    public var lastSeen: Date?

    public init() {}

    public var isMastered: Bool { box >= Self.masteredBox }

    public mutating func record(correct isCorrect: Bool, at date: Date) {
        seen += 1
        lastSeen = date
        if isCorrect {
            correct += 1
            box = min(Self.masteredBox, box + 1)
        } else {
            box = min(box, 1)
        }
    }

    /// Days to wait before a flag in this box is due for review again.
    static let intervals: [Int] = [0, 0, 1, 3, 7]

    public func isDue(at date: Date, calendar: Calendar = .current) -> Bool {
        guard let last = lastSeen else { return false }
        let wait = Self.intervals[min(box, Self.intervals.count - 1)]
        guard let dueDate = calendar.date(byAdding: .day, value: wait, to: last) else { return true }
        return dueDate <= date
    }
}

public enum Leveling {
    public static func xpToAdvance(from level: Int) -> Int { 150 + (level - 1) * 50 }

    public struct Status: Equatable, Sendable {
        public let level: Int
        public let xpIntoLevel: Int
        public let xpForNext: Int
        public var fraction: Double { Double(xpIntoLevel) / Double(xpForNext) }
    }

    public static func status(forTotalXP xp: Int) -> Status {
        var level = 1
        var remaining = max(0, xp)
        while remaining >= xpToAdvance(from: level) {
            remaining -= xpToAdvance(from: level)
            level += 1
        }
        return Status(level: level, xpIntoLevel: remaining, xpForNext: xpToAdvance(from: level))
    }

    private static let titles = [
        "Tourist", "Backpacker", "Traveler", "Explorer", "Navigator",
        "Voyager", "Diplomat", "Ambassador", "Cartographer", "Globetrotter", "World Master",
    ]

    /// A new title every 3 levels.
    public static func title(forLevel level: Int) -> String {
        titles[min(titles.count - 1, max(0, (level - 1) / 3))]
    }
}

/// What changed after a round, used to drive the results screen.
public struct RoundOutcome: Sendable {
    public let mode: RoundMode
    public let correct: Int
    public let total: Int
    public let bestCombo: Int
    public let answerXP: Int
    public let bonusXP: Int
    public let stars: Int
    public let previousStars: Int
    public let levelBefore: Leveling.Status
    public let levelAfter: Leveling.Status
    public let newlyMastered: [String]
    public let unlockedChapters: [String]
    public let isNewBest: Bool
    public let missed: [Country]

    public var totalXP: Int { answerXP + bonusXP }
    public var leveledUp: Bool { levelAfter.level > levelBefore.level }
}

public struct PlayerProgress: Codable, Equatable, Sendable {
    public var totalXP = 0
    public var stageStars: [String: Int] = [:]
    public var flagStats: [String: FlagStat] = [:]
    public var blitzBest = 0
    public var dailyScores: [String: Int] = [:]
    public var lastPlayedDay: String?
    public var streak = 0
    public var bestStreak = 0
    public var roundsPlayed = 0

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case totalXP, stageStars, flagStats, blitzBest, dailyScores, lastPlayedDay, streak, bestStreak, roundsPlayed
    }

    /// Tolerates missing keys so saves survive new fields being added.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalXP = try c.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        stageStars = try c.decodeIfPresent([String: Int].self, forKey: .stageStars) ?? [:]
        flagStats = try c.decodeIfPresent([String: FlagStat].self, forKey: .flagStats) ?? [:]
        blitzBest = try c.decodeIfPresent(Int.self, forKey: .blitzBest) ?? 0
        dailyScores = try c.decodeIfPresent([String: Int].self, forKey: .dailyScores) ?? [:]
        lastPlayedDay = try c.decodeIfPresent(String.self, forKey: .lastPlayedDay)
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        roundsPlayed = try c.decodeIfPresent(Int.self, forKey: .roundsPlayed) ?? 0
    }

    // MARK: Derived

    public var level: Leveling.Status { Leveling.status(forTotalXP: totalXP) }
    public var totalStars: Int { stageStars.values.reduce(0, +) }
    public var masteredCount: Int { flagStats.values.filter(\.isMastered).count }
    public var seenCount: Int { flagStats.values.filter { $0.seen > 0 }.count }

    public func stars(for stage: Stage) -> Int { stageStars[stage.id] ?? 0 }

    public func isUnlocked(_ chapter: Chapter) -> Bool { totalStars >= chapter.requiredStars }

    public func isUnlocked(_ stage: Stage) -> Bool {
        guard let chapter = Campaign.chapter(stage.chapterID), isUnlocked(chapter) else { return false }
        guard stage.number > 1 else { return true }
        return (stageStars[chapter.stages[stage.number - 2].id] ?? 0) > 0
    }

    /// The stage the big "Play" button should launch.
    public var nextStage: Stage {
        let unlocked = Campaign.stages.filter { isUnlocked($0) }
        if let fresh = unlocked.first(where: { stars(for: $0) == 0 }) { return fresh }
        if let imperfect = unlocked.first(where: { stars(for: $0) < 3 }) { return imperfect }
        return unlocked.last ?? Campaign.stages[0]
    }

    /// Streak as it should be shown today (drops to 0 once a day is missed).
    public func currentStreak(at date: Date, calendar: Calendar = .current) -> Int {
        guard let last = lastPlayedDay else { return 0 }
        let today = DayKey.key(for: date, calendar: calendar)
        let yesterday = DayKey.yesterday(of: date, calendar: calendar)
        return last == today || last == yesterday ? streak : 0
    }

    public func hasPlayedToday(at date: Date, calendar: Calendar = .current) -> Bool {
        lastPlayedDay == DayKey.key(for: date, calendar: calendar)
    }

    /// Flags to drill in Review mode: due ones first, then the weakest.
    public func reviewCodes(at date: Date, limit: Int = 10, calendar: Calendar = .current) -> [String] {
        flagStats
            .filter { ($0.value.seen > 0 && !$0.value.isMastered) || $0.value.isDue(at: date, calendar: calendar) }
            .sorted { a, b in
                let dueA = a.value.isDue(at: date, calendar: calendar), dueB = b.value.isDue(at: date, calendar: calendar)
                if dueA != dueB { return dueA }
                if a.value.box != b.value.box { return a.value.box < b.value.box }
                return a.key < b.key
            }
            .prefix(limit)
            .map { $0.key }
    }

    public func reviewDueCount(at date: Date, calendar: Calendar = .current) -> Int {
        flagStats.values.filter { $0.isDue(at: date, calendar: calendar) }.count
    }

    // MARK: Applying a round

    @discardableResult
    public mutating func apply(_ round: Round, at date: Date, calendar: Calendar = .current) -> RoundOutcome {
        let levelBefore = level
        let unlockedBefore = Set(Campaign.chapters.filter { isUnlocked($0) }.map(\.id))
        let masteredBefore = Set(flagStats.filter { $0.value.isMastered }.map { $0.key })

        for answer in round.answers {
            flagStats[answer.question.answer.code, default: FlagStat()].record(correct: answer.isCorrect, at: date)
        }

        let correct = round.correctCount
        let total = round.answers.count
        var stars = 0
        var previousStars = 0
        var bonus = 0
        var isNewBest = false

        switch round.mode {
        case .stage(let id):
            previousStars = stageStars[id] ?? 0
            stars = Campaign.stars(correct: correct, total: total)
            if stars > previousStars { stageStars[id] = stars }
            bonus = stars * 10 + (previousStars == 0 && stars > 0 ? 25 : 0)
        case .blitz:
            isNewBest = correct > blitzBest
            blitzBest = max(blitzBest, correct)
        case .daily(let key):
            if dailyScores[key] == nil { bonus = 30 }
            isNewBest = correct > (dailyScores[key] ?? -1)
            dailyScores[key] = max(dailyScores[key] ?? 0, correct)
        case .review:
            bonus = total > 0 ? 15 : 0
        }

        totalXP += round.xp + bonus
        roundsPlayed += 1
        updateStreak(at: date, calendar: calendar)

        let missed = round.answers.filter { !$0.isCorrect }.map(\.question.answer)
        var uniqueMissed: [Country] = []
        for c in missed where !uniqueMissed.contains(c) { uniqueMissed.append(c) }

        return RoundOutcome(
            mode: round.mode,
            correct: correct,
            total: total,
            bestCombo: round.bestCombo,
            answerXP: round.xp,
            bonusXP: bonus,
            stars: stars,
            previousStars: previousStars,
            levelBefore: levelBefore,
            levelAfter: level,
            newlyMastered: flagStats.filter { $0.value.isMastered && !masteredBefore.contains($0.key) }.map { $0.key }.sorted(),
            unlockedChapters: Campaign.chapters.filter { isUnlocked($0) && !unlockedBefore.contains($0.id) }.map(\.id),
            isNewBest: isNewBest,
            missed: uniqueMissed
        )
    }

    private mutating func updateStreak(at date: Date, calendar: Calendar) {
        let today = DayKey.key(for: date, calendar: calendar)
        guard lastPlayedDay != today else { return }
        streak = lastPlayedDay == DayKey.yesterday(of: date, calendar: calendar) ? streak + 1 : 1
        bestStreak = max(bestStreak, streak)
        lastPlayedDay = today
    }
}
