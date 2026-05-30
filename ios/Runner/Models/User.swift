import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let role: String
    let isActive: Bool
    let showroomId: Int?
    let showroomName: String?
    let createdAt: String?

    var isAdmin: Bool { role == "admin" }
    var isStaff: Bool { role == "staff" }

    var initials: String {
        let parts = name.trimmingCharacters(in: .whitespaces).split(separator: " ")
        if parts.count >= 2, let f = parts.first?.first, let l = parts.last?.first {
            return "\(f)\(l)".uppercased()
        }
        return name.isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id, name, email, role
        case isActive     = "is_active"
        case showroomId   = "showroom_id"
        case showroom
        case createdAt    = "created_at"
    }

    private struct ShowroomNested: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id   = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        email = try c.decode(String.self, forKey: .email)
        role  = try c.decode(String.self, forKey: .role)
        // is_active can arrive as Bool or Int
        if let b = try? c.decode(Bool.self, forKey: .isActive) {
            isActive = b
        } else if let i = try? c.decode(Int.self, forKey: .isActive) {
            isActive = i == 1
        } else {
            isActive = false
        }
        showroomId   = try? c.decode(Int.self, forKey: .showroomId)
        showroomName = (try? c.decode(ShowroomNested.self, forKey: .showroom))?.name
        createdAt    = try? c.decode(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(name,      forKey: .name)
        try c.encode(email,     forKey: .email)
        try c.encode(role,      forKey: .role)
        try c.encode(isActive,  forKey: .isActive)
        try c.encodeIfPresent(showroomId, forKey: .showroomId)
        try c.encodeIfPresent(createdAt,  forKey: .createdAt)
    }
}
