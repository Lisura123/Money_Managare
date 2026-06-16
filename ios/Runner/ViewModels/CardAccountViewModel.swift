import Foundation

@MainActor
final class CardAccountViewModel: ObservableObject {
    @Published var accounts: [CardAccount] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchAll(showroomId: Int? = nil) async {
        isLoading = true; error = nil
        var q: [String: Any] = [:]
        if let s = showroomId { q["showroom_id"] = s }
        do {
            let result: [CardAccount] = try await api.get("/card-accounts", query: q)
            accounts = result
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    /// Staff endpoint — returns accounts for the staff's assigned showroom(s).
    /// Pass `showroomId` to scope to a single assigned showroom.
    func fetchMyAccounts(showroomId: Int? = nil) async {
        isLoading = true; error = nil
        var q: [String: Any] = [:]
        if let s = showroomId { q["showroom_id"] = s }
        do {
            let result: [CardAccount] = try await api.get("/my-card-accounts", query: q)
            accounts = result
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func create(showroomId: Int, bankName: String, lastFour: String,
                currentBalance: Double, isActive: Bool) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        let body: [String: Any] = [
            "showroom_id": showroomId, "bank_name": bankName,
            "last_four": lastFour, "current_balance": currentBalance,
            "is_active": isActive
        ]
        let new: CardAccount = try await api.post("/card-accounts", body: body)
        accounts.append(new)
    }

    func update(_ id: Int, showroomId: Int, bankName: String, lastFour: String,
                currentBalance: Double, isActive: Bool, reason: String? = nil) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [
            "showroom_id": showroomId, "bank_name": bankName,
            "last_four": lastFour, "current_balance": currentBalance,
            "is_active": isActive
        ]
        if let r = reason { body["reason"] = r }
        let updated: CardAccount = try await api.put("/card-accounts/\(id)", body: body)
        if let idx = accounts.firstIndex(where: { $0.id == id }) {
            accounts[idx] = updated
        }
    }

    func delete(_ id: Int) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/card-accounts/\(id)")
        accounts.removeAll { $0.id == id }
    }
}
