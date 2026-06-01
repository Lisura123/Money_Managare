import Foundation

@MainActor
final class StaffViewModel: ObservableObject {
    @Published var staffList: [User] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchAll(showroomId: Int? = nil) async {
        isLoading = true; error = nil
        var q: [String: Any] = [:]
        if let s = showroomId { q["showroom_id"] = s }
        do {
            staffList = try await api.get("/staff", query: q)
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func create(name: String, email: String, password: String,
                role: String, showroomId: Int?, isActive: Bool) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [
            "name": name, "email": email,
            "password": password, "role": role, "is_active": isActive
        ]
        if let s = showroomId { body["showroom_id"] = s }
        struct CreateResponse: Decodable { let data: User }
        let resp: CreateResponse = try await api.post("/staff", body: body)
        staffList.append(resp.data)
    }

    func update(_ id: Int, name: String, email: String, role: String, showroomId: Int?,
                isActive: Bool, password: String?) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = ["name": name, "email": email, "role": role, "is_active": isActive]
        if let s = showroomId { body["showroom_id"] = s }
        if let p = password, !p.isEmpty { body["password"] = p }
        let updated: User = try await api.put("/staff/\(id)", body: body)
        if let idx = staffList.firstIndex(where: { $0.id == id }) { staffList[idx] = updated }
    }

    func toggleActive(_ id: Int) async throws {
        let updated: User = try await api.patch("/staff/\(id)/toggle-active")
        if let idx = staffList.firstIndex(where: { $0.id == id }) {
            staffList[idx] = updated
        }
    }

    func delete(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/staff/\(id)")
        staffList.removeAll { $0.id == id }
    }

    func bulkDelete(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/staff/bulk-delete", body: ["ids": ids])
        staffList.removeAll { ids.contains($0.id) }
    }
}

// Convenience memberwise init for User (not Decodable path)
extension User {
    init(id: Int, name: String, email: String, role: String,
         isActive: Bool, showroomId: Int?, showroomName: String?, createdAt: String?) {
        self.id           = id
        self.name         = name
        self.email        = email
        self.role         = role
        self.isActive     = isActive
        self.showroomId   = showroomId
        self.showroomName = showroomName
        self.createdAt    = createdAt
    }
}
