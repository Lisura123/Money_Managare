import SwiftUI

// MARK: - Records / Verify Hub
//
// Centralised place to view & verify all financial records:
//   • Cash Entries, Bank Entries, Cash Adjustments, Bank Adjustments, Self Transactions
//   • Total Cash / Total Bank / Total Mano's amounts
// All filtered by either a single date or a date range.

private enum RecordsDateMode: String, CaseIterable {
    case single = "Single Date"
    case range  = "Date Range"
}

private enum RecordsTab: String, CaseIterable, Identifiable {
    case cashEntries    = "Cash Entries"
    case bankEntries    = "Bank Entries"
    case cashAdj        = "Cash Adjustments"
    case bankAdj        = "Bank Adjustments"
    case selfTx         = "Self Transactions"
    case balanceUpdates = "Balance Updates"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cashEntries:    return "banknote.fill"
        case .bankEntries:    return "creditcard.fill"
        case .cashAdj:        return "slider.horizontal.3"
        case .bankAdj:        return "slider.horizontal.below.rectangle"
        case .selfTx:         return "arrow.left.arrow.right"
        case .balanceUpdates: return "pencil.and.list.clipboard"
        }
    }

    /// Short label used inside the section summary header.
    var shortLabel: String {
        switch self {
        case .cashEntries:    return "cash entries"
        case .bankEntries:    return "bank entries"
        case .cashAdj:        return "cash adjustments"
        case .bankAdj:        return "bank adjustments"
        case .selfTx:         return "self transactions"
        case .balanceUpdates: return "balance updates"
        }
    }
}

private struct RecordsTotals: Decodable {
    let cashTotal: Double
    let manoTotal: Double
    let bankTotal: Double

    enum CodingKeys: String, CodingKey {
        case cashTotal = "cash_total"
        case manoTotal = "mano_total"
        case bankTotal = "bank_total"
    }
}

struct RecordsView: View {
    @StateObject private var cashVM = CashEntryViewModel()
    @StateObject private var cardVM = CardEntryViewModel()
    @StateObject private var selfVM = SelfTransactionViewModel()
    @StateObject private var buVM   = BalanceUpdateViewModel()

    @State private var dateMode: RecordsDateMode = .single
    @State private var singleDate = Date()
    @State private var fromDate   = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var toDate     = Date()

    @State private var tab: RecordsTab = .cashEntries

    @State private var totals: RecordsTotals?
    @State private var isLoading = false
    @State private var error: String?

    // Multi-select / delete
    @State private var isSelecting = false
    @State private var selectedIds = Set<Int>()
    @State private var bulkDeleteAlert = false

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    // Resolved query params for the current filter selection.
    private var queryParams: (date: String?, from: String?, to: String?) {
        switch dateMode {
        case .single:
            return (fmt.string(from: singleDate), nil, nil)
        case .range:
            return (nil, fmt.string(from: fromDate), fmt.string(from: toDate))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                filterCard
                totalsCards
                if let e = error { ErrorBanner(message: e) }
                tabPicker
                sectionSummary
                recordsList
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle("Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { selectionToolbar }
        .alert("Delete \(selectedIds.count) record\(selectedIds.count == 1 ? "" : "s")?", isPresented: $bulkDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await deleteSelected() } }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone.") }
        .task { await loadAll() }
        .refreshable { await loadAll() }
    }

    // MARK: - Selection toolbar

    @ToolbarContentBuilder
    private var selectionToolbar: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { exitSelection() }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(selectedIds.count == currentIds.count ? "Deselect All" : "Select All") {
                    if selectedIds.count == currentIds.count { selectedIds = [] }
                    else { selectedIds = Set(currentIds) }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Delete (\(selectedIds.count))") { bulkDeleteAlert = true }
                    .foregroundStyle(Color.mmError)
                    .disabled(selectedIds.isEmpty)
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                Button { isSelecting = true } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
                .disabled(currentIds.isEmpty)
            }
        }
    }

    // MARK: - Filter

    private var filterCard: some View {
        RowCard {
            VStack(spacing: 12) {
                Picker("Mode", selection: $dateMode) {
                    ForEach(RecordsDateMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Divider()

                switch dateMode {
                case .single:
                    DatePicker("Date", selection: $singleDate, displayedComponents: .date)
                case .range:
                    DatePicker("From", selection: $fromDate, displayedComponents: .date)
                    Divider()
                    DatePicker("To",   selection: $toDate,   displayedComponents: .date)
                }

                MMButton(title: "Apply Filter", isLoading: isLoading) {
                    Task { await loadAll() }
                }
            }
        }
    }

    // MARK: - Totals

    private var totalsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            RecordsStatCard(title: "Total Cash",   value: totals?.cashTotal ?? 0, color: Color.mmPrimary,      icon: "banknote.fill")
            RecordsStatCard(title: "Total Bank",   value: totals?.bankTotal ?? 0, color: Color(hex: "6366F1"), icon: "creditcard.fill")
            RecordsStatCard(title: "Total Mano's", value: totals?.manoTotal ?? 0, color: Color.mmAccent,       icon: "person.fill")
        }
    }

    // MARK: - Tab selector

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecordsTab.allCases) { t in
                    Button {
                        tab = t
                        exitSelection()
                    } label: {
                        Label(t.rawValue, systemImage: t.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(tab == t ? Color.mmPrimary : Color.mmCard)
                            .foregroundStyle(tab == t ? .white : Color.mmTextSecondary)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    // MARK: - Section summary (count + total for the active tab)

    private var sectionSummary: some View {
        let info = currentSectionInfo
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mmTextPrimary)
                Text("\(info.count) \(info.count == 1 ? String(tab.shortLabel.dropLast()) : tab.shortLabel)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(info.totalLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.mmTextSecondary)
                Text(info.total.currency)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmPrimary)
                    .minimumScaleFactor(0.6).lineLimit(1)
            }
        }
        .padding(14)
        .background(Color.mmCard)
        .cornerRadius(12)
    }

    /// Count + total + label for the currently selected tab.
    private var currentSectionInfo: (count: Int, total: Double, totalLabel: String) {
        switch tab {
        case .cashEntries:
            return (cashVM.totalEntries, cashVM.totalAmount, "Total in range")
        case .bankEntries:
            return (cardVM.totalEntries, cardVM.totalAmount, "Total in range")
        case .cashAdj:
            let t = cashVM.adjustments.reduce(0) { $0 + $1.adjustedAmount }
            return (cashVM.adjustments.count, t, "Net adjustment")
        case .bankAdj:
            let t = cardVM.adjustments.reduce(0) { $0 + $1.adjustedAmount }
            return (cardVM.adjustments.count, t, "Net adjustment")
        case .selfTx:
            let t = selfVM.transactions.reduce(0) { $0 + $1.amount }
            return (selfVM.transactions.count, t, "Total transferred")
        case .balanceUpdates:
            let t = buVM.updates.reduce(0) { $0 + $1.changeAmount }
            return (buVM.updates.count, t, "Net change")
        }
    }

    // MARK: - Records list

    @ViewBuilder
    private var recordsList: some View {
        LazyVStack(spacing: 0) {
            switch tab {
            case .cashEntries:
                if cashVM.entries.isEmpty { emptyState }
                else { ForEach(cashVM.entries) { e in selectable(e.id) { AdminCashEntryRow(entry: e) } } }
            case .bankEntries:
                if cardVM.entries.isEmpty { emptyState }
                else { ForEach(cardVM.entries) { e in selectable(e.id) { AdminCardEntryRow(entry: e) } } }
            case .cashAdj:
                if cashVM.adjustments.isEmpty { emptyState }
                else { ForEach(cashVM.adjustments) { a in selectable(a.id) { CashAdjRow(adj: a) } } }
            case .bankAdj:
                if cardVM.adjustments.isEmpty { emptyState }
                else { ForEach(cardVM.adjustments) { a in selectable(a.id) { CardAdjRow(adj: a) } } }
            case .selfTx:
                if selfVM.transactions.isEmpty { emptyState }
                else { ForEach(selfVM.transactions) { t in selectable(t.id) { SelfTxRow(tx: t) } } }
            case .balanceUpdates:
                if buVM.updates.isEmpty { emptyState }
                else { ForEach(buVM.updates) { u in selectable(u.id) { BalanceUpdateRow(update: u) } } }
            }
        }
    }

    /// Wraps a record row with a selection checkbox + tap-to-toggle when in selection mode.
    @ViewBuilder
    private func selectable<Content: View>(_ id: Int, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            if isSelecting {
                Image(systemName: selectedIds.contains(id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selectedIds.contains(id) ? Color.mmPrimary : Color.mmTextSecondary)
                    .padding(.leading, 4)
            }
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelecting && selectedIds.contains(id) ? Color.mmPrimary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { if isSelecting { toggle(id) } }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray").font(.system(size: 28)).foregroundStyle(Color.mmTextSecondary)
            Text("No records for this period")
                .font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Selection helpers

    /// IDs of every record currently shown in the active tab.
    private var currentIds: [Int] {
        switch tab {
        case .cashEntries:    return cashVM.entries.map { $0.id }
        case .bankEntries:    return cardVM.entries.map { $0.id }
        case .cashAdj:        return cashVM.adjustments.map { $0.id }
        case .bankAdj:        return cardVM.adjustments.map { $0.id }
        case .selfTx:         return selfVM.transactions.map { $0.id }
        case .balanceUpdates: return buVM.updates.map { $0.id }
        }
    }

    private func toggle(_ id: Int) {
        if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
    }

    private func exitSelection() {
        isSelecting = false
        selectedIds = []
    }

    private func deleteSelected() async {
        let ids = Array(selectedIds)
        guard !ids.isEmpty else { return }
        do {
            switch tab {
            case .cashEntries:    try await cashVM.bulkDeleteEntries(ids)
            case .bankEntries:    try await cardVM.bulkDeleteEntries(ids)
            case .cashAdj:        try await cashVM.bulkDeleteAdjustments(ids)
            case .bankAdj:        try await cardVM.bulkDeleteAdjustments(ids)
            case .selfTx:         try await selfVM.bulkDelete(ids)
            case .balanceUpdates: try await buVM.bulkDelete(ids)
            }
        } catch {
            self.error = error.localizedDescription
        }
        exitSelection()
        await loadAll()
    }

    // MARK: - Loading

    private func loadAll() async {
        isLoading = true; error = nil
        defer { isLoading = false }

        let p = queryParams

        // Totals
        var q: [String: Any] = [:]
        if let d = p.date { q["date"] = d }
        if let f = p.from { q["from"] = f }
        if let t = p.to   { q["to"]   = t }
        do {
            totals = try await APIService.shared.get("/admin/records-summary", query: q)
        } catch {
            self.error = error.localizedDescription
        }

        // Lists
        await cashVM.fetchEntries(date: p.date, from: p.from, to: p.to, refresh: true)
        await cardVM.fetchEntries(date: p.date, from: p.from, to: p.to, refresh: true)
        await cashVM.fetchAdjustments(date: p.date, from: p.from, to: p.to)
        await cardVM.fetchAdjustments(date: p.date, from: p.from, to: p.to)
        await selfVM.fetchAll(date: p.date, from: p.from, to: p.to, refresh: true)
        await buVM.fetchAll(date: p.date, from: p.from, to: p.to, refresh: true)
    }
}

// MARK: - Stat Card

private struct RecordsStatCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .cornerRadius(7)
            Text(title).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
            Text(value.currency)
                .font(.system(size: 15, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.6).lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Balance Update Row

struct BalanceUpdateRow: View {
    let update: BalanceUpdate

    private var isIncrease: Bool { update.changeAmount >= 0 }
    private var changeColor: Color { isIncrease ? Color.mmSuccess : Color.mmError }

    private var displayDate: String {
        guard let raw = update.createdAt else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsed = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
        guard let d = parsed else { return String(raw.prefix(16).replacingOccurrences(of: "T", with: " ")) }
        let out = DateFormatter()
        out.dateFormat = "MMM d, yyyy • h:mm a"
        return out.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: update.accountType == "bank" ? "creditcard.fill" : "banknote.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmPrimary)
                    .frame(width: 30, height: 30)
                    .background(Color.mmPrimary.opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(update.accountLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mmTextPrimary)
                    HStack(spacing: 6) {
                        Text(update.accountTypeLabel)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.mmPrimary.opacity(0.10))
                            .foregroundStyle(Color.mmPrimary)
                            .cornerRadius(5)
                        if let s = update.showroomName {
                            Text(s)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.mmTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text((isIncrease ? "+" : "") + update.changeAmount.currency)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(changeColor)
                    Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(changeColor)
                }
            }

            HStack(spacing: 8) {
                amountChip(title: "Previous", value: update.previousAmount)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmTextSecondary)
                amountChip(title: "Updated", value: update.newAmount)
            }

            if let r = update.reason, !r.isEmpty {
                Text(r)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmTextSecondary)
            }

            HStack {
                if let u = update.userName {
                    Label(u, systemImage: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Text(displayDate)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mmDivider.opacity(0.7), lineWidth: 1))
        .padding(.bottom, 8)
    }

    private func amountChip(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
            Text(value.currency)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.mmBackground)
        .cornerRadius(8)
    }
}

