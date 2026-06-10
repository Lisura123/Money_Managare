import Foundation

@MainActor
final class AdminUserViewModel: ObservableObject {
    @Published var admins: [User] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchAll() async {
        isLoading = true; error = nil
        do {
            admins = try await api.get("/admins")
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func create(name: String, email: String, password: String, isActive: Bool) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        let body: [String: Any] = ["name": name, "email": email, "password": password, "is_active": isActive]
        // Accept both `{ "data": User }` and a flat `User` response shape.
        struct CreateResponse: Decodable {
            let user: User
            private enum CodingKeys: String, CodingKey { case data }
            init(from decoder: Decoder) throws {
                if let container = try? decoder.container(keyedBy: CodingKeys.self),
                   let wrapped = try? container.decode(User.self, forKey: .data) {
                    user = wrapped
                } else {
                    user = try User(from: decoder)
                }
            }
        }
        let resp: CreateResponse = try await api.post("/admins", body: body)
        admins.append(resp.user)
    }

    func update(_ id: Int, name: String, email: String, isActive: Bool, password: String?) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = ["name": name, "email": email, "is_active": isActive]
        if let p = password, !p.isEmpty { body["password"] = p }
        let updated: User = try await api.put("/admins/\(id)", body: body)
        if let idx = admins.firstIndex(where: { $0.id == id }) { admins[idx] = updated }
    }

    func delete(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/admins/\(id)")
        admins.removeAll { $0.id == id }
    }

    func bulkDelete(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/admins/bulk-delete", body: ["ids": ids])
        admins.removeAll { ids.contains($0.id) }
    }

    func toggleActive(_ id: Int) async throws {
        let updated: User = try await api.patch("/admins/\(id)/toggle-active")
        if let idx = admins.firstIndex(where: { $0.id == id }) { admins[idx] = updated }
    }

    func changeRole(userId: Int, newRole: String, showroomId: Int?) async throws {
        struct ChangeRoleResponse: Decodable { let data: User }
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = ["role": newRole]
        if let sId = showroomId { body["showroom_id"] = sId }
        let resp: ChangeRoleResponse = try await api.patch("/users/\(userId)/change-role", body: body)
        // Remove from admins list if changed to staff
        if newRole == "staff" {
            admins.removeAll { $0.id == userId }
        } else if let idx = admins.firstIndex(where: { $0.id == userId }) {
            admins[idx] = resp.data
        }
    }
}
