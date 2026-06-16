import Foundation

struct AdminCashAdjustment: Decodable, Identifiable {
    let id: Int
    let cashEntryId: Int
    let adminId: Int
    let adminName: String?
    let adjustedAmount: Double
    let reason: String?
    let cashAccountType: String?
    let showroomName: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case cashEntryId      = "cash_entry_id"
        case dailyCashEntryId = "daily_cash_entry_id"
        case adminId          = "admin_id"
        case admin
        case adjustedAmount   = "adjusted_amount"
        case reason
        case cashAccountType  = "cash_account_type"
        case showroomName     = "showroom_name"
        case createdAt        = "created_at"
    }

    private struct NameNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(Int.self, forKey: .id)
        adminId   = try c.decode(Int.self, forKey: .adminId)
        reason    = try? c.decode(String.self, forKey: .reason)
        createdAt = try? c.decode(String.self, forKey: .createdAt)
        adminName = (try? c.decode(NameNested.self, forKey: .admin))?.name
        cashAccountType = try? c.decode(String.self, forKey: .cashAccountType)
        showroomName = try? c.decode(String.self, forKey: .showroomName)

        cashEntryId = (try? c.decode(Int.self, forKey: .cashEntryId))
            ?? (try? c.decode(Int.self, forKey: .dailyCashEntryId)) ?? 0

        let raw = try c.decode(AnyCodable.self, forKey: .adjustedAmount)
        adjustedAmount = Double("\(raw.value)") ?? 0
    }
}

struct AdminCardAdjustment: Decodable, Identifiable {
    let id: Int
    let cardEntryId: Int
    let adminId: Int
    let adminName: String?
    let adjustedAmount: Double
    let reason: String?
    let createdAt: String?
    let bankName: String?
    let lastFour: String?
    let showroomName: String?

    var accountLabel: String {
        if let b = bankName, let l = lastFour { return "\(b) •••• \(l)" }
        return "Entry #\(cardEntryId)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case cardEntryId      = "card_entry_id"
        case dailyCardEntryId = "daily_card_entry_id"
        case adminId          = "admin_id"
        case admin
        case adjustedAmount   = "adjusted_amount"
        case reason
        case createdAt        = "created_at"
        case bankName         = "bank_name"
        case lastFour         = "last_four"
        case showroomName     = "showroom_name"
    }

    private struct NameNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(Int.self, forKey: .id)
        adminId   = try c.decode(Int.self, forKey: .adminId)
        reason    = try? c.decode(String.self, forKey: .reason)
        createdAt = try? c.decode(String.self, forKey: .createdAt)
        adminName = (try? c.decode(NameNested.self, forKey: .admin))?.name
        bankName  = try? c.decode(String.self, forKey: .bankName)
        lastFour  = try? c.decode(String.self, forKey: .lastFour)
        showroomName = try? c.decode(String.self, forKey: .showroomName)

        cardEntryId = (try? c.decode(Int.self, forKey: .cardEntryId))
            ?? (try? c.decode(Int.self, forKey: .dailyCardEntryId)) ?? 0

        let raw = try c.decode(AnyCodable.self, forKey: .adjustedAmount)
        adjustedAmount = Double("\(raw.value)") ?? 0
    }
}
