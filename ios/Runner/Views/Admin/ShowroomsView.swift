import SwiftUI

struct ShowroomListView: View {
    @StateObject private var vm = ShowroomViewModel()
    @State private var path: [Showroom] = []
    @State private var showForm = false
    @State private var editTarget: Showroom?
    @State private var deleteAlert: Showroom?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if vm.isLoading && vm.showrooms.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else if !vm.isLoading && vm.showrooms.isEmpty {
                    Text("No showrooms yet")
                        .foregroundStyle(Color.mmTextSecondary)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(vm.showrooms) { s in
                        if isSelecting {
                            Button {
                                if selectedIds.contains(s.id) { selectedIds.remove(s.id) }
                                else { selectedIds.insert(s.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedIds.contains(s.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(s.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                    ShowroomRow(showroom: s)
                                }
                            }
                            .listRowBackground(selectedIds.contains(s.id) ? Color.mmPrimary.opacity(0.1) : Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            NavigationLink(value: s) {
                                ShowroomRow(showroom: s)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button("Edit") { editTarget = s }.tint(Color.mmPrimary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.mmBackground)
            .navigationTitle("Showrooms")
            .navigationDestination(for: Showroom.self) { s in
                ShowroomDetailView(showroom: s)
            }
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
                        Button { isSelecting = true } label: {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                }
            }
            .refreshable { await vm.fetchAll() }
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
            .alert("Delete \(selectedIds.count) showroom(s)?", isPresented: $bulkDeleteAlert) {
                Button("Delete", role: .destructive) {
                    let ids = Array(selectedIds)
                    Task {
                        try? await vm.bulkDelete(ids)
                        isSelecting = false; selectedIds = []
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
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
    @StateObject private var cardVM    = CardAccountViewModel()
    @StateObject private var staffVM   = StaffViewModel()
    @StateObject private var cashVM    = ShowroomCashViewModel()
    @State private var showAddCard = false
    @State private var editCardTarget: CardAccount? = nil
    @State private var deleteCardAlert: CardAccount? = nil
    @State private var showCashEdit = false

    private var showroomAccounts: [CardAccount] {
        cardVM.accounts.filter { $0.showroomId == showroom.id }
    }
    private var totalCardBalance: Double {
        showroomAccounts.reduce(0) { $0 + $1.currentBalance }
    }
    private var mainCashBalance: Double {
        cashVM.showrooms.first { $0.showroomId == showroom.id }?.balance ?? 0
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

                // Balance summary tiles
                HStack(spacing: 12) {
                    BalanceTile(
                        title: "Main Cash",
                        amount: mainCashBalance,
                        icon: "banknote.fill",
                        color: Color.mmPrimary,
                        onEdit: { showCashEdit = true }
                    )
                    BalanceTile(
                        title: "Total Cards",
                        amount: totalCardBalance,
                        icon: "creditcard.fill",
                        color: Color.mmAccent
                    )
                }

                // Card accounts
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionHeader(title: "Bank Accounts")
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
                        Text("No bank accounts").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
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
                    } else if staffVM.staffList.filter({ $0.showroomId == showroom.id }).isEmpty {
                        Text("No staff assigned").font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                    } else {
                        ForEach(staffVM.staffList.filter({ $0.showroomId == showroom.id })) { s in
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
        .sheet(isPresented: $showCashEdit) {
            ShowroomCashAdjustSheet(showroom: showroom, currentBalance: mainCashBalance) {
                await cashVM.fetchAll()
                NotificationCenter.default.post(name: .balancesDidChange, object: nil)
            }
        }
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
            Task {
                async let c: () = cardVM.fetchAll(showroomId: showroom.id)
                async let h: () = cashVM.fetchAll()
                _ = await (c, h)
            }
        }
        .task {
            async let c: () = cardVM.fetchAll(showroomId: showroom.id)
            async let s: () = staffVM.fetchAll(showroomId: showroom.id)
            async let h: () = cashVM.fetchAll()
            _ = await (c, s, h)
        }
    }
}

private struct BalanceTile: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    var onEdit: (() -> Void)? = nil

    var body: some View {
        RowCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                    if let edit = onEdit {
                        Button(action: edit) {
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(color.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(amount.currency)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Main Cash Adjustment Sheet

struct ShowroomCashAdjustSheet: View {
    @Environment(\.dismiss) var dismiss
    let showroom: Showroom
    let currentBalance: Double
    let onSave: () async -> Void

    @StateObject private var vm = CashEntryViewModel()
    @State private var adjustmentAmount = ""
    @State private var reason = ""
    @State private var error: String?
    @State private var success = false

    private let reasonChips = ["Cash top-up", "Cash withdrawal", "Correction", "Transfer", "Other"]

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
                            Text("Balance updated").foregroundStyle(Color.mmSuccess)
                        }
                        .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
                    }

                    // Current balance
                    RowCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Balance")
                                    .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                                Text(currentBalance.currency)
                                    .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.mmPrimary)
                            }
                            Spacer()
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 28)).foregroundStyle(Color.mmPrimary.opacity(0.3))
                        }
                    }

                    // Adjustment amount
                    RowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Adjustment Amount", systemImage: "plusminus.circle")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                            Text("Use positive to add cash, negative to deduct (e.g. -500)")
                                .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                            MMTextField(label: "Amount", text: $adjustmentAmount,
                                        placeholder: "e.g. 500 or -200",
                                        keyboardType: .numbersAndPunctuation,
                                        autocapitalization: .never)
                            if let amt = Double(adjustmentAmount), !adjustmentAmount.isEmpty {
                                let newBal = currentBalance + amt
                                HStack {
                                    Text("New balance:")
                                        .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                                    Text(newBal.currency)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(newBal >= 0 ? Color.mmSuccess : Color.mmError)
                                }
                            }
                        }
                    }

                    // Reason chips
                    RowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Reason", systemImage: "text.bubble")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(reasonChips, id: \.self) { chip in
                                    Button { reason = chip } label: {
                                        Text(chip)
                                            .font(.system(size: 12, weight: reason == chip ? .semibold : .regular))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 10).padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(reason == chip ? Color.mmPrimary : Color.mmInputFill)
                                            .foregroundStyle(reason == chip ? .white : Color.mmTextPrimary)
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                                reason == chip ? Color.clear : Color.mmDivider))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            if reason == "Other" || (!reasonChips.dropLast().contains(reason) && !reason.isEmpty) {
                                MMTextField(label: "Custom reason", text: $reason, placeholder: "Describe reason…")
                            }
                        }
                    }

                    MMButton(title: "Apply Adjustment", isLoading: vm.isSubmitting) {
                        Task { await submit() }
                    }
                    .disabled(adjustmentAmount.isEmpty || reason.isEmpty || vm.isSubmitting)
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Edit Main Cash — \(showroom.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private func submit() async {
        guard let amt = Double(adjustmentAmount), amt != 0 else {
            error = "Enter a non-zero adjustment amount."
            return
        }
        let r = reason.trimmingCharacters(in: .whitespaces)
        guard !r.isEmpty else { error = "Select or enter a reason."; return }
        error = nil
        do {
            try await vm.createAdjustment(
                adjustedAmount: amt,
                reason: r,
                cashAccountType: "main",
                showroomId: showroom.id
            )
            success = true
            await onSave()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
