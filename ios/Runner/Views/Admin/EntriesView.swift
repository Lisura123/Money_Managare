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
    @State private var selectedItem: DailyCashEntry?
    @State private var deleteAlert: DailyCashEntry?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false
    @State private var showAddEntry = false

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    if selectedIds.contains(e.id) { selectedIds.remove(e.id) }
                                    else { selectedIds.insert(e.id) }
                                } else {
                                    selectedItem = selectedItem?.id == e.id ? nil : e
                                }
                            }
                            .listRowBackground(
                                (isSelecting ? selectedIds.contains(e.id) : selectedItem?.id == e.id)
                                    ? Color.mmPrimary.opacity(0.1) : Color.clear
                            )
                            .listRowSeparator(.hidden)
                            .overlay(alignment: .leading) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(e.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(e.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                        .padding(.leading, 20)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !e.isLocked && !isSelecting {
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
                    Button { showAddEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
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
        .sheet(isPresented: $showAddEntry) {
            AdminAddCashEntryView(showrooms: showroomVM.showrooms) {
                await vm.fetchEntries(showroomId: filterShowroomId, refresh: true)
            }
        }
        .sheet(item: $editTarget) { e in
            EditCashEntryView(entry: e) { await vm.fetchEntries(showroomId: filterShowroomId, refresh: true) }
        }
        .alert(item: $deleteAlert) { e in
            Alert(
                title: Text("Delete Entry?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.deleteEntry(e.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) entr\(selectedIds.count == 1 ? "y" : "ies")?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDeleteEntries(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
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
    @State private var selectedItem: DailyCardEntry?
    @State private var deleteAlert: DailyCardEntry?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false
    @State private var showAddEntry = false

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    if selectedIds.contains(e.id) { selectedIds.remove(e.id) }
                                    else { selectedIds.insert(e.id) }
                                } else {
                                    selectedItem = selectedItem?.id == e.id ? nil : e
                                }
                            }
                            .listRowBackground(
                                (isSelecting ? selectedIds.contains(e.id) : selectedItem?.id == e.id)
                                    ? Color.mmPrimary.opacity(0.1) : Color.clear
                            )
                            .listRowSeparator(.hidden)
                            .overlay(alignment: .leading) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(e.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(e.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                        .padding(.leading, 20)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !e.isLocked && !isSelecting {
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
                    Button { showAddEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("All") { filterShowroomId = nil; Task { await vm.fetchEntries(showroomId: nil, refresh: true) } }
                        ForEach(showroomVM.showrooms) { s in
                            Button(s.name) { filterShowroomId = s.id; Task { await vm.fetchEntries(showroomId: s.id, refresh: true) } }
                        }
                    } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
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
        .sheet(isPresented: $showAddEntry) {
            AdminAddCardEntryView(showrooms: showroomVM.showrooms) {
                await vm.fetchEntries(showroomId: filterShowroomId, refresh: true)
            }
        }
        .sheet(item: $editTarget) { e in
            EditCardEntryView(entry: e) { await vm.fetchEntries(showroomId: filterShowroomId, refresh: true) }
        }
        .alert(item: $deleteAlert) { e in
            Alert(
                title: Text("Delete Entry?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.deleteEntry(e.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) entr\(selectedIds.count == 1 ? "y" : "ies")?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDeleteEntries(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
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
    @State private var selectedItem: AdminCashAdjustment?
    @State private var deleteAlert: AdminCashAdjustment?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    if selectedIds.contains(adj.id) { selectedIds.remove(adj.id) }
                                    else { selectedIds.insert(adj.id) }
                                } else {
                                    selectedItem = selectedItem?.id == adj.id ? nil : adj
                                }
                            }
                            .listRowBackground(
                                (isSelecting ? selectedIds.contains(adj.id) : selectedItem?.id == adj.id)
                                    ? Color.mmPrimary.opacity(0.1) : Color.clear
                            )
                            .listRowSeparator(.hidden)
                            .overlay(alignment: .leading) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(adj.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(adj.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                        .padding(.leading, 20)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAdjustments() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Cash Adjustments").navigationBarTitleDisplayMode(.inline)
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
                    Button { showForm = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary) }
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
            CashAdjustmentFormView { await vm.fetchAdjustments() }
        }
        .alert(item: $deleteAlert) { adj in
            Alert(
                title: Text("Delete Adjustment?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.deleteAdjustment(adj.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) adjustment(s)?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDeleteAdjustments(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
        .task { await vm.fetchAdjustments() }
    }
}

struct CashAdjRow: View {
    let adj: AdminCashAdjustment

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(adj.cashAccountType == "mano" ? "Mano Cash" : "Main Cash")
                        .font(.system(size: 14, weight: .semibold))
                    if let r = adj.reason, !r.isEmpty {
                        Text(r).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    }
                    Text((adj.createdAt ?? "").displayDateTime)
                        .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text(adj.adjustedAmount >= 0
                     ? "+\(adj.adjustedAmount.currency)"
                     : adj.adjustedAmount.currency)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(adj.adjustedAmount >= 0 ? Color.mmSuccess : Color.mmError)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct CashAdjustmentFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () async -> Void

    @StateObject private var vm = CashEntryViewModel()
    @State private var accountType = "main"
    @State private var sign = "add"
    @State private var amount = ""
    @State private var reason = ""
    @State private var error: String?

    private var currentBalance: Double {
        accountType == "mano" ? vm.manoCashBalance : vm.mainCashBalance
    }

    private var signedAmount: Double {
        let amt = Double(amount) ?? 0
        return sign == "add" ? amt : -amt
    }

    private var newBalance: Double { currentBalance + signedAmount }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Picker("Type", selection: $accountType) {
                        Text("Main Cash").tag("main")
                        Text("Mano Cash").tag("mano")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: accountType) { _ in
                        Task { await vm.fetchCashBalances() }
                    }

                    LabeledContent("Current Balance") {
                        if vm.mainCashBalance == 0 && vm.manoCashBalance == 0 && vm.isLoading {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Text(currentBalance.currency)
                                .fontWeight(.semibold).foregroundStyle(Color.mmPrimary)
                        }
                    }
                }

                Section("Adjustment") {
                    Picker("Operation", selection: $sign) {
                        Text("Add (+)").tag("add")
                        Text("Deduct (−)").tag("deduct")
                    }
                    .pickerStyle(.segmented)

                    MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                    MMTextField(label: "Reason", text: $reason)
                }

                if !amount.isEmpty, let amt = Double(amount), amt > 0 {
                    Section("Preview") {
                        LabeledContent("New Balance") {
                            Text(newBalance.currency)
                                .fontWeight(.bold)
                                .foregroundStyle(newBalance >= 0 ? Color.mmSuccess : Color.mmError)
                        }
                    }
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
                        .disabled(vm.isSubmitting || amount.isEmpty || reason.isEmpty)
                }
            }
            .task { await vm.fetchCashBalances() }
        }
    }

    private func save() async {
        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount"; return }
        guard !reason.isEmpty else { error = "Reason is required"; return }
        do {
            try await vm.createAdjustment(
                adjustedAmount: signedAmount,
                reason: reason,
                cashAccountType: accountType
            )
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

// MARK: - Card Adjustments

struct CardAdjustmentsView: View {
    @StateObject private var vm = CardEntryViewModel()
    @State private var showForm = false
    @State private var selectedItem: AdminCardAdjustment?
    @State private var deleteAlert: AdminCardAdjustment?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    if selectedIds.contains(adj.id) { selectedIds.remove(adj.id) }
                                    else { selectedIds.insert(adj.id) }
                                } else {
                                    selectedItem = selectedItem?.id == adj.id ? nil : adj
                                }
                            }
                            .listRowBackground(
                                (isSelecting ? selectedIds.contains(adj.id) : selectedItem?.id == adj.id)
                                    ? Color.mmPrimary.opacity(0.1) : Color.clear
                            )
                            .listRowSeparator(.hidden)
                            .overlay(alignment: .leading) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(adj.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(adj.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                        .font(.system(size: 20))
                                        .padding(.leading, 20)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.fetchAdjustments() }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Card Adjustments").navigationBarTitleDisplayMode(.inline)
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
                    Button { showForm = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Color.mmPrimary) }
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
            CardAdjustmentFormView { await vm.fetchAdjustments() }
        }
        .alert(item: $deleteAlert) { adj in
            Alert(
                title: Text("Delete Adjustment?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { try? await vm.deleteAdjustment(adj.id); selectedItem = nil }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete \(selectedIds.count) adjustment(s)?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) {
                let ids = Array(selectedIds)
                Task { try? await vm.bulkDeleteAdjustments(ids); isSelecting = false; selectedIds = [] }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
        .task { await vm.fetchAdjustments() }
    }
}

struct CardAdjRow: View {
    let adj: AdminCardAdjustment

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(adj.accountLabel).font(.system(size: 14, weight: .semibold))
                    Text(adj.reason ?? "").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    Text((adj.createdAt ?? "").displayDateTime).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text((adj.adjustedAmount >= 0 ? "+" : "") + adj.adjustedAmount.currency)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(adj.adjustedAmount >= 0 ? Color.mmSuccess : Color.mmError)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

struct CardAdjustmentFormView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () async -> Void

    @StateObject private var accountVM = CardAccountViewModel()
    @StateObject private var entryVM = CardEntryViewModel()
    @State private var selectedShowroom = ""
    @State private var selectedAccountId: Int? = nil
    @State private var sign = "add"
    @State private var amount = ""
    @State private var reason = ""
    @State private var error: String?

    private var uniqueShowrooms: [String] {
        Array(Set(accountVM.accounts.map { $0.showroomName ?? "" })).filter { !$0.isEmpty }.sorted()
    }

    private var filteredAccounts: [CardAccount] {
        accountVM.accounts.filter { $0.showroomName == selectedShowroom }
    }

    private var selectedAccount: CardAccount? {
        guard let id = selectedAccountId else { return nil }
        return accountVM.accounts.first { $0.id == id }
    }

    private var signedAmount: Double {
        let amt = Double(amount) ?? 0
        return sign == "add" ? amt : -amt
    }

    private var newBalance: Double {
        (selectedAccount?.currentBalance ?? 0) + signedAmount
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Showroom") {
                    if accountVM.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Picker("Showroom", selection: $selectedShowroom) {
                            Text("Select Showroom").tag("")
                            ForEach(uniqueShowrooms, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .onChange(of: selectedShowroom) { _ in selectedAccountId = nil }
                    }
                }

                if !selectedShowroom.isEmpty {
                    Section("Card Account") {
                        Picker("Account", selection: $selectedAccountId) {
                            Text("Select Account").tag(nil as Int?)
                            ForEach(filteredAccounts) { acc in
                                Text(acc.displayLabel).tag(acc.id as Int?)
                            }
                        }
                        if let acc = selectedAccount {
                            LabeledContent("Current Balance") {
                                Text(acc.currentBalance.currency)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.mmPrimary)
                            }
                        }
                    }
                }

                if selectedAccountId != nil {
                    Section("Adjustment") {
                        Picker("Operation", selection: $sign) {
                            Text("Add (+)").tag("add")
                            Text("Deduct (−)").tag("deduct")
                        }
                        .pickerStyle(.segmented)
                        MMTextField(label: "Amount", text: $amount, keyboardType: .decimalPad)
                        MMTextField(label: "Reason", text: $reason)
                    }

                    if !amount.isEmpty, let amt = Double(amount), amt > 0 {
                        Section("Preview") {
                            LabeledContent("New Balance") {
                                Text(newBalance.currency).fontWeight(.bold)
                                    .foregroundStyle(newBalance >= 0 ? Color.mmSuccess : Color.mmError)
                            }
                        }
                    }
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
                        .disabled(entryVM.isSubmitting || selectedAccountId == nil || amount.isEmpty || reason.isEmpty)
                }
            }
            .task { await accountVM.fetchAll() }
        }
    }

    private func save() async {
        guard let id = selectedAccountId else { error = "Select a card account"; return }
        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount"; return }
        guard !reason.isEmpty else { error = "Reason is required"; return }
        do {
            try await entryVM.createAdjustmentForAccount(cardAccountId: id, adjustedAmount: signedAmount, reason: reason)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

// MARK: - Admin Add Cash Entry

struct AdminAddCashEntryView: View {
    @Environment(\.dismiss) var dismiss
    let showrooms: [Showroom]
    let onSave: () async -> Void

    @StateObject private var vm = CashEntryViewModel()
    @State private var selectedShowroomId: Int?
    @State private var selectedAccount: String = "main"
    @State private var mainAmount = ""
    @State private var manoAmount = ""
    @State private var mainNotes  = ""
    @State private var manoNotes  = ""
    @State private var entryDate  = Date()
    @State private var error: String?
    @State private var success    = false
    private static let largeThreshold: Double = 1_000_000
    @State private var showLargeAmountConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = error { ErrorBanner(message: e) { error = nil } }
                    if success {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
                            Text("Entries submitted successfully").foregroundStyle(Color.mmSuccess)
                        }
                        .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
                    }

                    // Showroom picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Showroom", systemImage: "building.2")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                        Picker("Showroom", selection: $selectedShowroomId) {
                            Text("Select showroom…").tag(Optional<Int>.none)
                            ForEach(showrooms) { s in Text(s.name).tag(Optional(s.id)) }
                        }
                        .pickerStyle(.menu)
                        .padding(12).background(Color.mmInputFill).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                    }
                    .padding(16).background(Color.mmCard).cornerRadius(14)

                    // Entry date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry Date").font(.system(size: 13, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                        DatePicker("", selection: $entryDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(12).background(Color.mmInputFill).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                    }
                    .padding(16).background(Color.mmCard).cornerRadius(14)

                    // Account selector
                    Picker("Account", selection: $selectedAccount) {
                        Label("Main Cash",   systemImage: "banknote").tag("main")
                        Label("Mano's Cash", systemImage: "person.crop.circle.badge.checkmark").tag("mano")
                    }
                    .pickerStyle(.segmented).padding(.vertical, 4)

                    // Entry form
                    if selectedAccount == "main" {
                        adminCashSection(title: "Main Cash Account", icon: "banknote",
                                         amount: $mainAmount, notes: $mainNotes, accountType: "main")
                    } else {
                        adminCashSection(title: "Mano's Cash Account", icon: "person.crop.circle.badge.checkmark",
                                         amount: $manoAmount, notes: $manoNotes, accountType: "mano")
                    }

                    MMButton(title: "Submit Entries", isLoading: vm.isSubmitting) {
                        let m = Double(mainAmount) ?? -1
                        let n = Double(manoAmount) ?? -1
                        if m >= Self.largeThreshold || n >= Self.largeThreshold { showLargeAmountConfirm = true }
                        else { Task { await submit() } }
                    }
                    .disabled(selectedShowroomId == nil)
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Add Cash Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .confirmationDialog("Large Amount", isPresented: $showLargeAmountConfirm, titleVisibility: .visible) {
                Button("Submit Anyway", role: .destructive) { Task { await submit() } }
                Button("Cancel", role: .cancel) {}
            } message: { Text("One or more amounts are ≥ Rs. 1,000,000. Are you sure?") }
        }
    }

    @ViewBuilder
    private func adminCashSection(title: String, icon: String,
                                   amount: Binding<String>, notes: Binding<String>,
                                   accountType: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)
            MMTextField(label: "Amount", text: amount, placeholder: "0.00",
                        keyboardType: .decimalPad, autocapitalization: .never)
            MMTextField(label: "Notes (optional)", text: notes, placeholder: "Any remarks...")
        }
        .padding(16).background(Color.mmCard).cornerRadius(14)
    }

    private func submit() async {
        guard let sId = selectedShowroomId else { error = "Select a showroom."; return }
        let mainAmt = Double(mainAmount) ?? -1
        let manoAmt = Double(manoAmount) ?? -1
        guard mainAmt >= 0 || manoAmt >= 0 else { error = "Enter at least one valid amount."; return }
        let dateStr: String = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: entryDate) }()
        error = nil
        do {
            if mainAmt >= 0 {
                try await vm.submit(showroomId: sId, cashAmount: mainAmt,
                                    notes: mainNotes.isEmpty ? nil : mainNotes,
                                    cashAccountType: "main", entryDate: dateStr)
            }
            if manoAmt >= 0 {
                try await vm.submit(showroomId: sId, cashAmount: manoAmt,
                                    notes: manoNotes.isEmpty ? nil : manoNotes,
                                    cashAccountType: "mano", entryDate: dateStr)
            }
            success = true
            mainAmount = ""; manoAmount = ""; mainNotes = ""; manoNotes = ""
            await onSave()
        } catch { self.error = error.localizedDescription }
    }
}

// MARK: - Admin Add Card Entry

struct AdminAddCardEntryView: View {
    @Environment(\.dismiss) var dismiss
    let showrooms: [Showroom]
    let onSave: () async -> Void

    @StateObject private var vm        = CardEntryViewModel()
    @StateObject private var accountVM = CardAccountViewModel()
    @State private var selectedShowroomId: Int?
    @State private var selectedAccountId: Int?
    @State private var amount    = ""
    @State private var notes     = ""
    @State private var entryDate = Date()
    @State private var error: String?
    @State private var success   = false
    private static let largeThreshold: Double = 1_000_000
    @State private var showLargeAmountConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = error { ErrorBanner(message: e) { error = nil } }
                    if success {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
                            Text("Card entry submitted").foregroundStyle(Color.mmSuccess)
                        }
                        .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
                    }

                    // Showroom picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Showroom", systemImage: "building.2")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                        Picker("Showroom", selection: $selectedShowroomId) {
                            Text("Select showroom…").tag(Optional<Int>.none)
                            ForEach(showrooms) { s in Text(s.name).tag(Optional(s.id)) }
                        }
                        .pickerStyle(.menu)
                        .padding(12).background(Color.mmInputFill).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                    }
                    .padding(16).background(Color.mmCard).cornerRadius(14)
                    .onChange(of: selectedShowroomId) { _ in
                        selectedAccountId = nil
                        if let sId = selectedShowroomId {
                            Task { await accountVM.fetchAll(showroomId: sId) }
                        }
                    }

                    // Entry date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry Date").font(.system(size: 13, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                        DatePicker("", selection: $entryDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(12).background(Color.mmInputFill).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                    }
                    .padding(16).background(Color.mmCard).cornerRadius(14)

                    // Card account + amount
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Card Account", systemImage: "creditcard")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)

                        if accountVM.isLoading {
                            ProgressView()
                        } else if selectedShowroomId == nil {
                            Text("Select a showroom first.")
                                .font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                        } else if accountVM.accounts.isEmpty {
                            Text("No active card accounts for this showroom.")
                                .font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                        } else {
                            Picker(selection: $selectedAccountId) {
                                Text("Select account…").tag(Optional<Int>.none)
                                ForEach(accountVM.accounts) { acc in
                                    Text(acc.displayLabel).tag(Optional<Int>.some(acc.id))
                                }
                            } label: { Text("Select Account") }
                            .pickerStyle(.menu)
                            .padding(12).background(Color.mmInputFill).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                        }

                        MMTextField(label: "Amount", text: $amount, placeholder: "0.00",
                                    keyboardType: .decimalPad, autocapitalization: .never)
                        MMTextField(label: "Notes (optional)", text: $notes, placeholder: "Any remarks...")
                    }
                    .padding(16).background(Color.mmCard).cornerRadius(14)

                    MMButton(title: "Submit Card Entry", isLoading: vm.isSubmitting) {
                        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount."; return }
                        if amt >= Self.largeThreshold { showLargeAmountConfirm = true }
                        else { Task { await submit() } }
                    }
                    .disabled(selectedShowroomId == nil || selectedAccountId == nil)
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Add Card Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .confirmationDialog("Large Amount", isPresented: $showLargeAmountConfirm, titleVisibility: .visible) {
                Button("Submit Anyway", role: .destructive) { Task { await submit() } }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This amount is ≥ Rs. 1,000,000. Are you sure?") }
        }
    }

    private func submit() async {
        guard let sId = selectedShowroomId else { error = "Select a showroom."; return }
        guard let accId = selectedAccountId else { error = "Select a card account."; return }
        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount."; return }
        let dateStr: String = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: entryDate) }()
        error = nil
        do {
            try await vm.submit(showroomId: sId, cardAccountId: accId,
                                amount: amt, notes: notes.isEmpty ? nil : notes,
                                entryDate: dateStr)
            success = true; amount = ""; notes = ""; selectedAccountId = nil
            await onSave()
        } catch { self.error = error.localizedDescription }
    }
}
