import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: [Setting] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?

    private let api = APIService.shared

    func fetchAll() async {
        isLoading = true; error = nil
        do {
            settings = try await api.get("/settings")
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func update(key: String, value: String) async throws {
        isSubmitting = true; defer { isSubmitting = false }
        let updated: Setting = try await api.put("/settings/\(key)", body: ["value": value])
        if let idx = settings.firstIndex(where: { $0.key == key }) {
            settings[idx] = updated
        }
    }
}
