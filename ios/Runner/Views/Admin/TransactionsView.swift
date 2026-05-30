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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAll() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Self Transfers").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary)
                }
            }
        }
        .sheet(isPresented: $showForm) {
            SelfTransactionFormView { await vm.fetchAll(refresh: true) }
        }
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

    @StateObject private var vm = SelfTransactionViewModel()
    @StateObject private var cardVM = CardAccountViewModel()
    @StateObject private var extVM = ExternalAccountViewModel()
    @State private var fromCardId: Int?
    @State private var toDestination: ToDestination?
    @State private var amount = ""
    @State private var notes = ""
    @State private var error: String?

    /// Tagged union so one Picker can hold both card IDs and external account IDs
    enum ToDestination: Hashable {
        case card(Int)
        case external(Int)
        case other

        var label: String { "" }
    }

    var notesRequired: Bool { toDestination == .other }

    private var amountValue: Double? { Double(amount) }
    private var fromAccount: CardAccount? { cardVM.accounts.first { $0.id == fromCardId } }
    private var toCardAccount: CardAccount? {
        guard case .card(let id) = toDestination else { return nil }
        return cardVM.accounts.first { $0.id == id }
    }
    private var toExtAccount: ExternalAccount? {
        guard case .external(let id) = toDestination else { return nil }
        return extVM.accounts.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Transfer Details") {
                    Picker(selection: $fromCardId) {
                        Text("Select…").tag(Optional<Int>.none)
                        ForEach(cardVM.accounts) { a in
                            Text("\(a.displayLabel) (\(a.currentBalance.currency))").tag(Optional<Int>.some(a.id))
                        }
                    } label: { Text("From Card") }

                    Picker(selection: $toDestination) {
                        Text("Select…").tag(Optional<ToDestination>.none)
                        if !cardVM.accounts.isEmpty {
                            Section("Card Accounts") {
                                ForEach(cardVM.accounts) { a in
                                    Text("\(a.displayLabel) (\(a.currentBalance.currency))")
                                        .tag(Optional<ToDestination>.some(.card(a.id)))
                                }
                            }
                        }
                        if !extVM.accounts.isEmpty {
                            Section("External Accounts") {
                                ForEach(extVM.accounts) { a in
                                    Text("\(a.name) (\(a.balance.currency))")
                                        .tag(Optional<ToDestination>.some(.external(a.id)))
                                }
                            }
                        }
                        Section("") {
                            Text("Other").tag(Optional<ToDestination>.some(.other))
                        }
                    } label: { Text("To") }

                    MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(
                        label: notesRequired ? "Notes (required)" : "Notes (optional)",
                        text: $notes
                    )
                    if notesRequired && notes.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Notes are required for this destination")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mmError)
                    }
                }
                if let from = fromAccount, let amt = amountValue, amt > 0 {
                    Section("Balance Preview") {
                        BalancePreviewRow(label: "From", name: from.displayLabel,
                                         before: from.currentBalance, after: from.currentBalance - amt,
                                         isIncrease: false)
                        if let to = toCardAccount {
                            BalancePreviewRow(label: "To", name: to.displayLabel,
                                             before: to.currentBalance, after: to.currentBalance + amt,
                                             isIncrease: true)
                        } else if let ext = toExtAccount {
                            BalancePreviewRow(label: "To", name: ext.name,
                                             before: ext.balance, after: ext.balance + amt,
                                             isIncrease: true)
                        }
                    }
                }
                if let e = error { Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) } }
            }
            .navigationTitle("New Self Transfer").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(
                            vm.isSubmitting || fromCardId == nil || toDestination == nil ||
                            amount.isEmpty ||
                            (notesRequired && notes.trimmingCharacters(in: .whitespaces).isEmpty)
                        )
                }
            }
            .task {
                async let c: () = cardVM.fetchAll()
                async let e: () = extVM.fetchAll()
                _ = await (c, e)
            }
        }
    }

    private func save() async {
        guard let fId = fromCardId, let dest = toDestination, let amt = Double(amount) else {
            error = "Fill all fields"; return
        }
        let notesVal = notes.trimmingCharacters(in: .whitespaces)
        do {
            switch dest {
            case .card(let cId):
                try await vm.create(fromId: fId, toCardId: cId, amount: amt,
                                    notes: notesVal.isEmpty ? nil : notesVal)
            case .external(let eId):
                try await vm.create(fromId: fId, toExternalId: eId, amount: amt,
                                    notes: notesVal.isEmpty ? nil : notesVal)
            case .other:
                try await vm.create(fromId: fId, amount: amt, notes: notesVal)
            }
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
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

    var body: some View {
        Group {
            if vm.isLoading && vm.transactions.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.transactions.isEmpty {
                EmptyStateView(icon: "arrow.left.arrow.right.circle.fill", message: "No cash transfers")
            } else {
                List {
                    ForEach(vm.transactions) { t in
                        CashTxRow(tx: t)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAll() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Cash Transfers").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary)
                }
            }
        }
        .sheet(isPresented: $showForm) {
            CashTransactionFormView { await vm.fetchAll() }
        }
        .task { await vm.fetchAll() }
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
    @State private var selectedExtId: Int?
    @State private var type = "in"
    @State private var amount = ""
    @State private var notes = ""
    @State private var error: String?

    private let types = ["in", "out"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Transfer Details") {
                    Picker("External Account", selection: $selectedExtId) {
                        Text("Select…").tag(Optional<Int>.none)
                        ForEach(vm.externalAccounts) { a in Text(a.name).tag(Optional(a.id)) }
                    }
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { Text($0.capitalized).tag($0) }
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
                        .disabled(vm.isSubmitting || selectedExtId == nil || amount.isEmpty)
                }
            }
            .task { await vm.fetchExternalAccounts() }
        }
    }

    private func save() async {
        guard let extId = selectedExtId, let amt = Double(amount) else { error = "Fill all fields"; return }
        do {
            let fromType = type == "in" ? "external" : "main_cash"
            let toType: String? = type == "in" ? "main_cash" : nil
            let toExtId: Int? = type == "in" ? nil : extId
            let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10).description
            try await vm.create(fromAccountType: fromType, toAccountType: toType,
                                toExternalAccountId: toExtId, amount: amt,
                                notes: notes.isEmpty ? nil : notes, transactionDate: dateStr)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
