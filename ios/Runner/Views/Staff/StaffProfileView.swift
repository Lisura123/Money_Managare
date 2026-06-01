import SwiftUI

struct StaffProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showChangePassword = false
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
                }

                Section("Edit Requests") {
                    NavigationLink(destination: MyEditRequestsView()) {
                        Label("My Edit Requests", systemImage: "pencil.circle")
                    }
                    NavigationLink(destination: StaffEditWindowView()) {
                        Label("Edit Window", systemImage: "clock.badge.checkmark")
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

// MARK: - Staff Edit Window (read-only)

struct StaffEditWindowView: View {
    @StateObject private var vm = EditWindowViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status card
                RowCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill((vm.isOpen ? Color.mmSuccess : Color.mmError).opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: vm.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(vm.isOpen ? Color.mmSuccess : Color.mmError)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.isOpen ? "Editing is Currently Open" : "Editing is Currently Closed")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(vm.isOpen ? Color.mmSuccess : Color.mmError)
                            if let s = vm.status {
                                Text("Server time: \(to12h(s.serverTime))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                        Spacer()
                    }
                }

                // Window hours
                RowCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Daily Edit Window", systemImage: "clock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.mmPrimary)
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Opens at")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.mmTextSecondary)
                                Text(to12h(vm.windowStart))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Color.mmSuccess)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.mmTextSecondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Closes at")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.mmTextSecondary)
                                Text(to12h(vm.windowEnd))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Color.mmError)
                            }
                        }
                    }
                }

                // Info note when closed
                if !vm.isOpen {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.mmWarning)
                        Text("Entry edits are only allowed during the window hours set by your admin.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(14)
                    .background(Color.mmWarning.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle("Edit Window")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { Task { await vm.fetch() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { await vm.fetch() }
    }

    private func to12h(_ time: String) -> String {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count == 2 else { return time }
        let h = parts[0]; let m = parts[1]
        let period = h < 12 ? "AM" : "PM"
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", h12, m, period)
    }
}
