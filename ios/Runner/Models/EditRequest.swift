import Foundation

struct EditRequest: Codable, Identifiable {
    let id: Int
    let entryType: String   // "cash" or "card"
    let entryId: Int
    let originalValues: [String: AnyCodable]
    let requestedChanges: [String: AnyCodable]
    let reason: String
    let status: String      // "pending" | "approved" | "rejected"
    let adminRemarks: String?
    let staffName: String?
    let staffEmail: String?
    let showroomName: String?
    let reviewerName: String?
    let reviewedAt: String?
    let createdAt: String

    var isPending:  Bool { status == "pending" }
    var isApproved: Bool { status == "approved" }
    var isRejected: Bool { status == "rejected" }

    private enum CodingKeys: String, CodingKey {
        case id
        case entryType        = "entry_type"
        case entryId          = "entry_id"
        case originalValues   = "original_values"
        case requestedChanges = "requested_changes"
        case reason, status
        case adminRemarks  = "admin_remarks"
        case staffName     = "staff_name"
        case staffEmail    = "staff_email"
        case showroomName  = "showroom_name"
        case reviewerName  = "reviewer_name"
        case reviewedAt    = "reviewed_at"
        case createdAt     = "created_at"
    }
}
