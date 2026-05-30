import Foundation

struct ReportSummary: Decodable {
    let from: String
    let to: String
    let cashMainTotal: Double
    let cashManoTotal: Double
    let cardTotal: Double
    let grandTotal: Double
    let cashMainAdjusted: Double
    let cashManoAdjusted: Double
    let cardAdjusted: Double
    let grandAdjusted: Double
    let perShowroom: [ShowroomSnapshot]

    private enum CodingKeys: String, CodingKey {
        case from, to
        case cashMainTotal    = "cash_main_total"
        case cashManoTotal    = "cash_mano_total"
        case cardTotal        = "card_total"
        case grandTotal       = "grand_total"
        case cashMainAdjusted = "cash_main_adjusted"
        case cashManoAdjusted = "cash_mano_adjusted"
        case cardAdjusted     = "card_adjusted"
        case grandAdjusted    = "grand_adjusted"
        case perShowroom      = "per_showroom"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.from  = try c.decode(String.self, forKey: .from)
        self.to    = try c.decode(String.self, forKey: .to)
        perShowroom = (try? c.decode([ShowroomSnapshot].self, forKey: .perShowroom)) ?? []

        func d(_ k: CodingKeys) -> Double {
            let raw = try? c.decode(AnyCodable.self, forKey: k)
            return raw.map { Double("\($0.value)") ?? 0 } ?? 0
        }
        cashMainTotal    = d(.cashMainTotal)
        cashManoTotal    = d(.cashManoTotal)
        cardTotal        = d(.cardTotal)
        grandTotal       = d(.grandTotal)
        cashMainAdjusted = d(.cashMainAdjusted)
        cashManoAdjusted = d(.cashManoAdjusted)
        cardAdjusted     = d(.cardAdjusted)
        grandAdjusted    = d(.grandAdjusted)
    }
}

@MainActor
final class ReportViewModel: ObservableObject {
    @Published var report: ReportSummary?
    @Published var isLoading = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchReport(from: String, to: String, showroomId: Int? = nil) async {
        isLoading = true; error = nil
        var q: [String: Any] = ["from": from, "to": to]
        if let s = showroomId { q["showroom_id"] = s }
        do {
            report = try await api.get("/admin/reports", query: q)
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
