import Foundation

struct AuthService {
    private let api = APIService.shared

    // MARK: - Login

    struct LoginResponse: Decodable {
        let token: String
        let user: User
    }

    func login(email: String, password: String) async throws -> (token: String, user: User) {
        let resp: LoginResponse = try await api.post("/login", body: [
            "email":    email.trimmingCharacters(in: .whitespaces),
            "password": password
        ])
        try KeychainService.save(resp.token, for: AppConfig.tokenKey)
        if let userData = try? JSONEncoder().encode(resp.user) {
            UserDefaults.standard.set(userData, forKey: AppConfig.userKey)
        }
        return (resp.token, resp.user)
    }

    // MARK: - Logout

    func logout() async {
        try? await api.postVoid("/logout")
        KeychainService.delete(for: AppConfig.tokenKey)
        UserDefaults.standard.removeObject(forKey: AppConfig.userKey)
    }

    // MARK: - Password flows

    func forgotPassword(email: String) async throws {
        try await api.postVoid("/forgot-password", body: [
            "email": email.trimmingCharacters(in: .whitespaces)
        ])
    }

    func resetPassword(email: String, code: String,
                       password: String, passwordConfirmation: String) async throws {
        try await api.postVoid("/reset-password", body: [
            "email":                 email.trimmingCharacters(in: .whitespaces),
            "code":                  code.trimmingCharacters(in: .whitespaces),
            "password":              password,
            "password_confirmation": passwordConfirmation
        ])
    }

    func changePassword(currentPassword: String,
                        newPassword: String,
                        newPasswordConfirmation: String) async throws {
        try await api.postVoid("/change-password", body: [
            "current_password":          currentPassword,
            "new_password":              newPassword,
            "new_password_confirmation": newPasswordConfirmation
        ])
    }

    // MARK: - Local storage helpers

    func storedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: AppConfig.userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func storedToken() -> String? {
        try? KeychainService.read(for: AppConfig.tokenKey)
    }

    func clearStorage() {
        KeychainService.delete(for: AppConfig.tokenKey)
        UserDefaults.standard.removeObject(forKey: AppConfig.userKey)
    }
}
