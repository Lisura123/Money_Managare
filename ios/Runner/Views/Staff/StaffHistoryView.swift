import SwiftUI

private enum DatePreset: String, CaseIterable, Identifiable {
    case today = "Today", week = "This Week", month = "This Month", custom = "Custom"
    var id: String { rawValue }
}

struct StaffHistoryView: View {
    @StateObject private var cashVM = CashEntryViewModel()
    @StateObject private var cardVM = CardEntryViewModel()
    @StateObject private var editWindowVM = EditWindowViewModel()
    @State private var segment = 0           // 0=Cash, 1=Card
    @State private var cashAccountFilter = "all"  // all / main / mano
    @State private var datePreset: DatePreset = .today
    @State private var customFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var customTo   = Date()
    @State private var search     = ""
    @State private var showEditRequest: SubmitEditRequestTarget? = nil

    struct SubmitEditRequestTarget: Identifiable {
        let id: Int; let entryType: String; let originalAmount: Double; let originalNotes: String?
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment
                Picker("", selection: $segment) {
                    Text("Cash").tag(0)
                    Text("Bank").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DatePreset.allCases) { preset in
                            FilterChip(label: preset.rawValue, isSelected: datePreset == preset) {
                                datePreset = preset
                            }
                        }
                        if isFiltered {
                            Divider().frame(height: 22)
                            Button(action: clearFilters) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Clear")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.mmError.opacity(0.12))
                                .foregroundStyle(Color.mmError)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Custom date pickers
                if datePreset == .custom {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                            DatePicker("", selection: $customFrom, displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("To").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                            DatePicker("", selection: $customTo, displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                        }
                        Spacer()
                        Button("Apply") { Task { await applyFilters() } }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.mmPrimary)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 16).padding(.bottom, 8)
                }

                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Color.mmTextSecondary)
                    TextField("Search notes…", text: $search)
                        .font(.system(size: 13))
                        .submitLabel(.search)
                        .onSubmit { Task { await applyFilters() } }
                    if !search.isEmpty {
                        Button { search = ""; Task { await applyFilters() } } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.mmInputFill)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Summary bar
                summaryBar

                Divider()

                if segment == 0 { cashList } else { cardList }
            }
            .background(Color.mmBackground)
            .navigationTitle("My History")
        }
        .task {
            await editWindowVM.fetch()
            await applyFilters()
        }
        .sheet(item: $showEditRequest) { target in
            SubmitEditRequestView(
                entryType: target.entryType,
                entryId: target.id,
                originalAmount: target.originalAmount,
                originalNotes: target.originalNotes
            )
        }
        .onChange(of: segment)           { _ in Task { await applyFilters() } }
        .onChange(of: cashAccountFilter) { _ in Task { await applyFilters() } }
        .onChange(of: datePreset)        { _ in if datePreset != .custom { Task { await applyFilters() } } }
    }

    // MARK: - Summary bar

    @ViewBuilder
    private var summaryBar: some View {
        let cashTotal = cashVM.myHistory.reduce(0.0) { $0 + $1.cashAmount }
        let cardTotal = cardVM.myHistory.reduce(0.0) { $0 + $1.amount }
        let combined  = cashTotal + cardTotal

        HStack(spacing: 0) {
            summaryCell(label: "Cash", value: cashTotal, color: .mmAccent)
            Divider().frame(height: 28)
            summaryCell(label: "Bank", value: cardTotal, color: .mmPrimary)
            Divider().frame(height: 28)
            summaryCell(label: "Total", value: combined, color: .mmSuccess)
        }
        .padding(.vertical, 8)
        .background(Color.mmCard)
    }

    private func summaryCell(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
            Text(value.currency).font(.system(size: 12, weight: .bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cash list

    @ViewBuilder
    private var cashList: some View {
        if cashVM.isLoading && cashVM.myHistory.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(40)
        } else if cashVM.myHistory.isEmpty {
            EmptyStateView(icon: "banknote", message: "No cash entries found")
        } else {
            List {
                ForEach(cashVM.myHistory) { entry in
                    CashEntryRow(entry: entry, onEditRequest: editWindowVM.isOpen ? {
                        showEditRequest = SubmitEditRequestTarget(
                            id: entry.id, entryType: "cash",
                            originalAmount: entry.cashAmount, originalNotes: entry.notes
                        )
                    } : nil)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        if entry.id == cashVM.myHistory.last?.id {
                            Task { await cashVM.fetchMyHistory(
                                cashAccountType: cashAccountFilter == "all" ? nil : cashAccountFilter,
                                from: fromString, to: toString, search: search.isEmpty ? nil : search
                            ) }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await applyFilters() }
        }
    }

    // MARK: - Card list

    @ViewBuilder
    private var cardList: some View {
        if cardVM.isLoading && cardVM.myHistory.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(40)
        } else if cardVM.myHistory.isEmpty {
            EmptyStateView(icon: "creditcard", message: "No bank entries found")
        } else {
            List {
                ForEach(cardVM.myHistory) { entry in
                    CardEntryRow(entry: entry, onEditRequest: editWindowVM.isOpen ? {
                        showEditRequest = SubmitEditRequestTarget(
                            id: entry.id, entryType: "card",
                            originalAmount: entry.amount, originalNotes: entry.notes
                        )
                    } : nil)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        if entry.id == cardVM.myHistory.last?.id {
                            Task { await cardVM.fetchMyHistory(
                                from: fromString, to: toString, search: search.isEmpty ? nil : search
                            ) }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await applyFilters() }
        }
    }

    // MARK: - Helpers

    private var isFiltered: Bool {
        segment != 0 || datePreset != .today || cashAccountFilter != "all" || !search.isEmpty
    }

    private func clearFilters() {
        segment = 0
        cashAccountFilter = "all"
        datePreset = .today
        search = ""
        Task { await applyFilters() }
    }

    private var fromString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        switch datePreset {
        case .today:
            return f.string(from: Date())
        case .week:
            return f.string(from: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
        case .month:
            return f.string(from: Calendar.current.date(byAdding: .day, value: -29, to: Date())!)
        case .custom:
            return f.string(from: customFrom)
        }
    }

    private var toString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return datePreset == .custom ? f.string(from: customTo) : f.string(from: Date())
    }

    private func applyFilters() async {
        let accountType = (segment == 0 && cashAccountFilter != "all") ? cashAccountFilter : nil
        let searchTerm  = search.isEmpty ? nil : search
        async let c: () = cashVM.fetchMyHistory(
            cashAccountType: accountType,
            from: fromString, to: toString, search: searchTerm, refresh: true
        )
        async let k: () = cardVM.fetchMyHistory(
            from: fromString, to: toString, search: searchTerm, refresh: true
        )
        _ = await (c, k)
    }
}

// MARK: - Row views

struct CashEntryRow: View {
    let entry: DailyCashEntry
    var onEditRequest: (() -> Void)? = nil

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.entryDate.displayDate)
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmTextPrimary)
                    Text(entry.cashAccountLabel)
                        .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    if let n = entry.notes {
                        Text(n).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.cashAmount.currency)
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
                    if entry.isLocked {
                        Label("Locked", systemImage: "lock.fill")
                            .font(.system(size: 10)).foregroundStyle(Color.mmWarning)
                    } else if let action = onEditRequest {
                        Button {
                            action()
                        } label: {
                            Label("Edit Request", systemImage: "pencil.circle")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.mmAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct CardEntryRow: View {
    let entry: DailyCardEntry
    var onEditRequest: (() -> Void)? = nil

    var body: some View {
        RowCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.entryDate.displayDate)
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmTextPrimary)
                    Text(entry.displayCard)
                        .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    if let n = entry.notes {
                        Text(n).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.amount.currency)
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmPrimary)
                    if entry.isLocked {
                        Label("Locked", systemImage: "lock.fill")
                            .font(.system(size: 10)).foregroundStyle(Color.mmWarning)
                    } else if let action = onEditRequest {
                        Button {
                            action()
                        } label: {
                            Label("Edit Request", systemImage: "pencil.circle")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.mmAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

