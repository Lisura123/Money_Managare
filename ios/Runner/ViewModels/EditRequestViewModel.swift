import Foundation

@MainActor
final class EditRequestViewModel: ObservableObject {
    @Published var adminRequests: [EditRequest] = []
    @Published var myRequests: [EditRequest] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var hasMore = true
    @Published var myHasMore = true

    private var page = 1
    private var myPage = 1
    private let api = APIService.shared

    // MARK: - Admin

    func fetchAdminRequests(status: String? = nil, refresh: Bool = false) async {
        if refresh { page = 1; adminRequests = []; hasMore = true }
        guard hasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": page]
        if let s = status { q["status"] = s }
        do {
            let resp: PaginatedResponse<EditRequest> = try await api.get("/edit-requests", query: q)
            let cur  = resp.meta?.currentPage ?? page
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore = cur < last
            if refresh { adminRequests = resp.data } else { adminRequests += resp.data }
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func review(_ id: Int, action: String, remarks: String?) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [:]
        if let r = remarks, !r.isEmpty { body["admin_remarks"] = r }
        let updated: EditRequest
        if action == "approve" {
            updated = try await api.put("/edit-requests/\(id)/approve", body: body)
        } else {
            updated = try await api.put("/edit-requests/\(id)/reject", body: body)
        }
        if let idx = adminRequests.firstIndex(where: { $0.id == id }) { adminRequests[idx] = updated }
    }

    // MARK: - Staff

    func fetchMyRequests(refresh: Bool = false) async {
        if refresh { myPage = 1; myRequests = []; myHasMore = true }
        guard myHasMore else { return }
        isLoading = true; error = nil
        let q: [String: Any] = ["page": myPage]
        do {
            let resp: PaginatedResponse<EditRequest> = try await api.get("/edit-requests/my-requests", query: q)
            let cur  = resp.meta?.currentPage ?? myPage
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            myHasMore = cur < last
            if refresh { myRequests = resp.data } else { myRequests += resp.data }
            myPage += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func submitCashEditRequest(cashEntryId: Int, changes: [String: Any], reason: String) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        let body: [String: Any] = [
            "entry_type": "cash", "entry_id": cashEntryId,
            "requested_changes": changes, "reason": reason
        ]
        let new: EditRequest = try await api.post("/edit-requests", body: body)
        myRequests.insert(new, at: 0)
    }

    func submitCardEditRequest(cardEntryId: Int, changes: [String: Any], reason: String) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        let body: [String: Any] = [
            "entry_type": "card", "entry_id": cardEntryId,
            "requested_changes": changes, "reason": reason
        ]
        let new: EditRequest = try await api.post("/edit-requests", body: body)
        myRequests.insert(new, at: 0)
    }

    func cancel(_ id: Int) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/edit-requests/\(id)")
        myRequests.removeAll { $0.id == id }
    }

    // MARK: - Pending count (admin)

    @Published var pendingCount: Int = 0

    func fetchPendingCount() async {
        struct CountResp: Decodable { let count: Int }
        if let resp: CountResp = try? await api.get("/edit-requests/pending-count") {
            pendingCount = resp.count
        }
    }
}
