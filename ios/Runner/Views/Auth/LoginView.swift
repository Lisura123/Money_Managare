import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgot = false

    var body: some View {
        ZStack {
            Color.mmPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: "creditcard.and.123")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                        Text(AppConfig.appName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Sign in to your account")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Card
                    VStack(spacing: 20) {
                        if let e = auth.error {
                            ErrorBanner(message: e) { auth.clearError() }
                        }

                        MMTextField(label: "Email", text: $email,
                                    placeholder: "you@example.com",
                                    keyboardType: .emailAddress,
                                    autocapitalization: .never)

                        MMTextField(label: "Password", text: $password,
                                    placeholder: "••••••••", isSecure: true)

                        MMButton(title: "Sign In", isLoading: auth.isLoading) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                            to: nil, from: nil, for: nil)
                            Task { await auth.login(email: email, password: password) }
                        }

                        Button("Forgot password?") { showForgot = true }
                            .font(.system(size: 14))
                            .foregroundStyle(Color.mmAccent)
                    }
                    .padding(24)
                    .background(Color.mmCard)
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordView()
        }
    }
}
