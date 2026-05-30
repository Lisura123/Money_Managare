import Foundation

struct ExternalAccount: Codable, Identifiable {
    let id: Int
    let name: String
    let balance: Double
    let cashAccountType: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, balance
        case cashAccountType = "cash_account_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(Int.self, forKey: .id)
        name            = try c.decode(String.self, forKey: .name)
        cashAccountType = try? c.decode(String.self, forKey: .cashAccountType)
        let raw         = try c.decode(AnyCodable.self, forKey: .balance)
        balance         = Double("\(raw.value)") ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,      forKey: .id)
        try c.encode(name,    forKey: .name)
        try c.encode(balance, forKey: .balance)
        try c.encodeIfPresent(cashAccountType, forKey: .cashAccountType)
    }
}
