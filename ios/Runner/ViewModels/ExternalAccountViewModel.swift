import Foundation

@MainActor
final class ExternalAccountViewModel: ObservableObject {
    @Published var accounts: [ExternalAccount] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchAll() async {
        isLoading = true; error = nil
        do {
            accounts = try await api.get("/external-accounts")
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
