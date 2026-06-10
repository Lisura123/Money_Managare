import Foundation

@MainActor
final class CashEntryViewModel: ObservableObject {
    @Published var entries: [DailyCashEntry] = []
    @Published var myHistory: [DailyCashEntry] = []
    @Published var adjustments: [AdminCashAdjustment] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var totalAmount: Double = 0
    @Published var totalEntries: Int = 0
    @Published var hasMore = true
    @Published var historyHasMore = true
    @Published var mainCashBalance: Double = 0
    @Published var manoCashBalance: Double = 0

    private var entriesPage = 1
    private var historyPage = 1
    private let api = APIService.shared

    // MARK: - Admin entries

    func fetchEntries(showroomId: Int? = nil, date: String? = nil,
                      from: String? = nil, to: String? = nil,
                      cashAccountType: String? = nil,
                      refresh: Bool = false) async {
        if refresh { entriesPage = 1; entries = []; hasMore = true }
        guard hasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": entriesPage]
        if let s = showroomId       { q["showroom_id"] = s }
        if let d = date             { q["date"] = d }
        if let f = from             { q["from"] = f }
        if let t = to               { q["to"] = t }
        if let c = cashAccountType  { q["cash_account_type"] = c }

        do {
            let resp: PaginatedResponse<DailyCashEntry> = try await api.get("/cash-entries", query: q)
            let meta = resp.meta
            let cur  = meta?.currentPage ?? entriesPage
            let last = meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore      = cur < last
            totalEntries = meta?.total ?? resp.data.count
            totalAmount  = meta?.totalAmount ?? resp.data.reduce(0) { $0 + $1.cashAmount }
            if refresh { entries = resp.data } else { entries += resp.data }
            entriesPage += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Staff history

    func fetchMyHistory(cashAccountType: String? = nil, from: String? = nil, to: String? = nil,
                        search: String? = nil, refresh: Bool = false) async {
        if refresh { historyPage = 1; myHistory = []; historyHasMore = true }
        guard historyHasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": historyPage]
        if let c = cashAccountType { q["cash_account_type"] = c }
        if let f = from   { q["from"] = f }
        if let t = to     { q["to"] = t }
        if let s = search, !s.isEmpty { q["search"] = s }

        do {
            let resp: PaginatedResponse<DailyCashEntry> = try await api.get("/cash-entries/my-history", query: q)
            let cur  = resp.meta?.currentPage ?? historyPage
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            historyHasMore = cur < last
            if refresh { myHistory = resp.data } else { myHistory += resp.data }
            historyPage += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Submit (staff)

    func submit(showroomId: Int, cashAmount: Double, notes: String?,
                cashAccountType: String, entryDate: String? = nil) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [
            "showroom_id": showroomId,
            "cash_amount": cashAmount,
            "cash_account_type": cashAccountType
        ]
        if let n = notes, !n.isEmpty { body["notes"] = n }
        if let d = entryDate { body["entry_date"] = d }
        let _: DailyCashEntry = try await api.post("/cash-entries", body: body)
    }

    func update(_ id: Int, cashAmount: Double, notes: String?) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = ["cash_amount": cashAmount]
        if let n = notes { body["notes"] = n }
        let updated: DailyCashEntry = try await api.put("/cash-entries/\(id)", body: body)
        replace(updated, in: &entries)
        replace(updated, in: &myHistory)
    }

    // MARK: - Adjustments

    func fetchAdjustments(date: String? = nil, from: String? = nil, to: String? = nil) async {
        var q: [String: Any] = [:]
        if let d = date { q["date"] = d }
        if let f = from { q["from"] = f }
        if let t = to   { q["to"]   = t }
        do {
            let resp: PaginatedResponse<AdminCashAdjustment> = try await api.get("/adjustments/cash", query: q)
            adjustments = resp.data
        } catch { self.error = error.localizedDescription }
    }

    func fetchCashBalances() async {
        async let summaryTask: DashboardSummary = api.get("/admin/dashboard-summary")
        async let accountsTask: [ExternalAccount] = api.get("/external-accounts")
        do {
            let (summary, accounts) = try await (summaryTask, accountsTask)
            mainCashBalance = summary.today.cashMainAdjusted
            manoCashBalance = accounts.first(where: { $0.cashAccountType == "mano" })?.balance
                ?? summary.today.cashManoAdjusted
        } catch { /* silently ignore */ }
    }

    func createAdjustment(adjustedAmount: Double, reason: String, cashAccountType: String, showroomId: Int? = nil) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [
            "adjusted_amount": adjustedAmount,
            "reason": reason,
            "cash_account_type": cashAccountType
        ]
        if let sid = showroomId { body["showroom_id"] = sid }
        let new: AdminCashAdjustment = try await api.post("/adjustments/cash", body: body)
        adjustments.insert(new, at: 0)
    }

    func deleteEntry(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/cash-entries/\(id)")
        entries.removeAll { $0.id == id }
    }

    func deleteAdjustment(_ id: Int) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.delete("/adjustments/cash/\(id)")
        adjustments.removeAll { $0.id == id }
    }

    func bulkDeleteEntries(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/cash-entries/bulk-delete", body: ["ids": ids])
        entries.removeAll { ids.contains($0.id) }
    }

    func bulkDeleteAdjustments(_ ids: [Int]) async throws {
        struct Msg: Decodable { let message: String }
        let _: Msg = try await api.post("/adjustments/cash/bulk-delete", body: ["ids": ids])
        adjustments.removeAll { ids.contains($0.id) }
    }

    // MARK: - Helpers

    private func replace(_ entry: DailyCashEntry, in list: inout [DailyCashEntry]) {
        if let idx = list.firstIndex(where: { $0.id == entry.id }) { list[idx] = entry }
    }
}
