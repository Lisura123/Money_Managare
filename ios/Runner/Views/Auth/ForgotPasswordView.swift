import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var codeSent = false

    private let authService = AuthService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = error {
                        ErrorBanner(message: e) { error = nil }
                    }

                    if codeSent {
                        VStack(spacing: 12) {
                            Image(systemName: "envelope.badge.checkmark")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.mmAccent)
                            Text("Reset code sent")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Check your email for a password reset code.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.mmTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)

                        ResetPasswordView(email: email)
                    } else {
                        Text("Enter your registered email and we'll send you a reset code.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.mmTextSecondary)

                        MMTextField(label: "Email", text: $email,
                                    placeholder: "you@example.com",
                                    keyboardType: .emailAddress,
                                    autocapitalization: .never)

                        MMButton(title: "Send Reset Code", isLoading: isLoading) {
                            Task { await send() }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func send() async {
        guard !email.isEmpty else { error = "Email is required."; return }
        isLoading = true; error = nil
        do {
            try await authService.forgotPassword(email: email)
            codeSent = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct ResetPasswordView: View {
    let email: String
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var success = false

    private let authService = AuthService()

    var body: some View {
        VStack(spacing: 16) {
            if let e = error {
                ErrorBanner(message: e) { error = nil }
            }
            if success {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 44)).foregroundStyle(Color.mmSuccess)
                    Text("Password reset successfully").font(.system(size: 16, weight: .semibold))
                    Button("Go to Login") { dismiss() }
                        .font(.system(size: 14)).foregroundStyle(Color.mmAccent)
                }
            } else {
                MMTextField(label: "Reset Code", text: $code, placeholder: "6-digit code",
                            keyboardType: .numberPad, autocapitalization: .never)
                MMTextField(label: "New Password", text: $password,
                            placeholder: "Min. 8 characters", isSecure: true)
                MMTextField(label: "Confirm Password", text: $confirm,
                            placeholder: "Repeat new password", isSecure: true)
                MMButton(title: "Reset Password", isLoading: isLoading) {
                    Task { await reset() }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func reset() async {
        guard !code.isEmpty, !password.isEmpty, password == confirm else {
            error = password != confirm ? "Passwords do not match." : "All fields required."
            return
        }
        isLoading = true; error = nil
        do {
            try await authService.resetPassword(
                email: email, code: code,
                password: password, passwordConfirmation: confirm)
            success = true
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
