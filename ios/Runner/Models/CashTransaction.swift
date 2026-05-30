import Foundation

struct CashTransaction: Decodable, Identifiable {
    let id: Int
    let adminId: Int
    let adminName: String?
    let fromAccountType: String
    let fromLabel: String
    let toAccountType: String?
    let toLabel: String
    let toExternalAccountId: Int?
    let toExternalAccountName: String?
    let amount: Double
    let notes: String?
    let transactionDate: String
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case adminId             = "admin_id"
        case adminName           = "admin_name"
        case fromAccountType     = "from_account_type"
        case fromLabel           = "from_label"
        case toAccountType       = "to_account_type"
        case toLabel             = "to_label"
        case toExternalAccountId = "to_external_account_id"
        case toExternalAccount   = "to_external_account"
        case amount, notes
        case transactionDate     = "transaction_date"
        case createdAt           = "created_at"
    }

    private struct ExtNested: Decodable { let name: String? }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(Int.self, forKey: .id)
        adminId         = try c.decode(Int.self, forKey: .adminId)
        adminName       = try? c.decode(String.self, forKey: .adminName)
        fromAccountType = try c.decode(String.self, forKey: .fromAccountType)
        fromLabel       = (try? c.decode(String.self, forKey: .fromLabel)) ?? "Main Cash"
        toAccountType   = try? c.decode(String.self, forKey: .toAccountType)
        toLabel         = (try? c.decode(String.self, forKey: .toLabel)) ?? "Others (External)"
        toExternalAccountId = try? c.decode(Int.self, forKey: .toExternalAccountId)
        notes           = try? c.decode(String.self, forKey: .notes)
        transactionDate = try c.decode(String.self, forKey: .transactionDate)
        createdAt       = try? c.decode(String.self, forKey: .createdAt)

        toExternalAccountName = (try? c.decode(ExtNested.self, forKey: .toExternalAccount))?.name

        let amtRaw = try c.decode(AnyCodable.self, forKey: .amount)
        amount = Double("\(amtRaw.value)") ?? 0
    }
}
