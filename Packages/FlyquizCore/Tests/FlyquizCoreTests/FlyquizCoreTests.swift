import XCTest
@testable import FlyquizCore

final class CountriesTests: XCTestCase {
    func testAllCountriesParsedAndUnique() {
        XCTAssertEqual(Countries.all.count, 197)
        XCTAssertEqual(Set(Countries.all.map(\.code)).count, Countries.all.count)
        XCTAssertEqual(Set(Countries.all.map(\.name)).count, Countries.all.count)
        XCTAssertTrue(Countries.all.allSatisfy { (1...5).contains($0.tier) && $0.code.count == 2 })
    }

    func testEmojiFlag() {
        XCTAssertEqual(Country.emojiFlag(for: "IS"), "🇮🇸")
        XCTAssertEqual(Countries.country("JP")?.flag, "🇯🇵")
    }

    func testLookalikeCodesExist() {
        for code in Lookalikes.groups.flatMap({ $0 }) {
            XCTAssertNotNil(Countries.country(code), "Unknown lookalike code \(code)")
        }
        XCTAssertTrue(Lookalikes.similar(to: "TD").contains("RO"))
    }
}

final class QuestionTests: XCTestCase {
    func testQuestionsHaveFourDistinctOptionsIncludingAnswer() {
        var rng = SeededGenerator(seed: 42)
        for difficulty in 1...4 {
            for country in Countries.all {
                let q = QuestionFactory.make(answer: country, kind: .flagToName, difficulty: difficulty, using: &rng)
                XCTAssertEqual(q.options.count, 4)
                XCTAssertEqual(Set(q.options).count, 4)
                XCTAssertTrue(q.options.contains(country))
            }
        }
    }

    func testHardQuestionsUseLookalikes() {
        var rng = SeededGenerator(seed: 1)
        let chad = Countries.country("TD")!
        let q = QuestionFactory.make(answer: chad, kind: .flagToName, difficulty: 4, using: &rng)
        XCTAssertTrue(q.options.contains { $0.code == "RO" })
    }

    func testSeededGeneratorIsDeterministic() {
        var a = SeededGenerator(string: "2026-10-14")
        var b = SeededGenerator(string: "2026-10-14")
        XCTAssertEqual((0..<5).map { _ in a.next() }, (0..<5).map { _ in b.next() })
    }
}

final class CampaignTests: XCTestCase {
    func testEveryCountryAppearsInExactlyOneRegularStage() {
        let regular = Campaign.chapters.filter { $0.id != "lookalikes" }.flatMap(\.stages).flatMap(\.countryCodes)
        XCTAssertEqual(regular.count, Countries.all.count)
        XCTAssertEqual(Set(regular), Set(Countries.all.map(\.code)))
    }

    func testStageIDsUniqueAndChaptersGatedIncreasingly() {
        XCTAssertEqual(Set(Campaign.stages.map(\.id)).count, Campaign.stages.count)
        let required = Campaign.chapters.map(\.requiredStars)
        XCTAssertEqual(required, required.sorted())
        XCTAssertEqual(required.first, 0)
        // Each chapter must be reachable with the stars available before it.
        var available = 0
        for chapter in Campaign.chapters {
            XCTAssertLessThanOrEqual(chapter.requiredStars, available, chapter.id)
            available += chapter.maxStars
        }
    }

    func testStageRoundsHaveTenQuestionsWithoutBackToBackRepeats() {
        var rng = SeededGenerator(seed: 7)
        for stage in Campaign.stages {
            let round = RoundBuilder.stage(stage, using: &rng)
            XCTAssertEqual(round.questions.count, stage.questionCount, stage.id)
            let introduced = Set(round.questions.map(\.answer.code))
            XCTAssertTrue(Set(stage.countryCodes).isSubset(of: introduced), stage.id)
        }
    }

    func testStars() {
        XCTAssertEqual(Campaign.stars(correct: 10, total: 10), 3)
        XCTAssertEqual(Campaign.stars(correct: 8, total: 10), 2)
        XCTAssertEqual(Campaign.stars(correct: 6, total: 10), 1)
        XCTAssertEqual(Campaign.stars(correct: 5, total: 10), 0)
    }

    func testEvenChunks() {
        let chunks = Campaign.evenChunks(Array(0..<41), target: 7)
        XCTAssertEqual(chunks.map(\.count).reduce(0, +), 41)
        XCTAssertLessThanOrEqual((chunks.map(\.count).max() ?? 0) - (chunks.map(\.count).min() ?? 0), 1)
    }
}

final class RoundTests: XCTestCase {
    func testComboAndXP() {
        var rng = SeededGenerator(seed: 3)
        var round = RoundBuilder.stage(Campaign.stages[0], using: &rng)
        for _ in 0..<3 { round.answer(round.current!.answer, responseTime: 1) }
        XCTAssertEqual(round.combo, 3)
        let wrong = round.current!.options.first { $0 != round.current!.answer }!
        round.answer(wrong, responseTime: 1)
        XCTAssertEqual(round.combo, 0)
        XCTAssertEqual(round.bestCombo, 3)
        // 15 + 17 + 19 for the three fast correct answers
        XCTAssertEqual(round.xp, 51)
    }

    func testDailyIsSameForEveryone() {
        let a = RoundBuilder.daily(dayKey: "2026-10-14")
        let b = RoundBuilder.daily(dayKey: "2026-10-14")
        XCTAssertEqual(a.questions.map(\.answer), b.questions.map(\.answer))
        XCTAssertEqual(a.questions.map(\.options), b.questions.map(\.options))
        XCTAssertEqual(a.questions.count, 10)
    }

    func testBlitzFinishDropsUnanswered() {
        var rng = SeededGenerator(seed: 9)
        var round = RoundBuilder.blitz(using: &rng)
        round.answer(round.current!.answer, responseTime: 1)
        round.finish()
        XCTAssertTrue(round.isFinished)
        XCTAssertEqual(round.questions.count, 1)
    }
}

final class ProgressTests: XCTestCase {
    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 12))!
    }

    func perfectRound(_ stage: Stage) -> Round {
        var rng = SeededGenerator(seed: 5)
        var round = RoundBuilder.stage(stage, using: &rng)
        while let q = round.current { round.answer(q.answer, responseTime: 1) }
        return round
    }

    func testLeveling() {
        XCTAssertEqual(Leveling.status(forTotalXP: 0).level, 1)
        XCTAssertEqual(Leveling.status(forTotalXP: 149).level, 1)
        XCTAssertEqual(Leveling.status(forTotalXP: 150).level, 2)
        XCTAssertEqual(Leveling.status(forTotalXP: 350).level, 3)
        XCTAssertEqual(Leveling.title(forLevel: 1), "Tourist")
    }

    func testApplyingAStageAwardsStarsAndUnlocksNext() {
        var progress = PlayerProgress()
        let first = Campaign.stages[0]
        let second = Campaign.stages[1]
        XCTAssertTrue(progress.isUnlocked(first))
        XCTAssertFalse(progress.isUnlocked(second))

        let outcome = progress.apply(perfectRound(first), at: date(14), calendar: calendar)
        XCTAssertEqual(outcome.stars, 3)
        XCTAssertGreaterThan(outcome.bonusXP, 0)
        XCTAssertTrue(progress.isUnlocked(second))
        XCTAssertEqual(progress.nextStage, second)
        XCTAssertEqual(progress.streak, 1)

        // A worse replay never lowers stars.
        var rng = SeededGenerator(seed: 1)
        var bad = RoundBuilder.stage(first, using: &rng)
        while let q = bad.current { bad.answer(q.options.first { $0 != q.answer }!, responseTime: 1) }
        progress.apply(bad, at: date(14), calendar: calendar)
        XCTAssertEqual(progress.stars(for: first), 3)
    }

    func testStreak() {
        var progress = PlayerProgress()
        progress.apply(perfectRound(Campaign.stages[0]), at: date(10), calendar: calendar)
        progress.apply(perfectRound(Campaign.stages[0]), at: date(11), calendar: calendar)
        progress.apply(perfectRound(Campaign.stages[0]), at: date(11), calendar: calendar)
        XCTAssertEqual(progress.streak, 2)
        XCTAssertEqual(progress.currentStreak(at: date(12), calendar: calendar), 2)
        XCTAssertEqual(progress.currentStreak(at: date(13), calendar: calendar), 0)
        progress.apply(perfectRound(Campaign.stages[0]), at: date(14), calendar: calendar)
        XCTAssertEqual(progress.streak, 1)
        XCTAssertEqual(progress.bestStreak, 2)
    }

    func testMasteryAndReview() {
        var stat = FlagStat()
        for _ in 0..<4 { stat.record(correct: true, at: date(1)) }
        XCTAssertTrue(stat.isMastered)
        stat.record(correct: false, at: date(1))
        XCTAssertEqual(stat.box, 1)
        XCTAssertTrue(stat.isDue(at: date(1), calendar: calendar))

        var progress = PlayerProgress()
        progress.flagStats["FR"] = stat
        XCTAssertEqual(progress.reviewCodes(at: date(2), calendar: calendar), ["FR"])
    }

    func testDecodingToleratesMissingKeys() throws {
        let decoded = try JSONDecoder().decode(PlayerProgress.self, from: Data(#"{"totalXP": 42}"#.utf8))
        XCTAssertEqual(decoded.totalXP, 42)
        XCTAssertEqual(decoded.streak, 0)
    }

    func testRoundTripEncoding() throws {
        var progress = PlayerProgress()
        progress.apply(perfectRound(Campaign.stages[0]), at: date(14), calendar: calendar)
        let data = try JSONEncoder().encode(progress)
        XCTAssertEqual(try JSONDecoder().decode(PlayerProgress.self, from: data), progress)
    }
}
