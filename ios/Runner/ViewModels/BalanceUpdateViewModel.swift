import Foundation

@MainActor
final class BalanceUpdateViewModel: ObservableObject {
    @Published var updates: [BalanceUpdate] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMore = true

    private var page = 1
    private let api = APIService.shared

    func fetchAll(date: String? = nil, from: String? = nil, to: String? = nil,
                  showroomId: Int? = nil, accountType: String? = nil,
                  refresh: Bool = false) async {
        if refresh { page = 1; updates = []; hasMore = true }
        guard hasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": page]
        if let d = date         { q["date"]         = d }
        if let f = from         { q["from"]         = f }
        if let t = to           { q["to"]           = t }
        if let s = showroomId   { q["showroom_id"]  = s }
        if let a = accountType  { q["account_type"] = a }
        do {
            let resp: PaginatedResponse<BalanceUpdate> = try await api.get("/balance-updates", query: q)
            let cur  = resp.meta?.currentPage ?? page
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore = cur < last
            if refresh { updates = resp.data } else { updates += resp.data }
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func delete(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/balance-updates/\(id)")
        updates.removeAll { $0.id == id }
    }

    func bulkDelete(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/balance-updates/bulk-delete", body: ["ids": ids])
        updates.removeAll { ids.contains($0.id) }
    }
}
