import SwiftUI

struct MyEditRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = EditRequestViewModel()
    @State private var statusFilter = "all"
    @State private var cancelTargetId: Int? = nil

    private let tabs = ["all", "pending", "approved", "rejected"]

    private var filtered: [EditRequest] {
        if statusFilter == "all" { return vm.myRequests }
        return vm.myRequests.filter { $0.status == statusFilter }
    }

    private func count(for status: String) -> Int {
        if status == "all" { return vm.myRequests.count }
        return vm.myRequests.filter { $0.status == status }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tabs, id: \.self) { tab in
                            let cnt = count(for: tab)
                            Button {
                                statusFilter = tab
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

                if vm.isLoading && vm.myRequests.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                } else if filtered.isEmpty {
                    EmptyStateView(icon: "pencil.circle", message: "No \(statusFilter == "all" ? "" : statusFilter + " ")edit requests")
                } else {
                    List {
                        ForEach(filtered) { req in
                            EditRequestRow(request: req, onCancel: req.status == "pending" ? {
                                cancelTargetId = req.id
                            } : nil)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onAppear {
                                if req.id == vm.myRequests.last?.id {
                                    Task { await vm.fetchMyRequests() }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchMyRequests(refresh: true) }
                }
            }
            .background(Color.mmBackground)
            .navigationTitle("My Edit Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await vm.fetchMyRequests(refresh: true) }
            .alert("Cancel Edit Request?", isPresented: Binding(
                get: { cancelTargetId != nil },
                set: { if !$0 { cancelTargetId = nil } }
            )) {
                Button("Cancel Request", role: .destructive) {
                    if let id = cancelTargetId {
                        Task { try? await vm.cancel(id) }
                    }
                    cancelTargetId = nil
                }
                Button("Keep", role: .cancel) { cancelTargetId = nil }
            } message: {
                Text("This will withdraw your pending edit request.")
            }
        }
    }
}

struct EditRequestRow: View {
    let request: EditRequest
    var onCancel: (() -> Void)? = nil

    var badgeColor: Color {
        switch request.status {
        case "approved": return .mmSuccess
        case "rejected": return .mmError
        default:         return .mmWarning
        }
    }

    var body: some View {
        RowCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(request.entryType.capitalized + " Edit")
                            .font(.system(size: 14, weight: .semibold))
                        Text("#\(request.entryId)")
                            .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                    }
                    Text(request.reason)
                        .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(2)
                    Text(request.createdAt.displayDateTime)
                        .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    StatusBadge(text: request.status, color: badgeColor)
                    if request.status == "pending", let cancel = onCancel {
                        Button(action: cancel) {
                            Text("Cancel")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.mmError)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.mmError.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if let remarks = request.adminRemarks, !remarks.isEmpty {
                Text("Remarks: \(remarks)")
                    .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

