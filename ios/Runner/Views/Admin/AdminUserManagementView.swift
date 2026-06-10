import SwiftUI

// MARK: - Combined User Management (Staff + Admins)

struct UserManagementView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var segment = 0  // 0 = Staff, 1 = Admins

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("Staff").tag(0)
                    Text("Admins").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.mmCard)

                if segment == 0 {
                    StaffSegmentView()
                } else {
                    AdminSegmentView()
                        .environmentObject(auth)
                }
            }
            .background(Color.mmBackground)
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Staff Segment

struct StaffSegmentView: View {
    @StateObject private var vm = StaffViewModel()
    @State private var showForm = false
    @State private var editTarget: User?
    @State private var selectedItem: User?
    @State private var deleteAlert: User?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    var body: some View {
        Group {
            if vm.isLoading && vm.staffList.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.staffList.isEmpty {
                EmptyStateView(icon: "person.2", message: "No staff members")
            } else {
                List {
                    ForEach(vm.staffList) { u in
                        StaffRow(user: u)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    if selectedIds.contains(u.id) { selectedIds.remove(u.id) }
                                    else { selectedIds.insert(u.id) }
                                } else {
                                    selectedItem = selectedItem?.id == u.id ? nil : u
                                }
                            }
                            .listRowBackground(
                                (isSelecting ? selectedIds.contains(u.id) : selectedItem?.id == u.id)
                                    ? Color.mmPrimary.opacity(0.1) : Color.clear
                            )
                            .listRowSeparator(.hidden)
                            .overlay(alignment: .leading) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(u.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(u.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                        .padding(.leading, 20)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !isSelecting {
                                    Button(u.isActive ? "Deactivate" : "Activate") {
                                        Task { try? await vm.toggleActive(u.id) }
                                    }
                                    .tint(u.isActive ? Color.mmWarning : Color.mmSuccess)
                                    Button("Edit") { editTarget = u }.tint(Color.mmPrimary)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAll() }
            }
        }
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isSelecting = false; selectedIds = [] }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Select All") { selectedIds = Set(vm.staffList.map { $0.id }) }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Delete (\(selectedIds.count))") { bulkDeleteAlert = true }
                        .foregroundStyle(Color.mmError)
                        .disabled(selectedIds.isEmpty)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button { showForm = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if let item = selectedItem {
                            Button(role: .destructive) { deleteAlert = item } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { editTarget = item } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Divider()
                        } else {
                            Text("Tap a row to select")
                            Divider()
                        }
                        Button { isSelecting = true } label: {
                            Label("Select Multiple", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showForm) {
            StaffFormView(existing: nil) { await vm.fetchAll() }
        }
        .sheet(item: $editTarget) { u in
            StaffFormView(existing: u) { await vm.fetchAll() }
        }
        .alert(item: $deleteAlert) { u in
            Alert(
                title: Text("Delete \(u.name)?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.delete(u.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) staff member(s)?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDelete(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
        .task { await vm.fetchAll() }
    }
}

// MARK: - Admin Users Segment

struct AdminSegmentView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = AdminUserViewModel()
    @State private var showForm = false
    @State private var editTarget: User?
    @State private var selectedItem: User?
    @State private var deleteAlert: User?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    var body: some View {
            Group {
                if vm.isLoading && vm.admins.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                } else if vm.admins.isEmpty {
                    EmptyStateView(icon: "person.badge.shield.checkmark", message: "No admin accounts")
                } else {
                    List {
                        ForEach(vm.admins) { u in
                            AdminUserRow(user: u, isCurrentUser: u.id == auth.user?.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isSelecting {
                                        guard u.id != auth.user?.id else { return }
                                        if selectedIds.contains(u.id) { selectedIds.remove(u.id) }
                                        else { selectedIds.insert(u.id) }
                                    } else {
                                        selectedItem = selectedItem?.id == u.id ? nil : u
                                    }
                                }
                                .listRowBackground(
                                    (isSelecting ? selectedIds.contains(u.id) : selectedItem?.id == u.id)
                                        ? Color.mmPrimary.opacity(0.1) : Color.clear
                                )
                                .listRowSeparator(.hidden)
                                .overlay(alignment: .leading) {
                                    if isSelecting && u.id != auth.user?.id {
                                        Image(systemName: selectedIds.contains(u.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedIds.contains(u.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                            .font(.system(size: 20))
                                            .padding(.leading, 20)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    if !isSelecting && u.id != auth.user?.id {
                                        Button(u.isActive ? "Deactivate" : "Activate") {
                                            Task { try? await vm.toggleActive(u.id) }
                                        }
                                        .tint(u.isActive ? Color.mmWarning : Color.mmSuccess)
                                        Button("Edit") { editTarget = u }.tint(Color.mmPrimary)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchAll() }
                }
            }
        .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isSelecting = false; selectedIds = [] }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Select All") {
                            selectedIds = Set(vm.admins.filter { $0.id != auth.user?.id }.map { $0.id })
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Delete (\(selectedIds.count))") { bulkDeleteAlert = true }
                            .foregroundStyle(Color.mmError)
                            .disabled(selectedIds.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showForm = true } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            if let item = selectedItem {
                                if item.id != auth.user?.id {
                                    Button(role: .destructive) { deleteAlert = item } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button { editTarget = item } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Divider()
                                } else {
                                    Text("Cannot modify your own account here")
                                    Divider()
                                }
                            } else {
                                Text("Tap a row to select")
                                Divider()
                            }
                            Button { isSelecting = true } label: {
                                Label("Select Multiple", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                AdminUserFormView(existing: nil) { await vm.fetchAll() }
            }
            .sheet(item: $editTarget) { u in
                AdminUserFormView(existing: u) { await vm.fetchAll() }
            }
            .alert(item: $deleteAlert) { u in
                Alert(
                    title: Text("Delete \(u.name)?"),
                    message: Text("This cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task { try? await vm.delete(u.id); selectedItem = nil }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Delete \(selectedIds.count) admin(s)?", isPresented: $bulkDeleteAlert) {
                Button("Delete", role: .destructive) {
                    let ids = Array(selectedIds)
                    Task { try? await vm.bulkDelete(ids); isSelecting = false; selectedIds = [] }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This cannot be undone.") }
        .task { await vm.fetchAll() }
    }
}

// MARK: - Admin User Row

struct AdminUserRow: View {
    let user: User
    let isCurrentUser: Bool

    var body: some View {
        RowCard {
            HStack(spacing: 12) {
                ZStack {
                    AvatarView(initials: user.initials, size: 40)
                    if isCurrentUser {
                        Circle()
                            .stroke(Color.mmAccent, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user.name).font(.system(size: 15, weight: .medium))
                        if isCurrentUser {
                            Text("(You)")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mmAccent)
                        }
                    }
                    Text(user.email).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                StatusBadge(text: user.isActive ? "Active" : "Inactive",
                            color: user.isActive ? .mmSuccess : .mmTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Admin User Form

struct AdminUserFormView: View {
    @Environment(\.dismiss) var dismiss
    let existing: User?
    let onSave: () async -> Void

    @StateObject private var vm = AdminUserViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isActive = true
    @State private var selectedRole = "admin"
    @State private var selectedShowroomId: Int?
    @State private var error: String?

    var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Info") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    HStack {
                        Group {
                            if showPassword {
                                TextField(isEditing ? "New Password (leave blank to keep)" : "Password", text: $password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField(isEditing ? "New Password (leave blank to keep)" : "Password", text: $password)
                            }
                        }
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Toggle("Active", isOn: $isActive)
                }
                if isEditing {
                    Section("Role") {
                        Picker("Role", selection: $selectedRole) {
                            Text("Admin").tag("admin")
                            Text("Staff").tag("staff")
                        }
                        if selectedRole == "staff" {
                            Picker("Showroom", selection: $selectedShowroomId) {
                                Text("Select Showroom").tag(Optional<Int>.none)
                                ForEach(showroomVM.showrooms.prioritized()) { s in
                                    ShowroomOptionLabel(name: s.name, isFlagship: s.isFlagship).tag(Optional(s.id))
                                }
                            }
                        }
                    }
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle(isEditing ? "Edit Admin" : "New Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || name.isEmpty || email.isEmpty || (!isEditing && password.isEmpty))
                }
            }
            .onAppear {
                if let u = existing {
                    name = u.name; email = u.email; isActive = u.isActive
                    selectedRole = u.role
                }
            }
            .task { if isEditing { await showroomVM.fetchAll() } }
        }
    }

    private func save() async {
        do {
            if let u = existing {
                if selectedRole != u.role {
                    if selectedRole == "staff" && selectedShowroomId == nil {
                        error = "Select a showroom for staff role."; return
                    }
                    try await vm.changeRole(userId: u.id, newRole: selectedRole,
                                            showroomId: selectedRole == "staff" ? selectedShowroomId : nil)
                }
                if selectedRole == "admin" {
                    try await vm.update(u.id, name: name, email: email, isActive: isActive,
                                        password: password.isEmpty ? nil : password)
                }
            } else {
                try await vm.create(name: name, email: email, password: password, isActive: isActive)
            }
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
