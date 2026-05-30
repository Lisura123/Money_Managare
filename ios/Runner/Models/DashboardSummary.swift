import Foundation

struct ShowroomSnapshot: Codable, Identifiable {
    var id: Int { showroomId }
    let showroomId: Int
    let showroomName: String
    let cashMainTotal: Double
    let cashManoTotal: Double
    let cardTotal: Double
    let combinedTotal: Double
    let cashMainAdjusted: Double
    let cashManoAdjusted: Double
    let cardAdjusted: Double
    let entryCount: Int

    private enum CodingKeys: String, CodingKey {
        case showroomId      = "showroom_id"
        case showroomName    = "showroom_name"
        case cashMainTotal   = "cash_main_total"
        case cashManoTotal   = "cash_mano_total"
        case cardTotal       = "card_total"
        case combinedTotal   = "combined_total"
        case cashMainAdjusted  = "cash_main_adjusted"
        case cashManoAdjusted  = "cash_mano_adjusted"
        case cardAdjusted    = "card_adjusted"
        case entryCount      = "entry_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        showroomId   = try c.decode(Int.self, forKey: .showroomId)
        showroomName = try c.decode(String.self, forKey: .showroomName)
        entryCount   = (try? c.decode(Int.self, forKey: .entryCount)) ?? 0

        func d(_ k: CodingKeys) -> Double {
            let raw = try? c.decode(AnyCodable.self, forKey: k)
            return raw.map { Double("\($0.value)") ?? 0 } ?? 0
        }
        cashMainTotal    = d(.cashMainTotal)
        cashManoTotal    = d(.cashManoTotal)
        cardTotal        = d(.cardTotal)
        combinedTotal    = d(.combinedTotal)
        cashMainAdjusted = d(.cashMainAdjusted)
        cashManoAdjusted = d(.cashManoAdjusted)
        cardAdjusted     = d(.cardAdjusted)
    }
}

struct DailySnapshot: Codable {
    let cashMainTotal: Double
    let cashManoTotal: Double
    let cardTotal: Double
    let grandTotal: Double
    let cashMainAdjusted: Double
    let cashManoAdjusted: Double
    let cardAdjusted: Double
    let grandAdjusted: Double
    let perShowroom: [ShowroomSnapshot]

    static let empty = DailySnapshot(
        cashMainTotal: 0, cashManoTotal: 0, cardTotal: 0, grandTotal: 0,
        cashMainAdjusted: 0, cashManoAdjusted: 0, cardAdjusted: 0,
        grandAdjusted: 0, perShowroom: []
    )

    private enum CodingKeys: String, CodingKey {
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

    init(cashMainTotal: Double, cashManoTotal: Double, cardTotal: Double,
         grandTotal: Double, cashMainAdjusted: Double, cashManoAdjusted: Double,
         cardAdjusted: Double, grandAdjusted: Double, perShowroom: [ShowroomSnapshot]) {
        self.cashMainTotal    = cashMainTotal
        self.cashManoTotal    = cashManoTotal
        self.cardTotal        = cardTotal
        self.grandTotal       = grandTotal
        self.cashMainAdjusted = cashMainAdjusted
        self.cashManoAdjusted = cashManoAdjusted
        self.cardAdjusted     = cardAdjusted
        self.grandAdjusted    = grandAdjusted
        self.perShowroom      = perShowroom
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
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

struct DashboardSummary: Codable {
    let serverDate: String
    let lastUpdatedAt: String
    let today: DailySnapshot
    let yesterday: DailySnapshot

    private enum CodingKeys: String, CodingKey {
        case serverDate    = "server_date"
        case lastUpdatedAt = "last_updated_at"
        case today, yesterday
    }
}
