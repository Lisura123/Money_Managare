import Foundation

struct CardAccount: Decodable, Identifiable {
    let id: Int
    let showroomId: Int
    let showroomName: String?
    let bankName: String
    let lastFour: String
    let currentBalance: Double
    let isActive: Bool
    let createdAt: String?

    var maskedNumber: String { "•••• \(lastFour)" }
    var displayLabel: String { "\(bankName) •••• \(lastFour)" }

    func dropdownLabel(_ sName: String?) -> String {
        "\(sName ?? showroomName ?? "") — \(bankName) •••• \(lastFour)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case showroomId      = "showroom_id"
        case showroom
        case bankName        = "bank_name"
        case lastFour        = "last_four"
        case currentBalance  = "current_balance"
        case isActive        = "is_active"
        case createdAt       = "created_at"
    }

    // Nested showroom object for showroomName
    private struct ShowroomNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(Int.self, forKey: .id)
        showroomId    = try c.decode(Int.self, forKey: .showroomId)
        bankName      = try c.decode(String.self, forKey: .bankName)
        lastFour      = try c.decode(String.self, forKey: .lastFour)
        createdAt     = try? c.decode(String.self, forKey: .createdAt)

        let balStr    = try c.decode(AnyCodable.self, forKey: .currentBalance)
        currentBalance = Double("\(balStr.value)") ?? 0

        if let b = try? c.decode(Bool.self, forKey: .isActive) {
            isActive = b
        } else {
            isActive = (try? c.decode(Int.self, forKey: .isActive)) == 1
        }
        showroomName = (try? c.decode(ShowroomNested.self, forKey: .showroom))?.name
    }
}
