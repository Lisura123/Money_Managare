import Foundation

struct DailyCashEntry: Decodable, Identifiable {
    let id: Int
    let showroomId: Int
    let showroomName: String?
    let userId: Int
    let userName: String?
    let entryDate: String
    let cashAmount: Double
    let notes: String?
    let isLocked: Bool
    let cashAccountType: String
    let cashAccountLabel: String
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case showroomId        = "showroom_id"
        case showroom
        case userId            = "user_id"
        case user
        case entryDate         = "entry_date"
        case cashAmount        = "cash_amount"
        case notes
        case isLocked          = "is_locked"
        case cashAccountType   = "cash_account_type"
        case cashAccountLabel  = "cash_account_label"
        case createdAt         = "created_at"
        case updatedAt         = "updated_at"
    }

    private struct NameNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(Int.self, forKey: .id)
        showroomId  = try c.decode(Int.self, forKey: .showroomId)
        userId      = try c.decode(Int.self, forKey: .userId)
        entryDate   = try c.decode(String.self, forKey: .entryDate)
        notes       = try? c.decode(String.self, forKey: .notes)
        createdAt   = try? c.decode(String.self, forKey: .createdAt)
        updatedAt   = try? c.decode(String.self, forKey: .updatedAt)

        showroomName = (try? c.decode(NameNested.self, forKey: .showroom))?.name
        userName     = (try? c.decode(NameNested.self, forKey: .user))?.name

        let amtRaw = try c.decode(AnyCodable.self, forKey: .cashAmount)
        cashAmount = Double("\(amtRaw.value)") ?? 0

        if let b = try? c.decode(Bool.self, forKey: .isLocked) {
            isLocked = b
        } else {
            isLocked = (try? c.decode(Int.self, forKey: .isLocked)) == 1
        }

        let typeRaw  = (try? c.decode(String.self, forKey: .cashAccountType)) ?? "main"
        cashAccountType  = typeRaw
        cashAccountLabel = (try? c.decode(String.self, forKey: .cashAccountLabel))
            ?? (typeRaw == "mano" ? "Mano's Account" : "Main Account")
    }
}
