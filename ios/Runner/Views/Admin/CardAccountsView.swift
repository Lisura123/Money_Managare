import SwiftUI

struct CardAccountListView: View {
    @StateObject private var vm = CardAccountViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()
    @State private var showForm = false
    @State private var editTarget: CardAccount?
    @State private var filterShowroomId: Int?

    var filtered: [CardAccount] {
        guard let id = filterShowroomId else { return vm.accounts }
        return vm.accounts.filter { $0.showroomId == id }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Showroom filter
                if !showroomVM.showrooms.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: filterShowroomId == nil) {
                                filterShowroomId = nil
                            }
                            ForEach(showroomVM.showrooms) { s in
                                FilterChip(label: s.name, isSelected: filterShowroomId == s.id) {
                                    filterShowroomId = s.id
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color.mmCard)
                }

                Group {
                    if vm.isLoading && vm.accounts.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(40)
                    } else if filtered.isEmpty {
                        EmptyStateView(icon: "creditcard", message: "No card accounts")
                    } else {
                        List {
                            ForEach(filtered) { acc in
                                NavigationLink(destination: CardAccountDetailView(account: acc)) {
                                    CardAccountRow(account: acc)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button("Edit") { editTarget = acc }.tint(Color.mmPrimary)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await vm.fetchAll() }
                    }
                }
                .background(Color.mmBackground)
            }
            .navigationTitle("Card Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showForm = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary)
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                CardAccountFormView(existing: nil, showrooms: showroomVM.showrooms) { await vm.fetchAll() }
            }
            .sheet(item: $editTarget) { acc in
                CardAccountFormView(existing: acc, showrooms: showroomVM.showrooms) { await vm.fetchAll() }
            }
            .task {
                async let a: () = vm.fetchAll()
                async let s: () = showroomVM.fetchAll()
                _ = await (a, s)
            }
            .onReceive(NotificationCenter.default.publisher(for: .balancesDidChange)) { _ in
                Task { await vm.fetchAll() }
            }
        }
    }
}

struct CardAccountRow: View {
    let account: CardAccount

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mmPrimary.opacity(0.08))
                    .frame(width: 44, height: 30)
                Text("CARD").font(.system(size: 8, weight: .bold)).foregroundStyle(Color.mmPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayLabel).font(.system(size: 14, weight: .medium))
                if let sn = account.showroomName {
                    Text(sn).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(account.currentBalance.currency)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.mmPrimary)
                StatusBadge(text: account.isActive ? "Active" : "Inactive",
                            color: account.isActive ? .mmSuccess : .mmTextSecondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct CardAccountDetailView: View {
    let account: CardAccount
    @StateObject private var cardVM = CardEntryViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RowCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(account.displayLabel).font(.system(size: 17, weight: .bold))
                            Spacer()
                            StatusBadge(text: account.isActive ? "Active" : "Inactive",
                                        color: account.isActive ? .mmSuccess : .mmTextSecondary)
                        }
                        if let sn = account.showroomName {
                            Label(sn, systemImage: "storefront").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                        }
                        Divider()
                        HStack {
                            Text("Current Balance").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                            Spacer()
                            Text(account.currentBalance.currency)
                                .font(.system(size: 16, weight: .bold)).foregroundStyle(Color.mmAccent)
                        }
                    }
                }
                SectionHeader(title: "Recent Card Entries")
                if cardVM.isLoading && cardVM.entries.isEmpty {
                    ProgressView()
                } else if cardVM.entries.isEmpty {
                    Text("No entries").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                } else {
                    ForEach(cardVM.entries) { e in CardEntryRow(entry: e) }
                }
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle(account.maskedNumber)
        .navigationBarTitleDisplayMode(.inline)
        .task { await cardVM.fetchEntries(cardAccountId: account.id, refresh: true) }
    }
}

struct CardAccountFormView: View {
    @Environment(\.dismiss) var dismiss
    let existing: CardAccount?
    let showrooms: [Showroom]
    let onSave: () async -> Void

    @StateObject private var vm = CardAccountViewModel()
    @State private var selectedShowroomId: Int?
    @State private var bankName = ""
    @State private var lastFour = ""
    @State private var balance = ""
    @State private var isActive = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Showroom", selection: $selectedShowroomId) {
                        Text("Select…").tag(Optional<Int>.none)
                        ForEach(showrooms) { s in Text(s.name).tag(Optional(s.id)) }
                    }
                    TextField("Bank Name", text: $bankName)
                    TextField("Last 4 Digits", text: $lastFour)
                        .keyboardType(.numberPad)
                    TextField("Current Balance", text: $balance)
                        .keyboardType(.decimalPad)
                    Toggle("Active", isOn: $isActive)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle(existing == nil ? "New Card Account" : "Edit Card Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || bankName.isEmpty || lastFour.count != 4)
                }
            }
            .onAppear {
                if let a = existing {
                    selectedShowroomId = a.showroomId
                    bankName = a.bankName; lastFour = a.lastFour
                    balance  = String(a.currentBalance); isActive = a.isActive
                }
            }
        }
    }

    private func save() async {
        guard let sId = selectedShowroomId else { error = "Select a showroom."; return }
        let bal = Double(balance) ?? 0
        do {
            if let a = existing {
                try await vm.update(a.id, showroomId: sId, bankName: bankName,
                                    lastFour: lastFour, currentBalance: bal, isActive: isActive)
            } else {
                try await vm.create(showroomId: sId, bankName: bankName,
                                    lastFour: lastFour, currentBalance: bal, isActive: isActive)
            }
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.mmPrimary : Color.mmCard)
                .foregroundStyle(isSelected ? Color.white : Color.mmTextPrimary)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.mmDivider, lineWidth: isSelected ? 0 : 1))
        }
    }
}
