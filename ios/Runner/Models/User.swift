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

    /// All showrooms this user is assigned to (multi-showroom support).
    let showrooms: [Showroom]
    /// Convenience list of assigned showroom IDs.
    var showroomIds: [Int] { showrooms.map(\.id) }
    /// True when the staff member is assigned to more than one showroom and
    /// must therefore pick a showroom before submitting an entry.
    var hasMultipleShowrooms: Bool { showroomIds.count > 1 }

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
        case showrooms
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
        showrooms    = (try? c.decode([Showroom].self, forKey: .showrooms)) ?? []
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
        try c.encode(showrooms, forKey: .showrooms)
        try c.encodeIfPresent(createdAt,  forKey: .createdAt)
    }
}
