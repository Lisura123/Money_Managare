import SwiftUI

struct AdminMoreView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var logoutAlert = false
    @State private var showChangePassword = false

    var body: some View {
        NavigationStack {
            List {
                Section("Reports & Logs") {
                    NavigationLink(destination: ReportsView()) {
                        Label("Reports", systemImage: "chart.bar.doc.horizontal")
                    }
                    NavigationLink(destination: AuditLogView()) {
                        Label("Audit Log", systemImage: "doc.text.magnifyingglass")
                    }
                }

                Section("Management") {
                    NavigationLink(destination: EditRequestsView()) {
                        Label("Edit Requests", systemImage: "pencil.circle")
                    }
                    NavigationLink(destination: EditWindowSettingsView()) {
                        Label("Edit Window", systemImage: "clock.badge.checkmark")
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
    @StateObject private var vm = ReportViewModel()
    @StateObject private var showroomVM = ShowroomViewModel()
    @State private var fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDate = Date()
    @State private var selectedShowroomId: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filters
                RowCard {
                    VStack(spacing: 12) {
                        DatePicker("From", selection: $fromDate, displayedComponents: .date)
                        DatePicker("To", selection: $toDate, displayedComponents: .date)
                        Picker("Showroom", selection: $selectedShowroomId) {
                            Text("All Showrooms").tag(Optional<Int>.none)
                            ForEach(showroomVM.showrooms) { s in Text(s.name).tag(Optional(s.id)) }
                        }
                    }
                }

                MMButton(title: "Generate Report", isLoading: vm.isLoading) {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "yyyy-MM-dd"
                    Task { await vm.fetchReport(from: fmt.string(from: fromDate), to: fmt.string(from: toDate), showroomId: selectedShowroomId) }
                }

                if let e = vm.error { ErrorBanner(message: e) }

                if let s = vm.report {
                    reportContent(s)
                }
            }
            .padding(16)
        }
        .background(Color.mmBackground)
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task { await showroomVM.fetchAll() }
    }

    @ViewBuilder
    private func reportContent(_ s: ReportSummary) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Summary")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Main Cash",  value: s.cashMainTotal.currency)
                StatCard(title: "Mano Cash",  value: s.cashManoTotal.currency, color: .mmPrimary)
                StatCard(title: "Card Total", value: s.cardTotal.currency, color: Color(hex: "6366F1"))
                StatCard(title: "Grand Total", value: s.grandTotal.currency, color: .mmAccent)
            }
            if !s.perShowroom.isEmpty {
                SectionHeader(title: "Per Showroom")
                ForEach(s.perShowroom) { snap in ShowroomSnapshotRow(snap: snap) }
            }
        }
    }
}

// MARK: - Audit Log

struct AuditLogView: View {
    @StateObject private var vm = AuditLogViewModel()
    @State private var tableFilter = ""
    @State private var actionFilter = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick filter row
                HStack(spacing: 10) {
                    TextField("Table", text: $tableFilter).textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                    TextField("Action", text: $actionFilter).textFieldStyle(.roundedBorder).frame(maxWidth: 100)
                    Button("Filter") {
                        Task { await vm.fetchAll(tableName: tableFilter.isEmpty ? nil : tableFilter,
                                                  action: actionFilter.isEmpty ? nil : actionFilter,
                                                  refresh: true) }
                    }
                    .foregroundStyle(Color.mmAccent)
                }
                .padding(12)
                .background(Color.mmCard)

                Group {
                    if vm.isLoading && vm.logs.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(40)
                    } else if vm.logs.isEmpty {
                        EmptyStateView(icon: "doc.text.magnifyingglass", message: "No audit records")
                    } else {
                        List {
                            ForEach(vm.logs) { log in
                                AuditLogRow(log: log)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .onAppear {
                                        if log.id == vm.logs.last?.id {
                                            Task { await vm.fetchAll(tableName: tableFilter.isEmpty ? nil : tableFilter,
                                                                      action: actionFilter.isEmpty ? nil : actionFilter) }
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(Color.mmBackground)
            .navigationTitle("Audit Log")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.fetchAll(refresh: true) }
        }
    }
}

struct AuditLogRow: View {
    let log: AuditLog

    var actionColor: Color {
        switch log.action {
        case "create": return .mmSuccess
        case "delete": return .mmError
        default:       return .mmPrimary
        }
    }

    var body: some View {
        RowCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    StatusBadge(text: log.action, color: actionColor)
                    Text(log.tableName).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(log.createdAt?.displayDateTime ?? "").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                if let name = log.userName {
                    Text("By: \(name)").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                }
                Text("Record #\(log.recordId)").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        Group {
            if vm.isLoading && vm.settings.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if let e = vm.error {
                VStack(spacing: 12) {
                    ErrorBanner(message: e)
                    Button("Retry") { Task { await vm.fetchAll() } }
                        .foregroundStyle(Color.mmPrimary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            } else if vm.settings.isEmpty {
                EmptyStateView(icon: "gearshape", message: "No settings found")
            } else {
                List {
                    ForEach(vm.settings) { s in
                        SettingRow(setting: s, vm: vm)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchAll() }
    }
}

struct SettingRow: View {
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
    @StateObject private var vm = SettingsViewModel()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var saveError: String?
    @State private var saved = false

    var body: some View {
        Group {
            if vm.isLoading && vm.settings.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else {
                Form {
                    Section {
                        Text("Set the daily time range during which staff are allowed to edit entries.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Section("Window Hours (HH:MM)") {
                        HStack {
                            Text("Start Time")
                            Spacer()
                            TextField("e.g. 08:00", text: $startTime)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                                .frame(maxWidth: 100)
                        }
                        HStack {
                            Text("End Time")
                            Spacer()
                            TextField("e.g. 20:00", text: $endTime)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                                .frame(maxWidth: 100)
                        }
                    }
                    if let e = saveError {
                        Section {
                            Text(e).foregroundStyle(Color.mmError).font(.system(size: 13))
                        }
                    }
                    if saved {
                        Section {
                            Label("Saved successfully", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.mmSuccess)
                                .font(.system(size: 13))
                        }
                    }
                    Section {
                        MMButton(title: "Save", isLoading: vm.isSubmitting) {
                            Task { await saveWindow() }
                        }
                        .disabled(startTime.isEmpty || endTime.isEmpty)
                    }
                }
            }
        }
        .background(Color.mmBackground)
        .navigationTitle("Edit Window")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.fetchAll()
            if let s = vm.settings.first(where: { $0.key == "edit_window_start" }) { startTime = s.value }
            if let e = vm.settings.first(where: { $0.key == "edit_window_end" })   { endTime = e.value }
        }
    }

    private func saveWindow() async {
        saveError = nil; saved = false
        do {
            try await vm.update(key: "edit_window_start", value: startTime)
            try await vm.update(key: "edit_window_end",   value: endTime)
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
