import SwiftUI

struct TransactionsHubView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: SelfTransactionListView()) {
                    Label("Self Transfers", systemImage: "arrow.left.arrow.right.circle")
                }
                NavigationLink(destination: CashTransactionListView()) {
                    Label("Cash Transfers", systemImage: "arrow.left.arrow.right.circle.fill")
                }
            }
            .navigationTitle("Transfers")
        }
    }
}

// MARK: - Self Transactions

struct SelfTransactionListView: View {
    @StateObject private var vm = SelfTransactionViewModel()
    @State private var showForm = false
    @State private var selectedItem: SelfTransaction?
    @State private var deleteAlert: SelfTransaction?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    var body: some View {
        Group {
            if vm.isLoading && vm.transactions.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.transactions.isEmpty {
                EmptyStateView(icon: "arrow.left.arrow.right.circle", message: "No self transfers")
            } else {
                List {
                    ForEach(vm.transactions) { t in
                        SelfTxRow(tx: t)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    if selectedIds.contains(t.id) { selectedIds.remove(t.id) }
                                    else { selectedIds.insert(t.id) }
                                } else {
                                    selectedItem = selectedItem?.id == t.id ? nil : t
                                }
                            }
                            .listRowBackground(
                                (isSelecting ? selectedIds.contains(t.id) : selectedItem?.id == t.id)
                                    ? Color.mmPrimary.opacity(0.1) : Color.clear
                            )
                            .listRowSeparator(.hidden)
                            .overlay(alignment: .leading) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(t.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(t.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                        .padding(.leading, 20)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAll() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Self Transfers").navigationBarTitleDisplayMode(.inline)
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
            SelfTransactionFormView { await vm.fetchAll(refresh: true) }
        }
        .alert(item: $deleteAlert) { t in
            Alert(
                title: Text("Delete Transfer?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.delete(t.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) transfer(s)?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDelete(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
        .task { await vm.fetchAll() }
    }
}

struct SelfTxRow: View {
    let tx: SelfTransaction

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(tx.fromDisplay) → \(tx.toDisplay)")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    if let n = tx.notes { Text(n).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary) }
                    Text((tx.createdAt ?? "").displayDateTime).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text(tx.amount.currency).font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct SelfTransactionFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () async -> Void

    // MARK: - Source / Destination type enums
    enum AccountSource: Hashable {
        case mainCash, showroomCash, card, mano
        var label: String {
            switch self {
            case .mainCash:     return "Main Cash"
            case .showroomCash: return "Showroom Cash"
            case .card:         return "Card"
            case .mano:         return "Mano"
            }
        }
    }
    enum AccountDest: Hashable {
        case mainCash, showroomCash, card, mano, other
        var label: String {
            switch self {
            case .mainCash:     return "Main Cash"
            case .showroomCash: return "Showroom Cash"
            case .card:         return "Card"
            case .mano:         return "Mano"
            case .other:        return "Others"
            }
        }
    }

    // MARK: - State
    @State private var fromType: AccountSource?
    @State private var fromShowroomId: Int?        // for Card type
    @State private var fromCardId: Int?
    @State private var fromCashShowroomId: Int?    // for Showroom Cash type

    @State private var toType: AccountDest?
    @State private var toShowroomId: Int?          // for Card type
    @State private var toCardId: Int?
    @State private var toCashShowroomId: Int?      // for Showroom Cash type

    @State private var amount = ""
    @State private var notes = ""
    @State private var error: String?

    // MARK: - ViewModels
    @StateObject private var vm           = SelfTransactionViewModel()
    @StateObject private var cardVM       = CardAccountViewModel()
    @StateObject private var showroomVM   = ShowroomViewModel()
    @StateObject private var extVM        = ExternalAccountViewModel()
    @StateObject private var cashVM       = ShowroomCashViewModel()

    // MARK: - Helpers
    private var mainCashAccount: ExternalAccount? {
        extVM.accounts.first { $0.cashAccountType == "main" }
    }
    private var manoAccount: ExternalAccount? {
        extVM.accounts.first { $0.cashAccountType == "mano" }
    }
    private func cardsForShowroom(_ id: Int) -> [CardAccount] {
        cardVM.accounts.filter { $0.showroomId == id && $0.isActive }
    }
    private var fromCardAccount: CardAccount? {
        guard let id = fromCardId else { return nil }
        return cardVM.accounts.first { $0.id == id }
    }
    private var toCardAccount: CardAccount? {
        guard let id = toCardId else { return nil }
        return cardVM.accounts.first { $0.id == id }
    }
    private var fromCashItem: ShowroomCashBalance? {
        guard let sid = fromCashShowroomId else { return nil }
        return cashVM.showrooms.first { $0.showroomId == sid }
    }
    private var toCashItem: ShowroomCashBalance? {
        guard let sid = toCashShowroomId else { return nil }
        return cashVM.showrooms.first { $0.showroomId == sid }
    }
    private var fromBalance: Double? {
        switch fromType {
        case .card:         return fromCardAccount?.currentBalance
        case .mano:         return manoAccount?.balance
        case .mainCash:     return mainCashAccount?.balance
        case .showroomCash: return fromCashItem?.balance
        case .none:         return nil
        }
    }
    private var toBalance: Double? {
        switch toType {
        case .card:         return toCardAccount?.currentBalance
        case .mano:         return manoAccount?.balance
        case .mainCash:     return mainCashAccount?.balance
        case .showroomCash: return toCashItem?.balance
        case .other, .none: return nil
        }
    }
    private var fromLabel: String {
        switch fromType {
        case .card:         return fromCardAccount?.displayLabel ?? "—"
        case .mano:         return manoAccount?.name ?? "Mano"
        case .mainCash:     return "Main Account"
        case .showroomCash: return fromCashItem.map { "Cash (\($0.showroomName))" } ?? "Showroom Cash"
        case .none:         return "—"
        }
    }
    private var toLabel: String {
        switch toType {
        case .card:         return toCardAccount?.displayLabel ?? "—"
        case .mano:         return manoAccount?.name ?? "Mano"
        case .mainCash:     return "Main Account"
        case .showroomCash: return toCashItem.map { "Cash (\($0.showroomName))" } ?? "Showroom Cash"
        case .other:        return "Others"
        case .none:         return "—"
        }
    }
    private var amountValue: Double? { Double(amount).flatMap { $0 > 0 ? $0 : nil } }
    private var notesRequired: Bool { toType == .other }
    private var saveDisabled: Bool {
        vm.isSubmitting || fromType == nil || toType == nil || amount.isEmpty ||
        (fromType == .card && fromCardId == nil) ||
        (fromType == .showroomCash && fromCashShowroomId == nil) ||
        (toType == .card && toCardId == nil) ||
        (toType == .showroomCash && toCashShowroomId == nil) ||
        (notesRequired && notes.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // ── FROM ──────────────────────────────────────────────────────
                Section {
                    typeChips(
                        options: [.mainCash, .showroomCash, .card, .mano],
                        selected: fromType
                    ) { newType in
                        fromType = newType
                        fromShowroomId = nil
                        fromCardId = nil
                        fromCashShowroomId = nil
                    }
                    fromDetailRows
                } header: { Text("From") }

                // ── TO ────────────────────────────────────────────────────────
                Section {
                    typeChips(
                        options: [.mainCash, .showroomCash, .card, .mano, .other],
                        selected: toType
                    ) { newType in
                        toType = newType
                        toShowroomId = nil
                        toCardId = nil
                        toCashShowroomId = nil
                    }
                    toDetailRows
                } header: { Text("To") }

                // ── AMOUNT & NOTES ────────────────────────────────────────────
                Section("Amount & Notes") {
                    MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(
                        label: notesRequired ? "Notes (required)" : "Notes (optional)",
                        text: $notes
                    )
                    if notesRequired && notes.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Notes are required for Others")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mmError)
                    }
                }

                // ── BALANCE PREVIEW ───────────────────────────────────────────
                if let amt = amountValue, let fb = fromBalance {
                    Section("Balance Preview") {
                        BalancePreviewRow(label: "From", name: fromLabel,
                                         before: fb, after: fb - amt, isIncrease: false)
                        if let tb = toBalance {
                            BalancePreviewRow(label: "To", name: toLabel,
                                             before: tb, after: tb + amt, isIncrease: true)
                        }
                    }
                }

                // ── ERROR ─────────────────────────────────────────────────────
                if let e = error {
                    Section {
                        Text(e).foregroundStyle(Color.mmError).font(.system(size: 13))
                    }
                }
            }
            .navigationTitle("New Self Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isSubmitting {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(saveDisabled)
                    }
                }
            }
            .task {
                async let c: () = cardVM.fetchAll()
                async let s: () = showroomVM.fetchAll()
                async let e: () = extVM.fetchAll()
                async let h: () = cashVM.fetchAll()
                _ = await (c, s, e, h)
            }
        }
    }

    // MARK: - Sub-views

    /// Horizontal row of pill chips for type selection.
    @ViewBuilder
    private func typeChips<T: Hashable>(
        options: [T],
        selected: T?,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                    let label: String = {
                        if let src = opt as? AccountSource { return src.label }
                        if let dst = opt as? AccountDest   { return dst.label }
                        return "\(opt)"
                    }()
                    let isSelected = selected == opt
                    Button(label) { onSelect(opt) }
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.mmTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.mmPrimary : Color(UIColor.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    @ViewBuilder
    private var fromDetailRows: some View {
        switch fromType {
        case .card:
            Picker("Showroom", selection: $fromShowroomId) {
                Text("Select showroom…").tag(Optional<Int>.none)
                ForEach(showroomVM.showrooms.filter { $0.isActive }) { s in
                    Text(s.name).tag(Optional<Int>.some(s.id))
                }
            }
            .onChange(of: fromShowroomId) { _ in fromCardId = nil }

            if let sid = fromShowroomId {
                let cards = cardsForShowroom(sid)
                Picker("Account", selection: $fromCardId) {
                    Text("Select account…").tag(Optional<Int>.none)
                    ForEach(cards) { a in
                        Text("\(a.displayLabel)  \(a.currentBalance.currency)")
                            .tag(Optional<Int>.some(a.id))
                    }
                }
            }
        case .mano:
            if let mano = manoAccount {
                LabeledContent(mano.name) {
                    Text(mano.balance.currency)
                        .fontWeight(.semibold).foregroundStyle(Color.mmPrimary)
                }
            } else {
                Text("Loading…").foregroundStyle(Color.mmTextSecondary)
            }
        case .mainCash:
            if let main = mainCashAccount {
                LabeledContent("Total Current Balance") {
                    Text(main.balance.currency)
                        .fontWeight(.bold).foregroundStyle(Color.mmPrimary)
                }
            } else {
                Text("Loading…").foregroundStyle(Color.mmTextSecondary)
            }
        case .showroomCash:
            Picker("Showroom", selection: $fromCashShowroomId) {
                Text("Select showroom…").tag(Optional<Int>.none)
                ForEach(cashVM.showrooms) { s in
                    Text(s.showroomName).tag(Optional<Int>.some(s.showroomId))
                }
            }
            if let item = fromCashItem {
                LabeledContent("Cash Balance") {
                    Text(item.balance.currency)
                        .fontWeight(.semibold).foregroundStyle(Color.mmPrimary)
                }
            }
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var toDetailRows: some View {
        switch toType {
        case .card:
            Picker("Showroom", selection: $toShowroomId) {
                Text("Select showroom…").tag(Optional<Int>.none)
                ForEach(showroomVM.showrooms.filter { $0.isActive }) { s in
                    Text(s.name).tag(Optional<Int>.some(s.id))
                }
            }
            .onChange(of: toShowroomId) { _ in toCardId = nil }

            if let sid = toShowroomId {
                let cards = cardsForShowroom(sid)
                Picker("Account", selection: $toCardId) {
                    Text("Select account…").tag(Optional<Int>.none)
                    ForEach(cards) { a in
                        Text("\(a.displayLabel)  \(a.currentBalance.currency)")
                            .tag(Optional<Int>.some(a.id))
                    }
                }
            }
        case .mano:
            if let mano = manoAccount {
                LabeledContent(mano.name) {
                    Text(mano.balance.currency)
                        .fontWeight(.semibold).foregroundStyle(Color.mmPrimary)
                }
            } else {
                Text("Loading…").foregroundStyle(Color.mmTextSecondary)
            }
        case .mainCash:
            if let main = mainCashAccount {
                LabeledContent("Total Current Balance") {
                    Text(main.balance.currency)
                        .fontWeight(.bold).foregroundStyle(Color.mmPrimary)
                }
            } else {
                Text("Loading…").foregroundStyle(Color.mmTextSecondary)
            }
        case .showroomCash:
            Picker("Showroom", selection: $toCashShowroomId) {
                Text("Select showroom…").tag(Optional<Int>.none)
                ForEach(cashVM.showrooms) { s in
                    Text(s.showroomName).tag(Optional<Int>.some(s.showroomId))
                }
            }
            if let item = toCashItem {
                LabeledContent("Cash Balance") {
                    Text(item.balance.currency)
                        .fontWeight(.semibold).foregroundStyle(Color.mmPrimary)
                }
            }
        case .other:
            EmptyView()   // notes are required — shown in Amount & Notes section
        case .none:
            EmptyView()
        }
    }

    // MARK: - Save
    private func save() async {
        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount"; return }
        let notesVal = notes.trimmingCharacters(in: .whitespaces)

        // Build FROM params
        let fromCardIdParam: Int?     = fromType == .card         ? fromCardId           : nil
        let fromExtIdParam:  Int?     = fromType == .mano         ? manoAccount?.id      : nil
        let fromAccTypeParam: String? = (fromType == .mainCash || fromType == .showroomCash) ? "main" : nil
        let fromShowroomIdParam: Int? = fromType == .showroomCash ? fromCashShowroomId   : nil

        // Build TO params
        var toCardIdParam:    Int?     = nil
        var toExtIdParam:     Int?     = nil
        var toAccTypeParam:   String?  = nil
        var toShowroomIdParam: Int?    = nil
        switch toType {
        case .card:         toCardIdParam  = toCardId
        case .mano:         toExtIdParam   = manoAccount?.id
        case .mainCash:     toAccTypeParam = "main"
        case .showroomCash: toAccTypeParam = "main"; toShowroomIdParam = toCashShowroomId
        case .other, .none: break
        }

        do {
            try await vm.create(
                fromCardId:     fromCardIdParam,
                fromExternalId: fromExtIdParam,
                fromAccType:    fromAccTypeParam,
                fromShowroomId: fromShowroomIdParam,
                toCardId:       toCardIdParam,
                toExternalId:   toExtIdParam,
                toAccType:      toAccTypeParam,
                toShowroomId:   toShowroomIdParam,
                amount:         amt,
                notes:          notesVal.isEmpty ? nil : notesVal
            )
            await onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Balance Preview Row

private struct BalancePreviewRow: View {
    let label: String
    let name: String
    let before: Double
    let after: Double
    let isIncrease: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(name)")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(before.currency)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmTextSecondary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmTextSecondary)
                Text(after.currency)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isIncrease ? Color.mmSuccess : Color.mmError)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Cash Transactions

struct CashTransactionListView: View {
    @StateObject private var vm = CashTransactionViewModel()
    @State private var showForm = false
    @State private var selectedItem: CashTransaction?
    @State private var deleteAlert: CashTransaction?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    var body: some View {
        List {
            // Main Cash Balance card header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Main Cash Balance")
                        .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    if vm.mainCashBalance == 0 && vm.isLoading {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text(vm.mainCashBalance.currency)
                            .font(.system(size: 26, weight: .bold)).foregroundStyle(Color.mmPrimary)
                    }
                }
                Spacer()
                Image(systemName: "banknote.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.mmPrimary.opacity(0.2))
            }
            .padding(20)
            .background(Color.mmCard)
            .cornerRadius(16)
            .listRowBackground(Color.mmBackground)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))

            if vm.isLoading && vm.transactions.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if vm.transactions.isEmpty {
                EmptyStateView(icon: "arrow.left.arrow.right.circle.fill", message: "No cash transfers")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(vm.transactions) { t in
                    CashTxRow(tx: t)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isSelecting {
                                if selectedIds.contains(t.id) { selectedIds.remove(t.id) }
                                else { selectedIds.insert(t.id) }
                            } else {
                                selectedItem = selectedItem?.id == t.id ? nil : t
                            }
                        }
                        .listRowBackground(
                            (isSelecting ? selectedIds.contains(t.id) : selectedItem?.id == t.id)
                                ? Color.mmPrimary.opacity(0.1) : Color.clear
                        )
                        .listRowSeparator(.hidden)
                        .overlay(alignment: .leading) {
                            if isSelecting {
                                Image(systemName: selectedIds.contains(t.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIds.contains(t.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                    .font(.system(size: 20))
                                    .padding(.leading, 20)
                            }
                        }
                        .onAppear {
                            if t.id == vm.transactions.last?.id {
                                Task { await vm.fetchAll() }
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.mmBackground)
        .refreshable {
            async let a: () = vm.fetchAll(refresh: true)
            async let b: () = vm.fetchMainCashBalance()
            _ = await (a, b)
        }
        .navigationTitle("Cash Transfers").navigationBarTitleDisplayMode(.inline)
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
            CashTransactionFormView {
                async let a: () = vm.fetchAll(refresh: true)
                async let b: () = vm.fetchMainCashBalance()
                _ = await (a, b)
            }
        }
        .alert(item: $deleteAlert) { t in
            Alert(
                title: Text("Delete Transfer?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.delete(t.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) transfer(s)?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDelete(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
        .task {
            async let a: () = vm.fetchAll()
            async let b: () = vm.fetchMainCashBalance()
            _ = await (a, b)
        }
    }
}

struct CashTxRow: View {
    let tx: CashTransaction

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.toExternalAccountName ?? "External").font(.system(size: 14, weight: .semibold))
                    Text("\(tx.fromLabel) → \(tx.toLabel)").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    if let n = tx.notes { Text(n).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary) }
                    Text((tx.createdAt ?? "").displayDateTime).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text(tx.amount.currency).font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct CashTransactionFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () async -> Void

    @StateObject private var vm = CashTransactionViewModel()
    @State private var amount = ""
    @State private var notes = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Transfer Details") {
                    LabeledContent("Main Cash Balance") {
                        Text(vm.mainCashBalance.currency)
                            .foregroundStyle(Color.mmPrimary)
                            .fontWeight(.semibold)
                    }
                    MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(label: "Notes (optional)", text: $notes)
                }
                if let e = error { Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) } }
            }
            .navigationTitle("New Cash Transfer").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || amount.isEmpty)
                }
            }
            .task { await vm.fetchMainCashBalance() }
        }
    }

    private func save() async {
        guard let amt = Double(amount) else { error = "Enter a valid amount"; return }
        do {
            let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10).description
            try await vm.create(fromAccountType: "main", toAccountType: nil,
                                toExternalAccountId: nil, amount: amt,
                                notes: notes.isEmpty ? nil : notes, transactionDate: dateStr)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

