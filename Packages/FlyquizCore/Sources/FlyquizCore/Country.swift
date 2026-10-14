import Foundation

public enum Region: String, Codable, CaseIterable, Sendable {
    case europe, asia, africa, northAmerica, southAmerica, oceania

    public var displayName: String {
        switch self {
        case .europe: return "Europe"
        case .asia: return "Asia"
        case .africa: return "Africa"
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .oceania: return "Oceania"
        }
    }
}

public struct Country: Hashable, Codable, Identifiable, Sendable {
    /// ISO 3166-1 alpha-2 code, e.g. "FR".
    public let code: String
    public let name: String
    public let region: Region
    /// 1 = everyone knows it … 5 = obscure.
    public let tier: Int
    /// Emoji flag built from regional indicator symbols. Rendered by the OS, so no image assets.
    public let flag: String

    public var id: String { code }

    public init(code: String, name: String, region: Region, tier: Int) {
        self.code = code
        self.name = name
        self.region = region
        self.tier = tier
        self.flag = Country.emojiFlag(for: code)
    }

    public static func emojiFlag(for code: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in code.uppercased().unicodeScalars {
            if let indicator = UnicodeScalar(127_397 + scalar.value) {
                scalars.append(indicator)
            }
        }
        return String(scalars)
    }
}
