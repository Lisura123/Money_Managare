import Foundation

struct DailyCardEntry: Decodable, Identifiable {
    let id: Int
    let showroomId: Int
    let showroomName: String?
    let userId: Int
    let userName: String?
    let cardAccountId: Int
    let bankName: String?
    let lastFour: String?
    let entryDate: String
    let amount: Double
    let notes: String?
    let isLocked: Bool
    let createdAt: String?
    let updatedAt: String?

    var displayCard: String {
        guard let b = bankName, let l = lastFour else { return "Card" }
        return "\(b) •••• \(l)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case showroomId    = "showroom_id"
        case showroom
        case userId        = "user_id"
        case user
        case cardAccountId = "card_account_id"
        case cardAccount   = "card_account"
        case entryDate     = "entry_date"
        case amount, notes
        case isLocked      = "is_locked"
        case createdAt     = "created_at"
        case updatedAt     = "updated_at"
    }

    private struct NameNested: Decodable { let name: String }
    private struct CardNested: Decodable {
        let bankName: String?
        let lastFour: String?
        enum CodingKeys: String, CodingKey {
            case bankName = "bank_name"
            case lastFour = "last_four"
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(Int.self, forKey: .id)
        showroomId    = try c.decode(Int.self, forKey: .showroomId)
        userId        = try c.decode(Int.self, forKey: .userId)
        cardAccountId = try c.decode(Int.self, forKey: .cardAccountId)
        entryDate     = try c.decode(String.self, forKey: .entryDate)
        notes         = try? c.decode(String.self, forKey: .notes)
        createdAt     = try? c.decode(String.self, forKey: .createdAt)
        updatedAt     = try? c.decode(String.self, forKey: .updatedAt)

        showroomName = (try? c.decode(NameNested.self, forKey: .showroom))?.name
        userName     = (try? c.decode(NameNested.self, forKey: .user))?.name

        let card = try? c.decode(CardNested.self, forKey: .cardAccount)
        bankName = card?.bankName
        lastFour = card?.lastFour

        let amtRaw = try c.decode(AnyCodable.self, forKey: .amount)
        amount = Double("\(amtRaw.value)") ?? 0

        if let b = try? c.decode(Bool.self, forKey: .isLocked) {
            isLocked = b
        } else {
            isLocked = (try? c.decode(Int.self, forKey: .isLocked)) == 1
        }
    }
}
