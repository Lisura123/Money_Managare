import SwiftUI

struct StaffProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showChangePassword = false
    @State private var showMyRequests = false
    @State private var logoutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // User info header
                Section {
                    HStack(spacing: 16) {
                        if let user = auth.user {
                            AvatarView(initials: user.initials, size: 56)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.mmPrimary)
                                Text(user.email)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.mmTextSecondary)
                                if let sn = user.showroomName {
                                    Label(sn, systemImage: "storefront")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.mmTextSecondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Account") {
                    Button {
                        showChangePassword = true
                    } label: {
                        Label("Change Password", systemImage: "key.fill")
                    }

                    Button {
                        showMyRequests = true
                    } label: {
                        Label("My Edit Requests", systemImage: "pencil.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        logoutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showMyRequests) {
                MyEditRequestsView()
            }
            .alert("Sign Out", isPresented: $logoutAlert) {
                Button("Sign Out", role: .destructive) {
                    Task { await auth.logout() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
