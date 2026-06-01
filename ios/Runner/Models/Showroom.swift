import Foundation

struct Showroom: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let location: String?
    let isActive: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, location
        case isActive  = "is_active"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(Int.self, forKey: .id)
        name     = try c.decode(String.self, forKey: .name)
        location = try? c.decode(String.self, forKey: .location)
        if let b = try? c.decode(Bool.self, forKey: .isActive) {
            isActive = b
        } else {
            isActive = (try? c.decode(Int.self, forKey: .isActive)) == 1
        }
        createdAt = try? c.decode(String.self, forKey: .createdAt)
    }
}
