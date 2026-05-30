import Foundation

@MainActor
final class ShowroomViewModel: ObservableObject {
    @Published var showrooms: [Showroom] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchAll() async {
        isLoading = true; error = nil
        do {
            let result: [Showroom] = try await api.get("/showrooms")
            showrooms = result
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func create(name: String, location: String?, isActive: Bool) async throws {
        isSubmitting = true
        defer { isSubmitting = false }
        var body: [String: Any] = ["name": name, "is_active": isActive]
        if let l = location, !l.isEmpty { body["location"] = l }
        let new: Showroom = try await api.post("/showrooms", body: body)
        showrooms.append(new)
    }

    func update(_ id: Int, name: String, location: String?, isActive: Bool) async throws {
        isSubmitting = true
        defer { isSubmitting = false }
        var body: [String: Any] = ["name": name, "is_active": isActive]
        if let l = location { body["location"] = l }
        let updated: Showroom = try await api.put("/showrooms/\(id)", body: body)
        if let idx = showrooms.firstIndex(where: { $0.id == id }) {
            showrooms[idx] = updated
        }
    }

    func delete(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/showrooms/\(id)")
        showrooms.removeAll { $0.id == id }
    }
}
