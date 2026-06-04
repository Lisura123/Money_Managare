import SwiftUI

struct StaffListView: View {
    @StateObject private var vm = StaffViewModel()
    @State private var showForm = false
    @State private var editTarget: User?
    @State private var selectedItem: User?
    @State private var deleteAlert: User?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    var body: some View {
        NavigationStack {
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
            .background(Color.mmBackground)
            .navigationTitle("Staff")
            .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isSelecting = false; selectedIds = [] }
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
}

struct StaffRow: View {
    let user: User

    var body: some View {
        RowCard {
            HStack(spacing: 12) {
                AvatarView(initials: user.initials, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name).font(.system(size: 15, weight: .medium))
                    Text(user.email).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    if let sn = user.showroomName {
                        Text(sn).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(text: user.isActive ? "Active" : "Inactive",
                                color: user.isActive ? .mmSuccess : .mmTextSecondary)
                    Text(user.role.capitalized)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct StaffFormView: View {
    @Environment(\.dismiss) var dismiss
    let existing: User?
    let onSave: () async -> Void

    @StateObject private var vm = StaffViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var role = "staff"
    @State private var selectedShowroomId: Int?
    @State private var isActive = true
    @State private var error: String?

    private let roles = ["staff"]

    var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Info") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email).keyboardType(.emailAddress).autocorrectionDisabled()
                    if !isEditing {
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Password", text: $password)
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
                    }
                }
                Section("Role & Showroom") {
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    Picker("Showroom", selection: $selectedShowroomId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(showroomVM.showrooms) { s in Text(s.name).tag(Optional(s.id)) }
                    }
                    Toggle("Active", isOn: $isActive)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle(isEditing ? "Edit Staff" : "New Staff")
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
                    name = u.name; email = u.email
                    role = u.role; selectedShowroomId = u.showroomId; isActive = u.isActive
                }
            }
            .task { await showroomVM.fetchAll() }
        }
    }

    private func save() async {
        if !isEditing && selectedShowroomId == nil {
            error = "Showroom is required."; return
        }
        do {
            if let u = existing {
                try await vm.update(u.id, name: name, email: email, role: role,
                                    showroomId: selectedShowroomId, isActive: isActive,
                                    password: password.isEmpty ? nil : password)
            } else {
                try await vm.create(name: name, email: email, password: password,
                                    role: role, showroomId: selectedShowroomId, isActive: isActive)
            }
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
