import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel

    @State private var current = ""
    @State private var newPass = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var success = false

    private let authService = AuthService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = error {
                        ErrorBanner(message: e) { error = nil }
                    }
                    if success {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
                            Text("Password changed successfully").foregroundStyle(Color.mmSuccess)
                        }
                        .padding(12)
                        .background(Color.mmSuccess.opacity(0.1))
                        .cornerRadius(10)
                    }
                    MMTextField(label: "Current Password", text: $current,
                                placeholder: "Enter current password", isSecure: true)
                    MMTextField(label: "New Password", text: $newPass,
                                placeholder: "Min. 8 characters", isSecure: true)
                    MMTextField(label: "Confirm New Password", text: $confirm,
                                placeholder: "Repeat new password", isSecure: true)
                    MMButton(title: "Change Password", isLoading: isLoading) {
                        Task { await submit() }
                    }
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        guard !current.isEmpty, !newPass.isEmpty, newPass == confirm else {
            error = newPass != confirm ? "Passwords do not match." : "All fields are required."
            return
        }
        isLoading = true; error = nil
        do {
            try await authService.changePassword(
                currentPassword: current,
                newPassword: newPass,
                newPasswordConfirmation: confirm
            )
            success = true
            current = ""; newPass = ""; confirm = ""
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
