import Foundation

struct EditWindowStatus: Decodable {
    let editWindowStart: String
    let editWindowEnd:   String
    let isWithinWindow:  Bool
    let serverTime:      String

    private enum CodingKeys: String, CodingKey {
        case editWindowStart = "edit_window_start"
        case editWindowEnd   = "edit_window_end"
        case isWithinWindow  = "is_within_window"
        case serverTime      = "server_time"
    }
}

@MainActor
final class EditWindowViewModel: ObservableObject {
    @Published var status: EditWindowStatus?
    @Published var isLoading = false

    private let api = APIService.shared

    var isOpen:      Bool   { status?.isWithinWindow ?? true }
    var windowStart: String { status?.editWindowStart ?? "00:00" }
    var windowEnd:   String { status?.editWindowEnd   ?? "23:59" }

    /// Returns e.g. "12:00 AM – 11:59 PM" in 12-hour format
    var windowHours: String {
        "\(to12h(windowStart)) – \(to12h(windowEnd))"
    }

    func fetch() async {
        isLoading = true
        do { status = try await api.get("/edit-window") } catch {}
        isLoading = false
    }

    private func to12h(_ time: String) -> String {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count == 2 else { return time }
        let h = parts[0]; let m = parts[1]
        let period = h < 12 ? "AM" : "PM"
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", h12, m, period)
    }
}
