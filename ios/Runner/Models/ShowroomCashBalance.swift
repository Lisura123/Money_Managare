import Foundation

struct ShowroomCashBalance: Decodable, Identifiable {
    let showroomId: Int
    let showroomName: String
    let balance: Double

    var id: Int { showroomId }

    enum CodingKeys: String, CodingKey {
        case showroomId   = "showroom_id"
        case showroomName = "showroom_name"
        case balance
    }
}
