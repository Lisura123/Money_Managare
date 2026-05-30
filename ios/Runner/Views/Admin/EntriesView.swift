import SwiftUI

struct EntriesHubView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: CashEntriesAdminView()) {
                    Label("Cash Entries", systemImage: "banknote")
                }
                NavigationLink(destination: CardEntriesAdminView()) {
                    Label("Card Entries", systemImage: "creditcard")
                }
                NavigationLink(destination: CashAdjustmentsView()) {
                    Label("Cash Adjustments", systemImage: "arrow.triangle.2.circlepath.circle")
                }
                NavigationLink(destination: CardAdjustmentsView()) {
                    Label("Card Adjustments", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                }
            }
            .navigationTitle("Entries")
        }
    }
}

// MARK: - Cash Entries

struct CashEntriesAdminView: View {
    @StateObject private var vm = CashEntryViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()
    @State private var filterShowroomId: Int?
    @State private var editTarget: DailyCashEntry?

    var body: some View {
        Group {
            if vm.isLoading && vm.entries.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.entries.isEmpty {
                EmptyStateView(icon: "banknote", message: "No cash entries")
            } else {
                List {
                    ForEach(vm.entries) { e in
                        AdminCashEntryRow(entry: e)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                if !e.isLocked {
                                    Button("Edit") { editTarget = e }.tint(Color.mmPrimary)
                                }
                            }
                            .onAppear {
                                if e.id == vm.entries.last?.id {
                                    Task { await vm.fetchEntries() }
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchEntries(showroomId: filterShowroomId, refresh: true) }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Cash Entries")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("All") { filterShowroomId = nil; Task { await vm.fetchEntries(showroomId: nil, refresh: true) } }
                    ForEach(showroomVM.showrooms) { s in
                        Button(s.name) {
                            filterShowroomId = s.id
                            Task { await vm.fetchEntries(showroomId: s.id, refresh: true) }
                        }
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
        }
        .sheet(item: $editTarget) { e in
            EditCashEntryView(entry: e) { await vm.fetchEntries(showroomId: filterShowroomId, refresh: true) }
        }
        .task {
            async let c: () = vm.fetchEntries(refresh: true)
            async let s: () = showroomVM.fetchAll()
            _ = await (c, s)
        }
    }
}

struct AdminCashEntryRow: View {
    let entry: DailyCashEntry

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.entryDate.displayDate).font(.system(size: 14, weight: .semibold))
                    Text(entry.userName ?? "Unknown").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    Text(entry.showroomName ?? "—").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    Text(entry.cashAccountLabel).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.cashAmount.currency)
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
                    if entry.isLocked {
                        Label("Locked", systemImage: "lock.fill").font(.system(size: 10)).foregroundStyle(Color.mmWarning)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct EditCashEntryView: View {
    @Environment(\.dismiss) var dismiss
    let entry: DailyCashEntry
    let onSave: () async -> Void

    @StateObject private var vm = CashEntryViewModel()
    @State private var amount: String
    @State private var notes: String
    @State private var error: String?

    init(entry: DailyCashEntry, onSave: @escaping () async -> Void) {
        self.entry = entry; self.onSave = onSave
        _amount = State(initialValue: String(entry.cashAmount))
        _notes  = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Edit Cash Entry") {
                    MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(label: "Notes", text: $notes)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle("Edit Entry").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || amount.isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let amt = Double(amount) else { error = "Invalid amount"; return }
        do {
            try await vm.update(entry.id, cashAmount: amt, notes: notes.isEmpty ? nil : notes)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

// MARK: - Card Entries

struct CardEntriesAdminView: View {
    @StateObject private var vm = CardEntryViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()
    @State private var filterShowroomId: Int?
    @State private var editTarget: DailyCardEntry?

    var body: some View {
        Group {
            if vm.isLoading && vm.entries.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.entries.isEmpty {
                EmptyStateView(icon: "creditcard", message: "No card entries")
            } else {
                List {
                    ForEach(vm.entries) { e in
                        AdminCardEntryRow(entry: e)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                if !e.isLocked {
                                    Button("Edit") { editTarget = e }.tint(Color.mmPrimary)
                                }
                            }
                            .onAppear {
                                if e.id == vm.entries.last?.id {
                                    Task { await vm.fetchEntries() }
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchEntries(showroomId: filterShowroomId, refresh: true) }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Card Entries").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("All") { filterShowroomId = nil; Task { await vm.fetchEntries(showroomId: nil, refresh: true) } }
                    ForEach(showroomVM.showrooms) { s in
                        Button(s.name) { filterShowroomId = s.id; Task { await vm.fetchEntries(showroomId: s.id, refresh: true) } }
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
        }
        .sheet(item: $editTarget) { e in
            EditCardEntryView(entry: e) { await vm.fetchEntries(showroomId: filterShowroomId, refresh: true) }
        }
        .task {
            async let c: () = vm.fetchEntries(refresh: true)
            async let s: () = showroomVM.fetchAll()
            _ = await (c, s)
        }
    }
}

struct AdminCardEntryRow: View {
    let entry: DailyCardEntry

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.entryDate.displayDate).font(.system(size: 14, weight: .semibold))
                    Text(entry.userName ?? "Unknown").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    Text(entry.displayCard).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.amount.currency)
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
                    if entry.isLocked {
                        Label("Locked", systemImage: "lock.fill").font(.system(size: 10)).foregroundStyle(Color.mmWarning)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct EditCardEntryView: View {
    @Environment(\.dismiss) var dismiss
    let entry: DailyCardEntry
    let onSave: () async -> Void

    @StateObject private var vm = CardEntryViewModel()
    @State private var amount: String
    @State private var notes: String
    @State private var error: String?

    init(entry: DailyCardEntry, onSave: @escaping () async -> Void) {
        self.entry = entry; self.onSave = onSave
        _amount = State(initialValue: String(entry.amount))
        _notes  = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Edit Card Entry") {
                    MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(label: "Notes", text: $notes)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle("Edit Entry").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || amount.isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let amt = Double(amount) else { error = "Invalid amount"; return }
        do {
            try await vm.update(entry.id, amount: amt, notes: notes.isEmpty ? nil : notes)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

// MARK: - Cash Adjustments

struct CashAdjustmentsView: View {
    @StateObject private var vm = CashEntryViewModel()
    @State private var showForm = false

    var body: some View {
        Group {
            if vm.isLoading && vm.adjustments.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.adjustments.isEmpty {
                EmptyStateView(icon: "arrow.triangle.2.circlepath.circle", message: "No adjustments")
            } else {
                List {
                    ForEach(vm.adjustments) { adj in
                        CashAdjRow(adj: adj)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAdjustments() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Cash Adjustments").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary) }
            }
        }
        .sheet(isPresented: $showForm) {
            CashAdjustmentFormView { await vm.fetchAdjustments() }
        }
        .task { await vm.fetchAdjustments() }
    }
}

struct CashAdjRow: View {
    let adj: AdminCashAdjustment

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entry #\(adj.cashEntryId)").font(.system(size: 14, weight: .semibold))
                    Text(adj.reason ?? "").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    Text((adj.createdAt ?? "").displayDateTime).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text(adj.adjustedAmount.currency)
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct CashAdjustmentFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () async -> Void

    @StateObject private var vm = CashEntryViewModel()
    @State private var entryIdStr = ""
    @State private var amount = ""
    @State private var reason = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MMTextField(label: "Cash Entry ID", text: $entryIdStr, keyboardType: .numberPad)
                    MMTextField(label: "Adjusted Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(label: "Reason", text: $reason)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle("New Cash Adjustment").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || entryIdStr.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let id = Int(entryIdStr), let amt = Double(amount) else { error = "Invalid input"; return }
        do {
            try await vm.createAdjustment(cashEntryId: id, adjustedAmount: amt, reason: reason)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

// MARK: - Card Adjustments

struct CardAdjustmentsView: View {
    @StateObject private var vm = CardEntryViewModel()
    @State private var showForm = false

    var body: some View {
        Group {
            if vm.isLoading && vm.adjustments.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if vm.adjustments.isEmpty {
                EmptyStateView(icon: "arrow.triangle.2.circlepath.circle.fill", message: "No adjustments")
            } else {
                List {
                    ForEach(vm.adjustments) { adj in
                        CardAdjRow(adj: adj)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAdjustments() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Card Adjustments").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary) }
            }
        }
        .sheet(isPresented: $showForm) {
            CardAdjustmentFormView { await vm.fetchAdjustments() }
        }
        .task { await vm.fetchAdjustments() }
    }
}

struct CardAdjRow: View {
    let adj: AdminCardAdjustment

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entry #\(adj.cardEntryId)").font(.system(size: 14, weight: .semibold))
                    Text(adj.reason ?? "").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    Text((adj.createdAt ?? "").displayDateTime).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text(adj.adjustedAmount.currency)
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct CardAdjustmentFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () async -> Void

    @StateObject private var vm = CardEntryViewModel()
    @State private var entryIdStr = ""
    @State private var amount = ""
    @State private var reason = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MMTextField(label: "Card Entry ID", text: $entryIdStr, keyboardType: .numberPad)
                    MMTextField(label: "Adjusted Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(label: "Reason", text: $reason)
                }
                if let e = error {
                    Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) }
                }
            }
            .navigationTitle("New Card Adjustment").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(vm.isSubmitting || entryIdStr.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let id = Int(entryIdStr), let amt = Double(amount) else { error = "Invalid input"; return }
        do {
            try await vm.createAdjustment(cardEntryId: id, adjustedAmount: amt, reason: reason)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
