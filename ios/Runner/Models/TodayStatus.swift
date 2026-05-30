import Foundation

struct CardEntryStatus: Codable, Identifiable {
    let id: Int
    let amount: Double
    let bankName: String?
    let lastFour: String?

    private enum CodingKeys: String, CodingKey {
        case id, amount
        case bankName = "bank_name"
        case lastFour = "last_four"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(Int.self, forKey: .id)
        bankName = try? c.decode(String.self, forKey: .bankName)
        lastFour = try? c.decode(String.self, forKey: .lastFour)
        let raw  = try c.decode(AnyCodable.self, forKey: .amount)
        amount   = Double("\(raw.value)") ?? 0
    }
}

struct CashEntryStatus: Codable {
    let submitted: Bool
    let amount: Double?
    let entryId: Int?

    private enum CodingKeys: String, CodingKey {
        case submitted, amount
        case entryId = "entry_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        submitted = try c.decode(Bool.self, forKey: .submitted)
        entryId   = try? c.decode(Int.self, forKey: .entryId)
        if let raw = try? c.decode(AnyCodable.self, forKey: .amount) {
            amount = Double("\(raw.value)")
        } else { amount = nil }
    }
}

struct CardStatusToday: Codable {
    let count: Int
    let total: Double
    let entries: [CardEntryStatus]

    private enum CodingKeys: String, CodingKey {
        case count, total, entries
    }

    init(from decoder: Decoder) throws {
        let c   = try decoder.container(keyedBy: CodingKeys.self)
        count   = try c.decode(Int.self, forKey: .count)
        entries = (try? c.decode([CardEntryStatus].self, forKey: .entries)) ?? []
        let raw = try c.decode(AnyCodable.self, forKey: .total)
        total   = Double("\(raw.value)") ?? 0
    }
}

struct TodayStatus: Codable {
    let date: String
    let mainCash: CashEntryStatus
    let manoCash: CashEntryStatus
    let card: CardStatusToday

    private enum CodingKeys: String, CodingKey {
        case date
        case mainCash = "main_cash"
        case manoCash = "mano_cash"
        case card
    }
}
