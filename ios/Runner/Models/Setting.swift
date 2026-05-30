import Foundation

struct Setting: Codable, Identifiable {
    let id: Int
    let key: String
    let value: String
    let description: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, key, value, description
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(Int.self, forKey: .id)
        key         = try c.decode(String.self, forKey: .key)
        description = try? c.decode(String.self, forKey: .description)
        updatedAt   = try? c.decode(String.self, forKey: .updatedAt)
        // value can be String or Number
        if let s = try? c.decode(String.self, forKey: .value) {
            value = s
        } else if let i = try? c.decode(Int.self, forKey: .value) {
            value = "\(i)"
        } else {
            value = ""
        }
    }
}
