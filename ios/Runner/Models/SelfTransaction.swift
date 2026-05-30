import Foundation

struct SelfTransaction: Decodable, Identifiable {
    let id: Int
    let fromCardAccountId: Int
    let fromBankName: String?
    let fromLastFour: String?
    let fromShowroomName: String?
    let toCardAccountId: Int?
    let toBankName: String?
    let toLastFour: String?
    let toShowroomName: String?
    let amount: Double
    let notes: String?
    let adminId: Int
    let adminName: String?
    let createdAt: String?

    var fromDisplay: String {
        let parts = [fromShowroomName, fromBankName.map { "\($0) •••• \(fromLastFour ?? "")" }]
        return parts.compactMap { $0 }.joined(separator: " — ")
    }

    var toDisplay: String {
        let parts = [toShowroomName, toBankName.map { "\($0) •••• \(toLastFour ?? "")" }]
        return parts.compactMap { $0 }.joined(separator: " — ")
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case fromCardAccountId  = "from_card_account_id"
        case fromCardAccount    = "from_card_account"
        case toCardAccountId    = "to_card_account_id"
        case toCardAccount      = "to_card_account"
        case amount, notes
        case adminId   = "admin_id"
        case admin
        case createdAt = "created_at"
    }

    private struct CardNested: Decodable {
        let bankName: String?
        let lastFour: String?
        let showroom: ShowroomNested?
        struct ShowroomNested: Decodable { let name: String? }
        enum CodingKeys: String, CodingKey {
            case bankName = "bank_name"
            case lastFour = "last_four"
            case showroom
        }
    }
    private struct NameNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(Int.self, forKey: .id)
        fromCardAccountId = try c.decode(Int.self, forKey: .fromCardAccountId)
        toCardAccountId   = try? c.decode(Int.self, forKey: .toCardAccountId)
        adminId           = try c.decode(Int.self, forKey: .adminId)
        notes             = try? c.decode(String.self, forKey: .notes)
        createdAt         = try? c.decode(String.self, forKey: .createdAt)

        let from = try? c.decode(CardNested.self, forKey: .fromCardAccount)
        fromBankName     = from?.bankName
        fromLastFour     = from?.lastFour
        fromShowroomName = from?.showroom?.name

        let to = try? c.decode(CardNested.self, forKey: .toCardAccount)
        toBankName     = to?.bankName
        toLastFour     = to?.lastFour
        toShowroomName = to?.showroom?.name

        adminName = (try? c.decode(NameNested.self, forKey: .admin))?.name

        let amtRaw = try c.decode(AnyCodable.self, forKey: .amount)
        amount = Double("\(amtRaw.value)") ?? 0
    }
}
