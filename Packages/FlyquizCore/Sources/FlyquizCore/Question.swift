import Foundation

public enum QuestionKind: String, Codable, Sendable {
    /// Show a flag, pick the country name.
    case flagToName
    /// Show a country name, pick the flag.
    case nameToFlag
}

public struct Question: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: QuestionKind
    public let answer: Country
    public let options: [Country]

    public init(id: UUID = UUID(), kind: QuestionKind, answer: Country, options: [Country]) {
        self.id = id
        self.kind = kind
        self.answer = answer
        self.options = options
    }
}

public enum QuestionFactory {
    /// - Parameter difficulty: 1…4. Higher means more lookalike and same-region distractors.
    public static func make<R: RandomNumberGenerator>(
        answer: Country,
        kind: QuestionKind,
        difficulty: Int,
        pool: [Country] = Countries.all,
        using rng: inout R
    ) -> Question {
        var chosen: [Country] = []
        var used: Set<String> = [answer.code]

        /// Adds up to `limit` unused candidates, never exceeding three distractors in total.
        func take(from candidates: [Country], limit: Int) {
            var added = 0
            for c in candidates.shuffled(using: &rng) {
                guard chosen.count < 3, added < limit else { return }
                guard !used.contains(c.code) else { continue }
                chosen.append(c)
                used.insert(c.code)
                added += 1
            }
        }

        let lookalikeCount: Int
        switch difficulty {
        case ...1: lookalikeCount = Int.random(in: 0...2, using: &rng) == 0 ? 1 : 0
        case 2: lookalikeCount = 1
        case 3: lookalikeCount = 2
        default: lookalikeCount = 3
        }

        let similar = Lookalikes.similar(to: answer.code)
        let lookalikes = pool.filter { similar.contains($0.code) }
        take(from: lookalikes, limit: lookalikeCount)

        // Same-region distractors; at higher difficulty prefer countries of a similar tier.
        var sameRegion = pool.filter { $0.region == answer.region }
        if difficulty >= 3 {
            let close = sameRegion.filter { abs($0.tier - answer.tier) <= 1 }
            if close.count >= 4 { sameRegion = close }
        }
        take(from: sameRegion, limit: difficulty <= 1 ? 2 : 3)
        take(from: pool, limit: 3)
        take(from: Countries.all, limit: 3)

        let options = (chosen + [answer]).shuffled(using: &rng)
        return Question(kind: kind, answer: answer, options: options)
    }
}
