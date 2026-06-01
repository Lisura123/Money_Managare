import SwiftUI

struct AdminDashboardView: View {
    @ObservedObject var vm: DashboardViewModel
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var editVM = EditRequestViewModel()
    @StateObject private var cardVM = CardAccountViewModel()
    @StateObject private var extVM  = ExternalAccountViewModel()
    @State private var showEditRequests = false
    @State private var balancesShowroomFilter: Int? = nil

    private var availableBalanceShowrooms: [(id: Int, name: String)] {
        var seen = Set<Int>()
        return cardVM.accounts.compactMap { acc -> (id: Int, name: String)? in
            let id = acc.showroomId
            guard let name = acc.showroomName else { return nil }
            return seen.insert(id).inserted ? (id: id, name: name) : nil
        }.sorted { $0.name < $1.name }
    }

    private var filteredBalanceCards: [CardAccount] {
        guard let id = balancesShowroomFilter else { return cardVM.accounts }
        return cardVM.accounts.filter { $0.showroomId == id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let e = vm.error { ErrorBanner(message: e) }

                    if vm.newDayDetected {
                        newDayBanner
                    }

                    // Pending edit requests banner
                    if editVM.pendingCount > 0 {
                        Button { showEditRequests = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundStyle(Color.mmWarning)
                                Text("\(editVM.pendingCount) edit request\(editVM.pendingCount == 1 ? "" : "s") pending review")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.mmWarning)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11)).foregroundStyle(Color.mmWarning.opacity(0.7))
                            }
                            .padding(14)
                            .background(Color.mmWarning.opacity(0.12))
                            .cornerRadius(12)
                        }
                    }

                    if vm.isLoading && vm.summary == nil {
                        ProgressView().frame(maxWidth: .infinity).padding(40)
                    } else if let s = vm.summary {
                        dashboardContent(s)
                    }
                }
                .padding(16)
            }
            .background(Color.mmBackground)
            .navigationTitle("Dashboard")
            .refreshable {
                await vm.fetch()
                await editVM.fetchPendingCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: .balancesDidChange)) { _ in
                Task { await vm.fetch(silent: true) }
                Task { await cardVM.fetchAll() }
                Task { await extVM.fetchAll() }
            }
            .task {
                await editVM.fetchPendingCount()
                async let c: () = cardVM.fetchAll()
                async let e: () = extVM.fetchAll()
                _ = await (c, e)
            }
            .navigationDestination(isPresented: $showEditRequests) {
                AdminEditRequestsDestination()
            }
        }
    }

    private var newDayBanner: some View {
        HStack {
            Image(systemName: "sun.rise.fill").foregroundStyle(Color.mmWarning)
            Text("New day detected — data updated")
                .font(.system(size: 13))
            Spacer()
            Button("Dismiss") { vm.clearNewDayNotification() }
                .font(.system(size: 12)).foregroundStyle(Color.mmAccent)
        }
        .padding(12)
        .background(Color.mmWarning.opacity(0.1))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func dashboardContent(_ s: DashboardSummary) -> some View {
        // Today header
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                Text(s.serverDate.displayDate)
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Color.mmPrimary)
            }
            Spacer()
            Text("Last updated \(s.lastUpdatedAt.displayDateTime)")
                .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.trailing)
        }

        // Today: adjusted values are primary; show raw as sub-label when different
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AdjustedStatCard(
                title: "Main Cash",
                adjValue: s.today.cashMainAdjusted,
                rawValue: s.today.cashMainTotal,
                color: .mmAccent
            )
            AdjustedStatCard(
                title: "Mano Cash",
                adjValue: s.today.cashManoAdjusted,
                rawValue: s.today.cashManoTotal,
                color: .mmPrimary
            )
            AdjustedStatCard(
                title: "Card Total",
                adjValue: s.today.cardAdjusted,
                rawValue: s.today.cardTotal,
                color: Color(hex: "6366F1")
            )
            AdjustedStatCard(
                title: "Grand Total",
                adjValue: s.today.grandAdjusted,
                rawValue: s.today.grandTotal,
                color: .mmSuccess
            )
        }

        // Per showroom breakdown
        if !s.today.perShowroom.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Per Showroom — Today")
                ForEach(s.today.perShowroom) { snap in
                    ShowroomSnapshotRow(snap: snap)
                }
            }
        }

        // Live account balances
        if !cardVM.accounts.isEmpty || !extVM.accounts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Account Balances")

                // Showroom filter chips (shown when there are multiple showrooms)
                if availableBalanceShowrooms.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: balancesShowroomFilter == nil) {
                                balancesShowroomFilter = nil
                            }
                            ForEach(availableBalanceShowrooms, id: \.id) { s in
                                FilterChip(label: s.name, isSelected: balancesShowroomFilter == s.id) {
                                    balancesShowroomFilter = s.id
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }
                }

                // Cash accounts (Main Account first, then external like Mano's)
                ForEach(extVM.accounts) { acc in
                    let isMain = acc.cashAccountType == "main"
                    LiveBalanceRow(
                        icon: isMain ? "building.columns.fill" : "banknote",
                        iconColor: isMain ? .mmPrimary : .mmAccent,
                        label: acc.name,
                        balance: acc.balance
                    )
                }

                // Card accounts (filtered by showroom when selected)
                ForEach(filteredBalanceCards) { acc in
                    LiveBalanceRow(
                        icon: "creditcard.fill",
                        iconColor: Color(hex: "6366F1"),
                        label: acc.displayLabel,
                        balance: acc.currentBalance
                    )
                }

                // Card total (reflects active filter)
                let cardTotal = filteredBalanceCards.reduce(0.0) { $0 + $1.currentBalance }
                HStack {
                    Text(balancesShowroomFilter == nil ? "Card Total" : "Filtered Card Total")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                    Text(cardTotal.currency)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "6366F1"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.mmCard)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Live Balance Row

private struct LiveBalanceRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let balance: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)
            Spacer()
            Text(balance.currency)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(balance < 0 ? Color.mmError : Color.mmTextPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.mmCard)
        .cornerRadius(12)
    }
}

/// Stat card that shows adjusted as primary and raw as smaller sub-text when they differ
struct AdjustedStatCard: View {
    let title: String
    let adjValue: Double
    let rawValue: Double
    var color: Color = .mmAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                .lineLimit(1)
            Text(adjValue.currency)
                .font(.system(size: 15, weight: .bold)).foregroundStyle(color)
                .lineLimit(1)
            if abs(adjValue - rawValue) > 0.001 {
                Text("Raw: \(rawValue.currency)")
                    .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

/// Thin wrapper so pending-requests nav destination compiles (EditRequestsView is defined in AdminMoreView)
private struct AdminEditRequestsDestination: View {
    var body: some View {
        EditRequestsView()
    }
}

struct ShowroomSnapshotRow: View {
    let snap: ShowroomSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snap.showroomName)
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                Spacer()
                Text("\(snap.entryCount) entries")
                    .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cash Main").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                    Text(snap.cashMainTotal.currency).font(.system(size: 13, weight: .medium))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cash Mano").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                    Text(snap.cashManoTotal.currency).font(.system(size: 13, weight: .medium))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Card").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                    Text(snap.cardTotal.currency).font(.system(size: 13, weight: .medium))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                    Text(snap.combinedTotal.currency)
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Color.mmAccent)
                }
            }
        }
        .padding(14)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

