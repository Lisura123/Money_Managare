import Foundation

@MainActor
final class StaffStatusViewModel: ObservableObject {
    @Published var todayStatus: TodayStatus?
    @Published var isLoading = false
    @Published var error: String?

    private let api = APIService.shared

    func fetch() async {
        isLoading = true; error = nil
        do {
            todayStatus = try await api.get("/today-status")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
