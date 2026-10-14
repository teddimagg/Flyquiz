import Foundation

public struct Stage: Identifiable, Hashable, Sendable {
    public let id: String
    public let chapterID: String
    /// 1-based position within its chapter.
    public let number: Int
    /// Flags introduced in this stage.
    public let countryCodes: [String]
    /// Flags from earlier stages in the chapter, mixed in for review.
    public let reviewCodes: [String]
    public let questionCount: Int
    public let nameToFlagRatio: Double
    public let difficulty: Int

    public var countries: [Country] { countryCodes.compactMap(Countries.country) }
}

public struct Chapter: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let emoji: String
    public let requiredStars: Int
    public let stages: [Stage]

    public var maxStars: Int { stages.count * 3 }
}

public enum Campaign {
    public static let chapters: [Chapter] = build()

    public static let stages: [Stage] = chapters.flatMap(\.stages)

    private static let stageIndex: [String: Stage] = Dictionary(uniqueKeysWithValues: stages.map { ($0.id, $0) })

    public static func stage(_ id: String) -> Stage? { stageIndex[id] }

    public static func chapter(_ id: String) -> Chapter? { chapters.first { $0.id == id } }

    /// The stage after `stage` in campaign order, crossing chapter boundaries.
    public static func stage(after stage: Stage) -> Stage? {
        guard let i = stages.firstIndex(of: stage), i + 1 < stages.count else { return nil }
        return stages[i + 1]
    }

    public static let starsPerStage = 3

    /// 3 stars for a perfect run, 2 for ≥80 %, 1 for ≥60 %.
    public static func stars(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let accuracy = Double(correct) / Double(total)
        if correct == total { return 3 }
        if accuracy >= 0.8 { return 2 }
        if accuracy >= 0.6 { return 1 }
        return 0
    }

    // MARK: - Building

    private static func build() -> [Chapter] {
        let starterCodes = Countries.all.filter { $0.tier == 1 }.map(\.code)
        let starter = Set(starterCodes)

        func regional(_ regions: [Region]) -> [String] {
            Countries.all
                .filter { regions.contains($0.region) && !starter.contains($0.code) }
                .sorted { ($0.tier, $0.name) < ($1.tier, $1.name) }
                .map(\.code)
        }

        var chapters: [Chapter] = []
        chapters.append(chapter(id: "starter", title: "First Flight", subtitle: "The flags everyone should know",
                                emoji: "✈️", stars: 0, codes: starterCodes, chunk: 6, baseDifficulty: 1))
        chapters.append(chapter(id: "europe", title: "Europe", subtitle: "Crosses, tricolors and micro-states",
                                emoji: "🏰", stars: 4, codes: regional([.europe]), chunk: 7, baseDifficulty: 2))
        chapters.append(chapter(id: "americas", title: "The Americas", subtitle: "From the Arctic to Patagonia",
                                emoji: "🌎", stars: 12, codes: regional([.northAmerica, .southAmerica]), chunk: 7, baseDifficulty: 2))
        chapters.append(chapter(id: "asia", title: "Asia", subtitle: "Suns, moons and stars",
                                emoji: "🏯", stars: 22, codes: regional([.asia]), chunk: 7, baseDifficulty: 2))
        chapters.append(chapter(id: "africa", title: "Africa", subtitle: "Pan-African colors everywhere",
                                emoji: "🦁", stars: 34, codes: regional([.africa]), chunk: 7, baseDifficulty: 2))
        chapters.append(chapter(id: "oceania", title: "Oceania", subtitle: "Islands of the Pacific",
                                emoji: "🏝️", stars: 48, codes: regional([.oceania]), chunk: 6, baseDifficulty: 3))
        chapters.append(lookalikeChapter(stars: 62))
        return chapters
    }

    private static func chapter(id: String, title: String, subtitle: String, emoji: String, stars: Int,
                                codes: [String], chunk: Int, baseDifficulty: Int) -> Chapter {
        let groups = evenChunks(codes, target: chunk)
        var seen: [String] = []
        var stages: [Stage] = []
        for (i, group) in groups.enumerated() {
            let progress = groups.count > 1 ? Double(i) / Double(groups.count - 1) : 0
            stages.append(Stage(
                id: "\(id)-\(i + 1)",
                chapterID: id,
                number: i + 1,
                countryCodes: group,
                reviewCodes: seen,
                questionCount: 10,
                nameToFlagRatio: progress < 0.34 ? 0 : (progress < 0.67 ? 0.25 : 0.4),
                difficulty: min(4, baseDifficulty + Int(progress * 2))
            ))
            seen += group
        }
        return Chapter(id: id, title: title, subtitle: subtitle, emoji: emoji, requiredStars: stars, stages: stages)
    }

    private static func lookalikeChapter(stars: Int) -> Chapter {
        // Bundle the confusable groups into stages of roughly 8 flags.
        var buckets: [[String]] = [[]]
        for group in Lookalikes.groups {
            if buckets[buckets.count - 1].count + group.count > 9 { buckets.append([]) }
            for code in group where !buckets[buckets.count - 1].contains(code) {
                buckets[buckets.count - 1].append(code)
            }
        }
        let stages = buckets.enumerated().map { i, codes in
            Stage(id: "lookalikes-\(i + 1)", chapterID: "lookalikes", number: i + 1,
                  countryCodes: codes, reviewCodes: [], questionCount: 10,
                  nameToFlagRatio: 0.5, difficulty: 4)
        }
        return Chapter(id: "lookalikes", title: "Lookalikes", subtitle: "Spot the difference. For experts.",
                       emoji: "🔍", requiredStars: stars, stages: stages)
    }

    /// Splits into chunks of near-equal size close to `target`.
    static func evenChunks<T>(_ items: [T], target: Int) -> [[T]] {
        guard !items.isEmpty else { return [] }
        let count = max(1, Int((Double(items.count) / Double(target)).rounded()))
        let base = items.count / count
        let extra = items.count % count
        var result: [[T]] = []
        var start = 0
        for i in 0..<count {
            let size = base + (i < extra ? 1 : 0)
            result.append(Array(items[start..<start + size]))
            start += size
        }
        return result
    }
}
