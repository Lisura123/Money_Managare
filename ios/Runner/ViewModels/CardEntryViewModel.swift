import Foundation

@MainActor
final class CardEntryViewModel: ObservableObject {
    @Published var entries: [DailyCardEntry] = []
    @Published var myHistory: [DailyCardEntry] = []
    @Published var adjustments: [AdminCardAdjustment] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var totalAmount: Double = 0
    @Published var totalEntries: Int = 0
    @Published var hasMore = true
    @Published var historyHasMore = true

    private var entriesPage = 1
    private var historyPage = 1
    private let api = APIService.shared

    func fetchEntries(showroomId: Int? = nil, cardAccountId: Int? = nil,
                      date: String? = nil, from: String? = nil, to: String? = nil,
                      refresh: Bool = false) async {
        if refresh { entriesPage = 1; entries = []; hasMore = true }
        guard hasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": entriesPage]
        if let s = showroomId    { q["showroom_id"] = s }
        if let c = cardAccountId { q["card_account_id"] = c }
        if let d = date          { q["date"] = d }
        if let f = from          { q["from"] = f }
        if let t = to            { q["to"] = t }

        do {
            let resp: PaginatedResponse<DailyCardEntry> = try await api.get("/card-entries", query: q)
            let meta = resp.meta
            let cur  = meta?.currentPage ?? entriesPage
            let last = meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            hasMore      = cur < last
            totalEntries = meta?.total ?? resp.data.count
            totalAmount  = meta?.totalAmount ?? resp.data.reduce(0) { $0 + $1.amount }
            if refresh { entries = resp.data } else { entries += resp.data }
            entriesPage += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func fetchMyHistory(from: String? = nil, to: String? = nil,
                        search: String? = nil, refresh: Bool = false) async {
        if refresh { historyPage = 1; myHistory = []; historyHasMore = true }
        guard historyHasMore else { return }
        isLoading = true; error = nil
        var q: [String: Any] = ["page": historyPage]
        if let f = from   { q["from"] = f }
        if let t = to     { q["to"] = t }
        if let s = search, !s.isEmpty { q["search"] = s }
        do {
            let resp: PaginatedResponse<DailyCardEntry> = try await api.get("/card-entries/my-history", query: q)
            let cur  = resp.meta?.currentPage ?? historyPage
            let last = resp.meta?.lastPage ?? (resp.data.isEmpty ? cur : cur + 1)
            historyHasMore = cur < last
            if refresh { myHistory = resp.data } else { myHistory += resp.data }
            historyPage += 1
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func submit(showroomId: Int, cardAccountId: Int, amount: Double, notes: String?,
                entryDate: String? = nil) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = [
            "showroom_id": showroomId,
            "card_account_id": cardAccountId,
            "amount": amount
        ]
        if let n = notes, !n.isEmpty { body["notes"] = n }
        if let d = entryDate { body["entry_date"] = d }
        let _: DailyCardEntry = try await api.post("/card-entries", body: body)
    }

    func update(_ id: Int, amount: Double, notes: String?) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        var body: [String: Any] = ["amount": amount]
        if let n = notes { body["notes"] = n }
        let updated: DailyCardEntry = try await api.put("/card-entries/\(id)", body: body)
        if let idx = entries.firstIndex(where: { $0.id == id }) { entries[idx] = updated }
        if let idx = myHistory.firstIndex(where: { $0.id == id }) { myHistory[idx] = updated }
    }

    func fetchAdjustments(cardAccountId: Int? = nil) async {
        var q: [String: Any] = [:]
        if let c = cardAccountId { q["card_account_id"] = c }
        do {
            adjustments = try await api.get("/adjustments/card", query: q)
        } catch { self.error = error.localizedDescription }
    }

    func createAdjustment(cardEntryId: Int, adjustedAmount: Double, reason: String?) async throws {
        var body: [String: Any] = ["card_entry_id": cardEntryId, "adjusted_amount": adjustedAmount]
        if let r = reason, !r.isEmpty { body["reason"] = r }
        let new: AdminCardAdjustment = try await api.post("/adjustments/card", body: body)
        adjustments.append(new)
    }
}
