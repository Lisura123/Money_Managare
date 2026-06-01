import Foundation

@MainActor
final class CashTransactionViewModel: ObservableObject {
    @Published var transactions: [CashTransaction] = []
    @Published var externalAccounts: [ExternalAccount] = []
    @Published var mainCashBalance: Double = 0
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
            let resp: PaginatedResponse<CashTransaction> = try await api.get("/cash-transactions", query: q)
            let cur  = resp.meta?.currentPage ?? page
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore = cur < last
            if refresh { transactions = resp.data } else { transactions += resp.data }
            page += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func fetchExternalAccounts() async {
        do {
            externalAccounts = try await api.get("/external-accounts")
        } catch { self.error = error.localizedDescription }
    }

    func fetchMainCashBalance() async {
        do {
            let summary: DashboardSummary = try await api.get("/admin/dashboard-summary")
            mainCashBalance = summary.today.cashMainAdjusted
        } catch { /* silently ignore */ }
    }

    func create(fromAccountType: String, toAccountType: String?,
                toExternalAccountId: Int?, amount: Double,
                notes: String?, transactionDate: String) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [
            "from_account_type": fromAccountType,
            "amount": amount,
            "transaction_date": transactionDate
        ]
        if let t = toAccountType         { body["to_account_type"] = t }
        if let e = toExternalAccountId   { body["to_external_account_id"] = e }
        if let n = notes, !n.isEmpty     { body["notes"] = n }
        let new: CashTransaction = try await api.post("/cash-transactions", body: body)
        transactions.insert(new, at: 0)
    }

    func delete(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/cash-transactions/\(id)")
        transactions.removeAll { $0.id == id }
    }

    func bulkDelete(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/cash-transactions/bulk-delete", body: ["ids": ids])
        transactions.removeAll { ids.contains($0.id) }
    }
}
