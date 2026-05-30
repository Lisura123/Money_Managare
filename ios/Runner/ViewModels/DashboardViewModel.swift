import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var isLoading = false
    @Published var error: String?
    @Published var newDayDetected = false

    private let api = APIService.shared
    private var previousServerDate: String?
    private var refreshTask: Task<Void, Never>?

    func fetch(silent: Bool = false) async {
        if !silent { isLoading = true; error = nil }
        do {
            let data: DashboardSummary = try await api.get("/admin/dashboard-summary")
            if let prev = previousServerDate, prev != data.serverDate {
                newDayDetected = true
            }
            previousServerDate = data.serverDate
            summary = data
        } catch {
            if !silent { self.error = error.localizedDescription }
        }
        if !silent { isLoading = false }
    }

    func clearNewDayNotification() { newDayDetected = false }

    func startPolling() {
        stopPolling()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000) // 5 min
                await fetch(silent: true)
            }
        }
    }

    func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
