import Foundation

public enum Countries {
    /// All 197 countries in the game, parsed once from a compact table (fast to compile, fast to load).
    public static let all: [Country] = parse(table)

    public static let byCode: [String: Country] = Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })

    public static func country(_ code: String) -> Country? { byCode[code] }

    public static func inRegion(_ region: Region) -> [Country] {
        all.filter { $0.region == region }
    }

    static func parse(_ table: String) -> [Country] {
        let regions: [String: Region] = [
            "eu": .europe, "as": .asia, "af": .africa,
            "na": .northAmerica, "sa": .southAmerica, "oc": .oceania,
        ]
        return table.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 4, let region = regions[parts[2]], let tier = Int(parts[3]) else { return nil }
            return Country(code: parts[0], name: parts[1], region: region, tier: tier)
        }
    }

    // code | name | region | tier (1 famous … 5 obscure)
    private static let table = """
    FR|France|eu|1
    DE|Germany|eu|1
    IT|Italy|eu|1
    ES|Spain|eu|1
    GB|United Kingdom|eu|1
    PT|Portugal|eu|2
    NL|Netherlands|eu|2
    SE|Sweden|eu|2
    CH|Switzerland|eu|2
    GR|Greece|eu|2
    IE|Ireland|eu|2
    NO|Norway|eu|2
    DK|Denmark|eu|2
    FI|Finland|eu|2
    PL|Poland|eu|2
    BE|Belgium|eu|2
    AT|Austria|eu|2
    UA|Ukraine|eu|2
    RU|Russia|eu|2
    IS|Iceland|eu|2
    CZ|Czechia|eu|3
    HU|Hungary|eu|3
    RO|Romania|eu|3
    HR|Croatia|eu|3
    RS|Serbia|eu|3
    BG|Bulgaria|eu|3
    SK|Slovakia|eu|3
    SI|Slovenia|eu|3
    LU|Luxembourg|eu|3
    MC|Monaco|eu|3
    MT|Malta|eu|3
    EE|Estonia|eu|3
    LV|Latvia|eu|3
    LT|Lithuania|eu|3
    BY|Belarus|eu|3
    AL|Albania|eu|4
    BA|Bosnia and Herzegovina|eu|4
    MK|North Macedonia|eu|4
    ME|Montenegro|eu|4
    MD|Moldova|eu|4
    AD|Andorra|eu|4
    LI|Liechtenstein|eu|4
    SM|San Marino|eu|4
    VA|Vatican City|eu|4
    XK|Kosovo|eu|4
    CY|Cyprus|eu|4
    CN|China|as|1
    JP|Japan|as|1
    IN|India|as|1
    KR|South Korea|as|1
    TR|Turkey|as|2
    SA|Saudi Arabia|as|2
    IL|Israel|as|2
    TH|Thailand|as|2
    VN|Vietnam|as|2
    ID|Indonesia|as|2
    PH|Philippines|as|2
    PK|Pakistan|as|2
    IR|Iran|as|2
    SG|Singapore|as|2
    MY|Malaysia|as|2
    AE|United Arab Emirates|as|2
    KP|North Korea|as|2
    IQ|Iraq|as|3
    AF|Afghanistan|as|3
    BD|Bangladesh|as|3
    NP|Nepal|as|3
    LK|Sri Lanka|as|3
    QA|Qatar|as|3
    KW|Kuwait|as|3
    JO|Jordan|as|3
    LB|Lebanon|as|3
    SY|Syria|as|3
    KZ|Kazakhstan|as|3
    MN|Mongolia|as|3
    KH|Cambodia|as|3
    MM|Myanmar|as|3
    TW|Taiwan|as|3
    GE|Georgia|as|3
    AM|Armenia|as|3
    AZ|Azerbaijan|as|4
    UZ|Uzbekistan|as|4
    TM|Turkmenistan|as|4
    KG|Kyrgyzstan|as|4
    TJ|Tajikistan|as|4
    LA|Laos|as|4
    BT|Bhutan|as|4
    MV|Maldives|as|4
    BN|Brunei|as|4
    OM|Oman|as|4
    YE|Yemen|as|4
    BH|Bahrain|as|4
    TL|Timor-Leste|as|4
    PS|Palestine|as|4
    ZA|South Africa|af|1
    EG|Egypt|af|1
    NG|Nigeria|af|2
    KE|Kenya|af|2
    MA|Morocco|af|2
    GH|Ghana|af|2
    ET|Ethiopia|af|2
    DZ|Algeria|af|2
    TN|Tunisia|af|2
    SN|Senegal|af|3
    CM|Cameroon|af|3
    CI|Ivory Coast|af|3
    TZ|Tanzania|af|3
    UG|Uganda|af|3
    LY|Libya|af|3
    SD|Sudan|af|3
    ZW|Zimbabwe|af|3
    AO|Angola|af|3
    MZ|Mozambique|af|3
    CD|DR Congo|af|3
    RW|Rwanda|af|3
    ML|Mali|af|3
    MG|Madagascar|af|3
    SO|Somalia|af|3
    ZM|Zambia|af|4
    BW|Botswana|af|4
    NA|Namibia|af|4
    NE|Niger|af|4
    TD|Chad|af|4
    BF|Burkina Faso|af|4
    BJ|Benin|af|4
    TG|Togo|af|4
    GN|Guinea|af|4
    SL|Sierra Leone|af|4
    LR|Liberia|af|4
    GA|Gabon|af|4
    CG|Congo|af|4
    CF|Central African Republic|af|4
    SS|South Sudan|af|4
    ER|Eritrea|af|4
    DJ|Djibouti|af|4
    MW|Malawi|af|4
    MR|Mauritania|af|4
    GM|Gambia|af|4
    GW|Guinea-Bissau|af|5
    GQ|Equatorial Guinea|af|5
    CV|Cape Verde|af|5
    ST|São Tomé and Príncipe|af|5
    KM|Comoros|af|5
    SC|Seychelles|af|5
    MU|Mauritius|af|5
    LS|Lesotho|af|5
    SZ|Eswatini|af|5
    BI|Burundi|af|5
    US|United States|na|1
    CA|Canada|na|1
    MX|Mexico|na|1
    CU|Cuba|na|2
    JM|Jamaica|na|2
    PA|Panama|na|3
    CR|Costa Rica|na|3
    DO|Dominican Republic|na|3
    HT|Haiti|na|3
    BS|Bahamas|na|3
    GT|Guatemala|na|3
    HN|Honduras|na|3
    SV|El Salvador|na|4
    NI|Nicaragua|na|4
    BZ|Belize|na|4
    TT|Trinidad and Tobago|na|4
    BB|Barbados|na|4
    AG|Antigua and Barbuda|na|5
    DM|Dominica|na|5
    GD|Grenada|na|5
    KN|Saint Kitts and Nevis|na|5
    LC|Saint Lucia|na|5
    VC|Saint Vincent and the Grenadines|na|5
    BR|Brazil|sa|1
    AR|Argentina|sa|1
    CL|Chile|sa|2
    CO|Colombia|sa|2
    PE|Peru|sa|2
    VE|Venezuela|sa|3
    UY|Uruguay|sa|3
    EC|Ecuador|sa|3
    BO|Bolivia|sa|3
    PY|Paraguay|sa|3
    GY|Guyana|sa|4
    SR|Suriname|sa|4
    AU|Australia|oc|1
    NZ|New Zealand|oc|1
    FJ|Fiji|oc|3
    PG|Papua New Guinea|oc|3
    WS|Samoa|oc|4
    TO|Tonga|oc|4
    VU|Vanuatu|oc|4
    SB|Solomon Islands|oc|4
    KI|Kiribati|oc|5
    MH|Marshall Islands|oc|5
    FM|Micronesia|oc|5
    PW|Palau|oc|5
    NR|Nauru|oc|5
    TV|Tuvalu|oc|5
    """
}

/// Flags that are easy to confuse. Used for harder distractors and the Lookalikes chapter.
public enum Lookalikes {
    public static let groups: [[String]] = [
        ["TD", "RO", "AD", "MD"],
        ["ID", "MC", "PL", "SG"],
        ["IE", "CI", "IT", "NG"],
        ["NL", "LU", "FR", "PY", "HR"],
        ["RU", "SK", "SI", "RS"],
        ["AU", "NZ", "FJ", "TV"],
        ["NO", "IS", "DK", "FI", "SE"],
        ["VE", "CO", "EC"],
        ["SN", "ML", "GN", "CM"],
        ["HN", "NI", "SV", "GT"],
        ["AR", "UY"],
        ["JO", "PS", "SD", "KW", "AE"],
        ["EG", "IQ", "SY", "YE"],
        ["QA", "BH"],
        ["AT", "LV", "LB"],
        ["HU", "BG", "IT", "IR", "TJ"],
        ["DE", "BE", "UG"],
        ["MY", "US", "LR"],
        ["BD", "JP", "PW"],
        ["TR", "TN"],
        ["NE", "IN"],
        ["ME", "AL"],
        ["CL", "CZ", "PH", "CU"],
        ["LT", "BO", "GH", "ET"],
        ["GA", "SL", "RW"],
        ["CD", "CG", "TZ"],
    ]

    private static let index: [String: Set<String>] = {
        var result: [String: Set<String>] = [:]
        for group in groups {
            for code in group {
                result[code, default: []].formUnion(group.filter { $0 != code })
            }
        }
        return result
    }()

    public static func similar(to code: String) -> Set<String> {
        index[code] ?? []
    }
}
