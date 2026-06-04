import Foundation

extension Notification.Name {
    static let balancesDidChange = Notification.Name("balancesDidChange")
}

@MainActor
final class SelfTransactionViewModel: ObservableObject {
    @Published var transactions: [SelfTransaction] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var hasMore = true

    private var page = 1
    private let api = APIService.shared

    func fetchAll(refresh: Bool = false) async {
        if refresh { page = 1; transactions = []; hasMore = true }
        guard hasMore else { return }
        isLoading = true; error = nil
        let q: [String: Any] = ["page": page]
        do {
            let resp: PaginatedResponse<SelfTransaction> = try await api.get("/self-transactions", query: q)
            let cur  = resp.meta?.currentPage ?? page
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore = cur < last
            if refresh { transactions = resp.data } else { transactions += resp.data }
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func create(fromCardId: Int? = nil, fromExternalId: Int? = nil, fromAccType: String? = nil,
                toCardId: Int? = nil, toExternalId: Int? = nil, toAccType: String? = nil,
                amount: Double, notes: String?) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = ["amount": amount]
        if let c = fromCardId     { body["from_card_account_id"]     = c }
        if let e = fromExternalId { body["from_external_account_id"] = e }
        if let t = fromAccType    { body["from_account_type"]        = t }
        if let c = toCardId       { body["to_card_account_id"]       = c }
        if let e = toExternalId   { body["to_external_account_id"]   = e }
        if let t = toAccType      { body["to_account_type"]          = t }
        if let n = notes, !n.isEmpty { body["notes"] = n }
        let new: SelfTransaction = try await api.post("/self-transactions", body: body)
        transactions.insert(new, at: 0)
        NotificationCenter.default.post(name: .balancesDidChange, object: nil)
    }

    func delete(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/self-transactions/\(id)")
        transactions.removeAll { $0.id == id }
    }

    func bulkDelete(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/self-transactions/bulk-delete", body: ["ids": ids])
        transactions.removeAll { ids.contains($0.id) }
    }
}
