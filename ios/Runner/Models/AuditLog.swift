import Foundation

struct AuditLog: Decodable, Identifiable {
    let id: Int
    let tableName: String
    let recordId: Int
    let action: String
    let oldValues: [String: AnyCodable]?
    let newValues: [String: AnyCodable]?
    let userId: Int?
    let userName: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case tableName  = "table_name"
        case recordId   = "record_id"
        case action
        case oldValues  = "old_values"
        case newValues  = "new_values"
        case userId     = "user_id"
        case user
        case createdAt  = "created_at"
    }

    private struct UserNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(Int.self, forKey: .id)
        tableName  = try c.decode(String.self, forKey: .tableName)
        recordId   = try c.decode(Int.self, forKey: .recordId)
        action     = try c.decode(String.self, forKey: .action)
        oldValues  = try? c.decode([String: AnyCodable].self, forKey: .oldValues)
        newValues  = try? c.decode([String: AnyCodable].self, forKey: .newValues)
        userId     = try? c.decode(Int.self, forKey: .userId)
        createdAt  = try? c.decode(String.self, forKey: .createdAt)
        userName   = (try? c.decode(UserNested.self, forKey: .user))?.name
    }
}
