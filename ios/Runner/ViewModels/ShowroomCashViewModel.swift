import Foundation

@MainActor
final class ShowroomCashViewModel: ObservableObject {
    @Published var showrooms: [ShowroomCashBalance] = []
    @Published var isLoading = false

    private let api = APIService.shared

    func fetchAll() async {
        isLoading = true
        do {
            showrooms = try await api.get("/showroom-cash-balances")
        } catch { }
        isLoading = false
    }
}
