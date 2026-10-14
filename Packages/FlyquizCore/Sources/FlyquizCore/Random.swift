import Foundation

/// Deterministic RNG so the Daily challenge is identical for everyone on a given day.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public init(string: String) {
        // FNV-1a: stable across launches (unlike `hashValue`).
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        state = hash
    }

    // SplitMix64
    public mutating func next() -> UInt64 {
        state = state &+ 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }
}

public enum DayKey {
    public static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public static func yesterday(of date: Date, calendar: Calendar = .current) -> String {
        key(for: calendar.date(byAdding: .day, value: -1, to: date) ?? date, calendar: calendar)
    }
}
