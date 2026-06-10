import SwiftUI

struct AdminMoreView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var logoutAlert = false
    @State private var showChangePassword = false

    var body: some View {
        NavigationStack {
            List {
                Section("Reports & Logs") {
                    NavigationLink(destination: RecordsView()) {
                        Label("Records", systemImage: "checklist")
                    }
                }

                Section("Management") {
                    NavigationLink(destination: UserManagementView()) {
                        Label("User Management", systemImage: "person.2.badge.gearshape")
                    }
                    NavigationLink(destination: EditRequestsView()) {
                        Label("Edit Requests", systemImage: "pencil.circle")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }

                if let user = auth.user {
                    Section("Account") {
                        HStack(spacing: 12) {
                            AvatarView(initials: user.initials, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name).font(.system(size: 15, weight: .medium))
                                Text(user.email).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                        Button { showChangePassword = true } label: {
                            Label("Change Password", systemImage: "key.fill")
                        }
                        Button(role: .destructive) { logoutAlert = true } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    }
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showChangePassword) { ChangePasswordView() }
            .alert("Sign Out", isPresented: $logoutAlert) {
                Button("Sign Out", role: .destructive) { Task { await auth.logout() } }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Are you sure you want to sign out?") }
        }
    }
}

// MARK: - Reports

struct ReportsView: View {
    @StateObject private var vm         = ReportViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()
    @State private var fromDate         = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDate           = Date()
    @State private var selectedShowroomId: Int?
    @State private var pdfFileURL: URL?
    @State private var isDownloading    = false
    @State private var downloadError: String?

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filter card
                RowCard {
                    VStack(spacing: 12) {
                        DatePicker("From", selection: $fromDate, displayedComponents: .date)
                        Divider()
                        DatePicker("To",   selection: $toDate,   displayedComponents: .date)
                        Divider()
                        Picker("Showroom", selection: $selectedShowroomId) {
                            Text("All Showrooms").tag(Optional<Int>.none)
                            ForEach(showroomVM.showrooms.prioritized()) { s in
                                ShowroomOptionLabel(name: s.name, isFlagship: s.isFlagship).tag(Optional(s.id))
                            }
                        }
                    }
                }

                // Generate JSON summary
                MMButton(title: "Generate Report", isLoading: vm.isLoading) {
                    Task { await vm.fetchReport(from: fmt.string(from: fromDate),
                                                to:   fmt.string(from: toDate),
                                                showroomId: selectedShowroomId) }
                }

                // PDF Download button
                Button {
                    Task { await downloadPDF() }
                } label: {
                    HStack(spacing: 8) {
                        if isDownloading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                        }
                        Text(isDownloading ? "Downloading…" : "Download PDF Report")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.mmAccent)
                    .cornerRadius(12)
                }
                .disabled(isDownloading)

                if let e = downloadError { ErrorBanner(message: e) }
                if let e = vm.error      { ErrorBanner(message: e) }

                if let s = vm.report { reportContent(s) }
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task { await showroomVM.fetchAll() }
        .sheet(item: $pdfFileURL) { url in
            PDFPreviewView(url: url)
        }
    }

    @ViewBuilder
    private func reportContent(_ s: ReportSummary) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar").foregroundStyle(Color.mmTextSecondary)
                Text("\(s.from.displayDate) – \(s.to.displayDate)")
                    .font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
                Spacer()
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ReportStatCard(title: "Main Cash",   value: s.cashMainAdjusted, raw: s.cashMainTotal, color: Color.mmPrimary,      icon: "banknote.fill")
                ReportStatCard(title: "Mano Cash",   value: s.cashManoAdjusted, raw: s.cashManoTotal, color: Color.mmAccent,       icon: "person.fill")
                ReportStatCard(title: "Bank Total",  value: s.cardAdjusted,     raw: s.cardTotal,     color: Color(hex: "6366F1"), icon: "creditcard.fill")
                ReportStatCard(title: "Grand Total", value: s.grandAdjusted,    raw: s.grandTotal,    color: Color.mmSuccess,      icon: "chart.bar.fill")
            }
            if !s.perShowroom.isEmpty {
                SectionHeader(title: "Per Showroom")
                ForEach(s.perShowroom) { snap in ShowroomSnapshotRow(snap: snap) }
            }
        }
    }

    // MARK: - PDF download with auth header

    private func downloadPDF() async {
        isDownloading = true; downloadError = nil
        defer { isDownloading = false }

        var comps = URLComponents(string: AppConfig.baseURL + "/reports/pdf/daily-summary")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "from", value: fmt.string(from: fromDate)),
            URLQueryItem(name: "to",   value: fmt.string(from: toDate)),
        ]
        if let sid = selectedShowroomId {
            items.append(URLQueryItem(name: "showroom_id", value: "\(sid)"))
        }
        comps.queryItems = items
        guard let url = comps.url else { downloadError = "Invalid URL"; return }

        var req = URLRequest(url: url)
        if let token = try? KeychainService.read(for: AppConfig.tokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                downloadError = "Server returned an error. Check date range."; return
            }
            // Save to temp file
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("report-\(fmt.string(from: fromDate))-\(fmt.string(from: toDate)).pdf")
            try data.write(to: tmp)
            await MainActor.run { pdfFileURL = tmp }
        } catch {
            downloadError = error.localizedDescription
        }
    }
}

// MARK: - Report Stat Card

private struct ReportStatCard: View {
    let title: String
    let value: Double
    let raw: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12))
                    .cornerRadius(7)
                Spacer()
                if abs(value - raw) > 0.001 {
                    Text("adj").font(.system(size: 9, weight: .semibold)).foregroundStyle(color)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(color.opacity(0.12)).cornerRadius(3)
                }
            }
            Text(title).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
            Text(value.currency)
                .font(.system(size: 16, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.7).lineLimit(1)
            if abs(value - raw) > 0.001 {
                Text("Raw: \(raw.currency)").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - PDF Preview (QuickLook)

import QuickLook

private struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let vc = QLPreviewController()
        vc.dataSource = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as QLPreviewItem }
    }
}

// Make URL conform to Identifiable for .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}


// MARK: - Audit Log

// MARK: - Audit Log Filter Model

enum AuditTableFilter: String, CaseIterable, Identifiable {
    case all = ""
    case cashEntries   = "daily_cash_entries"
    case cardEntries   = "daily_card_entries"
    case cardAccounts  = "card_accounts"
    case selfTx        = "self_transactions"
    case cashTx        = "cash_transactions"
    case adjustments   = "admin_cash_adjustments"
    case cardAdj       = "admin_card_adjustments"
    case users         = "users"
    case showrooms     = "showrooms"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .all:          return "All"
        case .cashEntries:  return "Cash Entries"
        case .cardEntries:  return "Bank Entries"
        case .cardAccounts: return "Bank Accounts"
        case .selfTx:       return "Self Transfers"
        case .cashTx:       return "Cash Transfers"
        case .adjustments:  return "Cash Adjustments"
        case .cardAdj:      return "Bank Adjustments"
        case .users:        return "Users"
        case .showrooms:    return "Showrooms"
        }
    }
    var icon: String {
        switch self {
        case .all:          return "line.3.horizontal.decrease.circle"
        case .cashEntries:  return "dollarsign.circle"
        case .cardEntries:  return "creditcard"
        case .cardAccounts: return "creditcard.fill"
        case .selfTx:       return "arrow.left.arrow.right"
        case .cashTx:       return "banknote"
        case .adjustments:  return "slider.horizontal.3"
        case .cardAdj:      return "slider.horizontal.3"
        case .users:        return "person.2"
        case .showrooms:    return "storefront"
        }
    }
}

enum AuditActionFilter: String, CaseIterable, Identifiable {
    case all              = ""
    case created          = "created"
    case updated          = "updated"
    case deleted          = "deleted"
    case passwordChanged  = "password_changed"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .all:             return "All Actions"
        case .created:         return "Created"
        case .updated:         return "Updated"
        case .deleted:         return "Deleted"
        case .passwordChanged: return "Password Changed"
        }
    }
    var color: Color {
        switch self {
        case .all:             return .mmPrimary
        case .created:         return .mmSuccess
        case .updated:         return .mmPrimary
        case .deleted:         return .mmError
        case .passwordChanged: return .mmWarning
        }
    }
}

struct AuditLogView: View {
    @StateObject private var vm = AuditLogViewModel()
    @State private var tableFilter: AuditTableFilter = .all
    @State private var actionFilter: AuditActionFilter = .all
    @State private var dateFrom: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var dateTo: Date = Date()
    @State private var useDateFilter = false
    @State private var showFilters = false
    @State private var selectedItem: AuditLog?
    @State private var deleteAlert: AuditLog?
    @State private var isSelecting = false
    @State private var selectedIds: Set<Int> = []
    @State private var bulkDeleteAlert = false

    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private var activeFilterCount: Int {
        (tableFilter != .all ? 1 : 0) + (actionFilter != .all ? 1 : 0) + (useDateFilter ? 1 : 0)
    }

    private func applyFilters() async {
        await vm.fetchAll(
            tableName: tableFilter.rawValue.isEmpty ? nil : tableFilter.rawValue,
            action: actionFilter.rawValue.isEmpty ? nil : actionFilter.rawValue,
            dateFrom: useDateFilter ? dateFmt.string(from: dateFrom) : nil,
            dateTo: useDateFilter ? dateFmt.string(from: dateTo) : nil,
            refresh: true
        )
    }

    private func loadMore() async {
        await vm.fetchAll(
            tableName: tableFilter.rawValue.isEmpty ? nil : tableFilter.rawValue,
            action: actionFilter.rawValue.isEmpty ? nil : actionFilter.rawValue,
            dateFrom: useDateFilter ? dateFmt.string(from: dateFrom) : nil,
            dateTo: useDateFilter ? dateFmt.string(from: dateTo) : nil
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Active filter chips
                if activeFilterCount > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if tableFilter != .all {
                                AuditFilterChip(label: tableFilter.label, icon: tableFilter.icon) {
                                    tableFilter = .all; Task { await applyFilters() }
                                }
                            }
                            if actionFilter != .all {
                                AuditFilterChip(label: actionFilter.label, color: actionFilter.color) {
                                    actionFilter = .all; Task { await applyFilters() }
                                }
                            }
                            if useDateFilter {
                                AuditFilterChip(label: "\(dateFmt.string(from: dateFrom)) – \(dateFmt.string(from: dateTo))",
                                           icon: "calendar") {
                                    useDateFilter = false; Task { await applyFilters() }
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    .background(Color.mmCard)
                }

                Group {
                    if vm.isLoading && vm.logs.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(40)
                    } else if vm.logs.isEmpty {
                        EmptyStateView(icon: "doc.text.magnifyingglass", message: "No audit records")
                    } else {
                        List {
                            ForEach(vm.logs) { log in
                                AuditLogRow(log: log)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isSelecting {
                                            if selectedIds.contains(log.id) { selectedIds.remove(log.id) }
                                            else { selectedIds.insert(log.id) }
                                        } else {
                                            selectedItem = selectedItem?.id == log.id ? nil : log
                                        }
                                    }
                                    .listRowBackground(
                                        (isSelecting ? selectedIds.contains(log.id) : selectedItem?.id == log.id)
                                            ? Color.mmPrimary.opacity(0.1) : Color.clear
                                    )
                                    .listRowSeparator(.hidden)
                                    .overlay(alignment: .leading) {
                                        if isSelecting {
                                            Image(systemName: selectedIds.contains(log.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedIds.contains(log.id) ? Color.mmPrimary : Color.mmTextSecondary)
                                                .font(.system(size: 20))
                                                .padding(.leading, 20)
                                        }
                                    }
                                    .onAppear {
                                        if log.id == vm.logs.last?.id { Task { await loadMore() } }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await applyFilters() }
                    }
                }
            }
            .background(Color.mmBackground)
            .navigationTitle("Audit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isSelecting = false; selectedIds = [] }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Select All") { selectedIds = Set(vm.logs.map { $0.id }) }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Delete (\(selectedIds.count))") { bulkDeleteAlert = true }
                            .foregroundStyle(Color.mmError)
                            .disabled(selectedIds.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showFilters = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                if activeFilterCount > 0 {
                                    Circle().fill(Color.mmAccent).frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
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
            .sheet(isPresented: $showFilters) {
                AuditLogFilterSheet(
                    tableFilter: $tableFilter,
                    actionFilter: $actionFilter,
                    dateFrom: $dateFrom,
                    dateTo: $dateTo,
                    useDateFilter: $useDateFilter
                ) { Task { await applyFilters() } }
            }
            .alert(item: $deleteAlert) { log in
                Alert(
                    title: Text("Delete Log Entry?"),
                    message: Text("This cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task { try? await vm.delete(log.id); selectedItem = nil }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Delete \(selectedIds.count) log(s)?", isPresented: $bulkDeleteAlert) {
                Button("Delete", role: .destructive) {
                    let ids = Array(selectedIds)
                    Task { try? await vm.bulkDelete(ids); isSelecting = false; selectedIds = [] }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This cannot be undone.") }
            .task { await vm.fetchAll(refresh: true) }
        }
    }
}

// MARK: - Filter Sheet

struct AuditLogFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var tableFilter: AuditTableFilter
    @Binding var actionFilter: AuditActionFilter
    @Binding var dateFrom: Date
    @Binding var dateTo: Date
    @Binding var useDateFilter: Bool
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Record Type") {
                    ForEach(AuditTableFilter.allCases) { f in
                        HStack {
                            Image(systemName: f.icon).foregroundStyle(Color.mmPrimary).frame(width: 20)
                            Text(f.label)
                            Spacer()
                            if tableFilter == f {
                                Image(systemName: "checkmark").foregroundStyle(Color.mmPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { tableFilter = f }
                    }
                }

                Section("Action") {
                    ForEach(AuditActionFilter.allCases) { f in
                        HStack {
                            Circle().fill(f == .all ? Color.mmTextSecondary : f.color)
                                .frame(width: 8, height: 8)
                            Text(f.label)
                            Spacer()
                            if actionFilter == f {
                                Image(systemName: "checkmark").foregroundStyle(Color.mmPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { actionFilter = f }
                    }
                }

                Section {
                    Toggle("Filter by Date Range", isOn: $useDateFilter)
                    if useDateFilter {
                        DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                        DatePicker("To",   selection: $dateTo,   in: dateFrom..., displayedComponents: .date)
                    }
                } header: { Text("Date Range") }
            }
            .navigationTitle("Filter Audit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        tableFilter = .all; actionFilter = .all; useDateFilter = false
                        onApply(); dismiss()
                    }
                    .foregroundStyle(Color.mmError)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { onApply(); dismiss() }
                }
            }
        }
    }
}

struct AuditFilterChip: View {
    let label: String
    var icon: String? = nil
    var color: Color = .mmPrimary
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 11)) }
            Text(label).font(.system(size: 12, weight: .medium))
            Button { onRemove() } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.12))
        .cornerRadius(20)
    }
}

struct AuditLogRow: View {
    let log: AuditLog

    // MARK: - Metadata helpers
    var actionColor: Color {
        switch log.action {
        case "create", "created":               return .mmSuccess
        case "delete", "deleted":               return .mmError
        case "password_changed":                return .mmWarning
        case "role_change":                     return Color(hex: "8B5CF6")
        case "approve_edit_request":            return .mmSuccess
        case "reject_edit_request":             return .mmError
        default:                                return .mmPrimary
        }
    }

    var actionIcon: String {
        switch log.action {
        case "create", "created":               return "plus.circle.fill"
        case "update", "updated":               return "pencil.circle.fill"
        case "delete", "deleted":               return "trash.circle.fill"
        case "password_changed":                return "lock.rotation"
        case "role_change":                     return "person.badge.key.fill"
        case "approve_edit_request":            return "checkmark.seal.fill"
        case "reject_edit_request":             return "xmark.seal.fill"
        default:                                return "circle.fill"
        }
    }

    var actionLabel: String {
        switch log.action {
        case "create", "created":               return "Created"
        case "update", "updated":               return "Updated"
        case "delete", "deleted":               return "Deleted"
        case "password_changed":                return "Password Changed"
        case "role_change":                     return "Role Changed"
        case "approve_edit_request":            return "Request Approved"
        case "reject_edit_request":             return "Request Rejected"
        default:                                return log.action.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var tableLabel: String {
        switch log.tableName {
        case "daily_cash_entries":       return "Cash Entry"
        case "daily_card_entries":       return "Bank Entry"
        case "card_accounts":            return "Bank Account"
        case "self_transactions":        return "Self Transfer"
        case "cash_transactions":        return "Cash Transfer"
        case "admin_cash_adjustments":   return "Cash Adjustment"
        case "admin_card_adjustments":   return "Bank Adjustment"
        case "edit_requests":            return "Edit Request"
        case "showrooms":                return "Showroom"
        case "users":                    return "User"
        default:                         return log.tableName.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var tableIcon: String {
        switch log.tableName {
        case "daily_cash_entries":       return "banknote"
        case "daily_card_entries":       return "creditcard"
        case "card_accounts":            return "creditcard.fill"
        case "self_transactions":        return "arrow.left.arrow.right"
        case "cash_transactions":        return "arrow.left.arrow.right.circle"
        case "admin_cash_adjustments",
             "admin_card_adjustments":   return "slider.horizontal.3"
        case "edit_requests":            return "pencil.and.list.clipboard"
        case "showrooms":                return "building.2"
        case "users":                    return "person.fill"
        default:                         return "doc.text"
        }
    }

    /// Human-readable summary of what changed
    var changeSummary: String? {
        func val(_ dict: [String: AnyCodable]?, _ key: String) -> String? {
            guard let v = dict?[key] else { return nil }
            if v.value is NSNull { return nil }
            let s = "\(v.value)"
            return (s.isEmpty || s == "nil") ? nil : s
        }
        func money(_ s: String) -> String {
            Double(s).map { "Rs. \(String(format: "%.2f", $0))" } ?? s
        }
        func fieldLabel(_ key: String) -> String {
            key.split(separator: "_")
               .map { String($0.prefix(1)).uppercased() + String($0.dropFirst()) }
               .joined(separator: " ")
        }

        let anyVals = log.newValues ?? log.oldValues

        switch log.action {
        case "role_change":
            let old = val(log.oldValues, "role") ?? "?"
            let new = val(log.newValues, "role") ?? "?"
            return "\(old.capitalized) → \(new.capitalized)"

        case "password_changed": return "Password was updated"
        case "approve_edit_request": return "Edit request approved"
        case "reject_edit_request":  return "Edit request rejected"

        case "update", "updated":
            guard let newVals = log.newValues, !newVals.isEmpty else { return "Updated" }
            let moneyKeys: Set<String> = ["cash_amount", "amount", "adjusted_amount", "current_balance"]
            let skipKeys: Set<String> = ["updated_at", "showroom_id", "user_id", "card_account_id"]
            let parts = newVals.keys.sorted().compactMap { key -> String? in
                guard !skipKeys.contains(key), let newStr = val(newVals, key) else { return nil }
                let label = fieldLabel(key)
                let fmt: (String) -> String = { s in
                    if moneyKeys.contains(key) { return money(s) }
                    if key.contains("date") { return s.displayDate }
                    return s
                }
                if let oldStr = val(log.oldValues, key), oldStr != newStr {
                    return "\(label): \(fmt(oldStr)) → \(fmt(newStr))"
                } else if log.oldValues == nil {
                    return "\(label): \(fmt(newStr))"
                }
                return nil
            }
            return parts.isEmpty ? "Updated" : parts.joined(separator: " · ")

        default:
            // create / delete
            var parts: [String] = []
            if let acct = val(anyVals, "cash_account_type") {
                parts.append(acct == "mano" ? "Mano's Cash" : "Main Cash")
            }
            if let date = val(anyVals, "entry_date") {
                parts.append(date.displayDate)
            }
            if let amt = val(anyVals, "cash_amount") ?? val(anyVals, "amount") {
                parts.append(money(amt))
            }
            if let adj = val(anyVals, "adjusted_amount"), let num = Double(adj) {
                let sign = num >= 0 ? "+" : ""
                parts.append("Adj: \(sign)\(money(adj))")
            }
            if let n = val(anyVals, "notes") ?? val(anyVals, "reason"), n != "null" {
                parts.append(n.count > 40 ? String(n.prefix(40)) + "…" : n)
            }
            if parts.isEmpty, let name = val(anyVals, "name") { parts.append(name) }
            if let role = val(anyVals, "role") { parts.append(role.capitalized) }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }
    }

    var body: some View {
        RowCard {
            HStack(spacing: 12) {
                // Action icon circle
                ZStack {
                    Circle()
                        .fill(actionColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: actionIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(actionColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Action + table label
                    HStack(spacing: 6) {
                        Text(actionLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(actionColor)
                        Text(tableLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.mmTextPrimary)
                        Spacer()
                    }
                    // Change summary
                    if let summary = changeSummary {
                        Text(summary)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mmTextSecondary)
                            .lineLimit(2)
                    }
                    // User + record + time
                    HStack(spacing: 8) {
                        if let name = log.userName {
                            Label(name, systemImage: "person.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        Label("#\(log.recordId)", systemImage: "number")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                        Text(log.createdAt?.displayDateTime ?? "")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @StateObject private var settingsVM = SettingsViewModel()
    @State private var cashEnabled = true
    @State private var bankEnabled = true
    @State private var loaded = false

    var body: some View {
        List {
            Section("Edit Window") {
                NavigationLink(destination: EditWindowSettingsView()) {
                    HStack(spacing: 14) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.mmPrimary)
                            .frame(width: 32, height: 32)
                            .background(Color.mmPrimary.opacity(0.1))
                            .cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Edit Window")
                                .font(.system(size: 14, weight: .medium))
                            Text("Set the daily hours staff can submit entries")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Toggle(isOn: $cashEnabled) {
                    HStack(spacing: 14) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.mmPrimary)
                            .frame(width: 32, height: 32)
                            .background(Color.mmPrimary.opacity(0.1))
                            .cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cash Entries").font(.system(size: 14, weight: .medium))
                            Text("Allow staff to submit cash entries")
                                .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
                .onChange(of: cashEnabled) { newValue in
                    guard loaded else { return }
                    Task { try? await settingsVM.update(key: "cash_entries_enabled", value: newValue ? "1" : "0") }
                }

                Toggle(isOn: $bankEnabled) {
                    HStack(spacing: 14) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "6366F1"))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "6366F1").opacity(0.1))
                            .cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bank Entries").font(.system(size: 14, weight: .medium))
                            Text("Allow staff to submit bank entries")
                                .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
                .onChange(of: bankEnabled) { newValue in
                    guard loaded else { return }
                    Task { try? await settingsVM.update(key: "bank_entries_enabled", value: newValue ? "1" : "0") }
                }
            } header: {
                Text("Staff Entry Access")
            } footer: {
                Text("When disabled, staff cannot submit new cash or bank entries. Admins are always able to add entries.")
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.mmBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await settingsVM.fetchAll()
            cashEnabled = settingsVM.settings.first(where: { $0.key == "cash_entries_enabled" })?.value != "0"
            bankEnabled = settingsVM.settings.first(where: { $0.key == "bank_entries_enabled" })?.value != "0"
            loaded = true
        }
    }
}

private struct SettingRow: View {
    let setting: Setting
    @ObservedObject var vm: SettingsViewModel
    @State private var editValue = ""
    @State private var showEditor = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(setting.key).font(.system(size: 14, weight: .medium))
                Text(setting.value).font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
            }
            Spacer()
            Button { editValue = setting.value; showEditor = true } label: {
                Image(systemName: "pencil").foregroundStyle(Color.mmPrimary)
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                Form {
                    Section(setting.key) {
                        TextField("Value", text: $editValue)
                    }
                }
                .navigationTitle("Edit Setting").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showEditor = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task { try? await vm.update(key: setting.key, value: editValue); showEditor = false }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Edit Window Settings

struct EditWindowSettingsView: View {
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var windowVM   = EditWindowViewModel()
    @State private var startDate = Date()
    @State private var endDate   = Date()
    @State private var saveError: String?
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Live status card
                RowCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill((windowVM.isOpen ? Color.mmSuccess : Color.mmError).opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: windowVM.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(windowVM.isOpen ? Color.mmSuccess : Color.mmError)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(windowVM.isOpen ? "Editing is Open" : "Editing is Closed")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(windowVM.isOpen ? Color.mmSuccess : Color.mmError)
                            if let s = windowVM.status {
                                Text("Server time: \(to12h(s.serverTime))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                            Text("Current window: \(windowVM.windowHours)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        Spacer()
                    }
                }

                // Time pickers
                RowCard {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "clock.fill").foregroundStyle(Color.mmPrimary)
                            Text("Set Window Hours")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        Divider().padding(.vertical, 10)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Opens at").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                                DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.mmTextSecondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Closes at").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                                DatePicker("", selection: $endDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                            }
                        }
                        .padding(.vertical, 8)
                        Divider().padding(.bottom, 10)
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                            Text("Staff can only submit and edit entries during this daily window.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }

                if let e = saveError { ErrorBanner(message: e) }

                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
                        Text("Window updated successfully").font(.system(size: 13)).foregroundStyle(Color.mmSuccess)
                    }
                    .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
                }

                MMButton(title: "Save Window", isLoading: settingsVM.isSubmitting) {
                    Task { await saveWindow() }
                }
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle("Edit Window")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let a: () = settingsVM.fetchAll()
            async let b: () = windowVM.fetch()
            _ = await (a, b)
            if let s = settingsVM.settings.first(where: { $0.key == "edit_window_start" }) {
                startDate = timeStringToDate(s.value)
            }
            if let e = settingsVM.settings.first(where: { $0.key == "edit_window_end" }) {
                endDate = timeStringToDate(e.value)
            }
        }
    }

    private func timeStringToDate(_ str: String) -> Date {
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return Date() }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = parts[0]; comps.minute = parts[1]
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func dateToTimeString(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }

    private func to12h(_ time: String) -> String {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count == 2 else { return time }
        let h = parts[0]; let m = parts[1]
        let period = h < 12 ? "AM" : "PM"
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", h12, m, period)
    }

    private func saveWindow() async {
        saveError = nil; saved = false
        do {
            try await settingsVM.update(key: "edit_window_start", value: dateToTimeString(startDate))
            try await settingsVM.update(key: "edit_window_end",   value: dateToTimeString(endDate))
            await windowVM.fetch()
            saved = true
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Edit Requests (Admin)

struct EditRequestsView: View {
    @StateObject private var vm = EditRequestViewModel()
    @State private var reviewTarget: EditRequest?
    @State private var statusFilter = "pending"

    private let tabs = ["pending", "approved", "rejected", "all"]

    private var filtered: [EditRequest] {
        if statusFilter == "all" { return vm.adminRequests }
        return vm.adminRequests.filter { $0.status == statusFilter }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabs, id: \.self) { tab in
                        let cnt = vm.adminRequests.filter { tab == "all" || $0.status == tab }.count
                        Button {
                            statusFilter = tab
                            Task { await vm.fetchAdminRequests(status: tab == "all" ? nil : tab, refresh: true) }
                        } label: {
                            HStack(spacing: 4) {
                                Text(tab.capitalized)
                                    .font(.system(size: 12, weight: statusFilter == tab ? .semibold : .regular))
                                if cnt > 0 {
                                    Text("\(cnt)")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(statusFilter == tab ? Color.white.opacity(0.3) : Color.mmDivider)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(statusFilter == tab ? Color.mmPrimary : Color.mmCard)
                            .foregroundStyle(statusFilter == tab ? .white : Color.mmTextPrimary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            Divider()

            Group {
                if vm.isLoading && vm.adminRequests.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                } else if filtered.isEmpty {
                    EmptyStateView(icon: "pencil.circle", message: "No \(statusFilter == "all" ? "" : statusFilter + " ")edit requests")
                } else {
                    List {
                        ForEach(filtered) { req in
                            EditRequestRow(request: req)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture { if req.isPending { reviewTarget = req } }
                                .onAppear {
                                    if req.id == vm.adminRequests.last?.id {
                                        Task { await vm.fetchAdminRequests(status: statusFilter == "all" ? nil : statusFilter) }
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchAdminRequests(status: statusFilter == "all" ? nil : statusFilter, refresh: true) }
                }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Edit Requests")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $reviewTarget) { req in
            ReviewEditRequestView(request: req) { await vm.fetchAdminRequests(status: statusFilter == "all" ? nil : statusFilter, refresh: true) }
        }
        .task { await vm.fetchAdminRequests(status: "pending", refresh: true) }
    }
}

struct ReviewEditRequestView: View {
    @Environment(\.dismiss) var dismiss
    let request: EditRequest
    let onSave: () async -> Void

    @StateObject private var vm = EditRequestViewModel()
    @State private var remarks = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Request Details") {
                    LabeledContent("Type", value: request.entryType.capitalized + " Edit")
                    LabeledContent("Entry #", value: "\(request.entryId)")
                    LabeledContent("Reason", value: request.reason)
                    LabeledContent("Changes") {
                        Text(request.requestedChanges.keys.joined(separator: ", "))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                Section("Review") {
                    TextField("Admin Remarks (optional)", text: $remarks, axis: .vertical)
                        .lineLimit(3...)
                }
                if let e = error { Section { Text(e).foregroundStyle(Color.mmError).font(.system(size: 13)) } }
            }
            .navigationTitle("Review Request").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button("Reject") { Task { await decide("rejected") } }
                            .foregroundStyle(Color.mmError)
                        Button("Approve") { Task { await decide("approved") } }
                            .foregroundStyle(Color.mmSuccess)
                    }
                }
            }
        }
    }

    private func decide(_ status: String) async {
        do {
            try await vm.review(request.id, action: status, remarks: remarks.isEmpty ? nil : remarks)
            await onSave(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
