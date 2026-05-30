import Foundation

@MainActor
final class AuditLogViewModel: ObservableObject {
    @Published var logs: [AuditLog] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMore = true

    private var page = 1
    private let api = APIService.shared

    func fetchAll(tableName: String? = nil, action: String? = nil,
                  userId: Int? = nil, refresh: Bool = false) async {
        if refresh { page = 1; logs = []; hasMore = true }
        guard hasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": page]
        if let t = tableName { q["table_name"] = t }
        if let a = action    { q["action"] = a }
        if let u = userId    { q["user_id"] = u }
        do {
            let resp: PaginatedResponse<AuditLog> = try await api.get("/audit-logs", query: q)
            let cur  = resp.meta?.currentPage ?? page
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore = cur < last
            if refresh { logs = resp.data } else { logs += resp.data }
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
