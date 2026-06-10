import Foundation

struct SelfTransaction: Decodable, Identifiable {
    let id: Int
    let fromCardAccountId: Int?
    let fromExternalAccountId: Int?
    let fromExternalName: String?
    let fromAccountType: String?
    let fromBankName: String?
    let fromLastFour: String?
    let fromShowroomName: String?
    let toCardAccountId: Int?
    let toExternalAccountId: Int?
    let toExternalName: String?
    let toAccountType: String?
    let toBankName: String?
    let toLastFour: String?
    let toShowroomName: String?
    let amount: Double
    let notes: String?
    let adminId: Int
    let adminName: String?
    let createdAt: String?

    var fromDisplay: String {
        if fromAccountType == "main" { return "Main Cash" }
        if let n = fromExternalName { return n }
        let parts = [fromShowroomName, fromBankName.map { "\($0) •••• \(fromLastFour ?? "")" }]
        let joined = parts.compactMap { $0 }.joined(separator: " — ")
        return joined.isEmpty ? "—" : joined
    }

    var toDisplay: String {
        if toAccountType == "main" { return "Main Cash" }
        if let n = toExternalName { return n }
        let parts = [toShowroomName, toBankName.map { "\($0) •••• \(toLastFour ?? "")" }]
        let joined = parts.compactMap { $0 }.joined(separator: " — ")
        return joined.isEmpty ? (notes.map { _ in "Others" } ?? "—") : joined
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case fromCardAccountId     = "from_card_account_id"
        case fromCardAccount       = "from_card_account"
        case fromExternalAccountId = "from_external_account_id"
        case fromExternalAccount   = "from_external_account"
        case fromAccountType       = "from_account_type"
        case toCardAccountId       = "to_card_account_id"
        case toCardAccount         = "to_card_account"
        case toExternalAccountId   = "to_external_account_id"
        case toExternalAccount     = "to_external_account"
        case toAccountType         = "to_account_type"
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
    private struct ExternalNested: Decodable {
        let name: String?
        enum CodingKeys: String, CodingKey { case name }
    }
    private struct NameNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                    = try c.decode(Int.self, forKey: .id)
        fromCardAccountId     = try? c.decode(Int.self, forKey: .fromCardAccountId)
        fromExternalAccountId = try? c.decode(Int.self, forKey: .fromExternalAccountId)
        fromAccountType       = try? c.decode(String.self, forKey: .fromAccountType)
        toCardAccountId       = try? c.decode(Int.self, forKey: .toCardAccountId)
        toExternalAccountId   = try? c.decode(Int.self, forKey: .toExternalAccountId)
        toAccountType         = try? c.decode(String.self, forKey: .toAccountType)
        adminId               = try c.decode(Int.self, forKey: .adminId)
        notes                 = try? c.decode(String.self, forKey: .notes)
        createdAt             = try? c.decode(String.self, forKey: .createdAt)

        let from = try? c.decode(CardNested.self, forKey: .fromCardAccount)
        fromBankName     = from?.bankName
        fromLastFour     = from?.lastFour
        fromShowroomName = from?.showroom?.name

        fromExternalName = (try? c.decode(ExternalNested.self, forKey: .fromExternalAccount))?.name

        let to = try? c.decode(CardNested.self, forKey: .toCardAccount)
        toBankName     = to?.bankName
        toLastFour     = to?.lastFour
        toShowroomName = to?.showroom?.name

        toExternalName = (try? c.decode(ExternalNested.self, forKey: .toExternalAccount))?.name

        adminName = (try? c.decode(NameNested.self, forKey: .admin))?.name

        let amtRaw = try c.decode(AnyCodable.self, forKey: .amount)
        amount = Double("\(amtRaw.value)") ?? 0
    }
}
