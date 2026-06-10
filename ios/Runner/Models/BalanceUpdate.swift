import Foundation

/// A manual Main Cash / Bank balance change recorded in the Records → Balance Updates section.
struct BalanceUpdate: Decodable, Identifiable {
    let id: Int
    let showroomId: Int?
    let showroomName: String?
    let accountType: String      // "main_cash" | "bank"
    let cardAccountId: Int?
    let accountLabel: String
    let previousAmount: Double
    let newAmount: Double
    let changeAmount: Double
    let reason: String?
    let userId: Int?
    let userName: String?
    let createdAt: String?

    /// Friendly label for the account category.
    var accountTypeLabel: String {
        switch accountType {
        case "main_cash": return "Main Cash"
        case "bank":      return "Bank Account"
        default:          return accountType.capitalized
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case showroomId     = "showroom_id"
        case showroomName   = "showroom_name"
        case accountType    = "account_type"
        case cardAccountId  = "card_account_id"
        case accountLabel   = "account_label"
        case previousAmount = "previous_amount"
        case newAmount      = "new_amount"
        case changeAmount   = "change_amount"
        case reason
        case userId         = "user_id"
        case userName       = "user_name"
        case createdAt      = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(Int.self, forKey: .id)
        showroomId    = try? c.decode(Int.self, forKey: .showroomId)
        showroomName  = try? c.decode(String.self, forKey: .showroomName)
        accountType   = (try? c.decode(String.self, forKey: .accountType)) ?? ""
        cardAccountId = try? c.decode(Int.self, forKey: .cardAccountId)
        accountLabel  = (try? c.decode(String.self, forKey: .accountLabel)) ?? ""
        reason        = try? c.decode(String.self, forKey: .reason)
        userId        = try? c.decode(Int.self, forKey: .userId)
        userName      = try? c.decode(String.self, forKey: .userName)
        createdAt     = try? c.decode(String.self, forKey: .createdAt)

        func amount(_ key: CodingKeys) -> Double {
            guard let raw = try? c.decode(AnyCodable.self, forKey: key) else { return 0 }
            return Double("\(raw.value)") ?? 0
        }
        previousAmount = amount(.previousAmount)
        newAmount      = amount(.newAmount)
        changeAmount   = amount(.changeAmount)
    }
}
