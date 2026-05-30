import Foundation

enum AuthState { case initial, loading, authenticated, unauthenticated }

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthState = .initial
    @Published var user: User?
    @Published var error: String?
    @Published var isLoading = false

    private let authService = AuthService()

    var isAuthenticated: Bool { state == .authenticated && user != nil }
    var isAdmin:  Bool { user?.isAdmin ?? false }
    var isStaff:  Bool { user?.isStaff ?? false }

    func checkAuth() {
        state = .loading
        if let token = authService.storedToken(), !token.isEmpty,
           let u = authService.storedUser() {
            user  = u
            state = .authenticated
        } else {
            authService.clearStorage()
            state = .unauthenticated
        }
    }

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        error = nil
        do {
            let (_, u) = try await authService.login(email: email, password: password)
            user  = u
            state = .authenticated
            APIService.shared.onUnauthorised = { [weak self] in self?.forceLogout() }
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading  = false
            return false
        }
    }

    func logout() async {
        await authService.logout()
        user  = nil
        state = .unauthenticated
        error = nil
    }

    func forceLogout() {
        authService.clearStorage()
        user  = nil
        state = .unauthenticated
        error = nil
    }

    func clearError() { error = nil }
}
