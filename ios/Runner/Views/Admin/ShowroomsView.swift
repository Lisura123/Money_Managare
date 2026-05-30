import SwiftUI

struct ShowroomListView: View {
    @StateObject private var vm = ShowroomViewModel()
    @State private var showForm = false
    @State private var editTarget: Showroom?
    @State private var deleteAlert: Showroom?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.showrooms.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                } else if vm.showrooms.isEmpty {
                    EmptyStateView(icon: "storefront", message: "No showrooms yet")
                } else {
                    List {
                        ForEach(vm.showrooms) { s in
                            NavigationLink(destination: ShowroomDetailView(showroom: s)) {
                                ShowroomRow(showroom: s)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) { deleteAlert = s }
                                Button("Edit") { editTarget = s }.tint(Color.mmPrimary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchAll() }
                }
            }
            .background(Color.mmBackground)
            .navigationTitle("Showrooms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showForm = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary)
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                ShowroomFormView(existing: nil) { await vm.fetchAll() }
            }
            .sheet(item: $editTarget) { s in
                ShowroomFormView(existing: s) { await vm.fetchAll() }
            }
            .alert(item: $deleteAlert) { s in
                Alert(
                    title: Text("Delete \(s.name)?"),
                    message: Text("This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task { try? await vm.delete(s.id) }
                    },
                    secondaryButton: .cancel()
                )
            }
            .task { await vm.fetchAll() }
        }
    }
}

struct ShowroomRow: View {
    let showroom: Showroom

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(showroom.isActive ? Color.mmAccent.opacity(0.15) : Color.mmTextSecondary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "storefront")
                    .foregroundStyle(showroom.isActive ? Color.mmAccent : Color.mmTextSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(showroom.name).font(.system(size: 15, weight: .medium))
                if let l = showroom.location {
                    Text(l).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                }
            }
            Spacer()
            StatusBadge(text: showroom.isActive ? "Active" : "Inactive",
                        color: showroom.isActive ? .mmSuccess : .mmTextSecondary)
        }
        .padding(.vertical, 6)
    }
}

struct ShowroomDetailView: View {
    let showroom: Showroom
    @StateObject private var cardVM = CardAccountViewModel()
    @StateObject private var staffVM = StaffViewModel()
    @State private var showAddCard = false
    @State private var editCardTarget: CardAccount? = nil
    @State private var deleteCardAlert: CardAccount? = nil

    private var showroomAccounts: [CardAccount] {
        cardVM.accounts.filter { $0.showroomId == showroom.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info card
                RowCard {
                    HStack {
                        Image(systemName: "storefront.fill").font(.system(size: 28)).foregroundStyle(Color.mmAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(showroom.name).font(.system(size: 17, weight: .bold))
                            if let l = showroom.location {
                                Label(l, systemImage: "mappin").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                        Spacer()
                        StatusBadge(text: showroom.isActive ? "Active" : "Inactive",
                                    color: showroom.isActive ? .mmSuccess : .mmTextSecondary)
                    }
                }

                // Card accounts
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionHeader(title: "Card Accounts")
                        Spacer()
                        Button {
                            showAddCard = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.mmPrimary)
                                .font(.system(size: 20))
                        }
                    }
                    if cardVM.isLoading {
                        ProgressView()
                    } else if showroomAccounts.isEmpty {
                        Text("No card accounts").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                    } else {
                        ForEach(showroomAccounts) { acc in
                            RowCard {
                                HStack {
                                    CardAccountRow(account: acc)
                                    Spacer(minLength: 4)
                                    HStack(spacing: 12) {
                                        Button {
                                            editCardTarget = acc
                                        } label: {
                                            Image(systemName: "pencil").foregroundStyle(Color.mmPrimary)
                                        }
                                        Button {
                                            deleteCardAlert = acc
                                        } label: {
                                            Image(systemName: "trash").foregroundStyle(Color.mmError)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Staff
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Staff")
                    if staffVM.isLoading {
                        ProgressView()
                    } else if staffVM.staffList.isEmpty {
                        Text("No staff assigned").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                    } else {
                        ForEach(staffVM.staffList) { s in
                            StaffRow(user: s)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle(showroom.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddCard) {
            CardAccountFormView(existing: nil, showrooms: [showroom]) {
                await cardVM.fetchAll(showroomId: showroom.id)
            }
        }
        .sheet(item: $editCardTarget) { acc in
            CardAccountFormView(existing: acc, showrooms: [showroom]) {
                await cardVM.fetchAll(showroomId: showroom.id)
            }
        }
        .alert(item: $deleteCardAlert) { acc in
            Alert(
                title: Text("Delete \(acc.displayLabel)?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await cardVM.delete(acc.id) }
                },
                secondaryButton: .cancel()
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .balancesDidChange)) { _ in
            Task { await cardVM.fetchAll(showroomId: showroom.id) }
        }
        .task {
            async let c: () = cardVM.fetchAll(showroomId: showroom.id)
            async let s: () = staffVM.fetchAll(showroomId: showroom.id)
            _ = await (c, s)
        }
    }
}

struct ShowroomFormView: View {
    @Environment(\.dismiss) var dismiss
    let existing: Showroom?
    let onSave: () async -> Void

    @StateObject private var vm = ShowroomViewModel()
    @State private var name = ""
    @State private var location = ""
    @State private var isActive = true
    @State private var error: String?

    var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Location (optional)", text: $location)
                    Toggle("Active", isOn: $isActive)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle(isEditing ? "Edit Showroom" : "New Showroom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || name.isEmpty)
                }
            }
            .onAppear {
                if let s = existing {
                    name = s.name; location = s.location ?? ""; isActive = s.isActive
                }
            }
        }
    }

    private func save() async {
        do {
            let loc = location.isEmpty ? nil : location
            if let s = existing {
                try await vm.update(s.id, name: name, location: loc, isActive: isActive)
            } else {
                try await vm.create(name: name, location: loc, isActive: isActive)
            }
            await onSave()
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
