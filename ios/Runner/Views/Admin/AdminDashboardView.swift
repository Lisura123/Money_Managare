import SwiftUI

struct AdminDashboardView: View {
    @ObservedObject var vm: DashboardViewModel
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var editVM  = EditRequestViewModel()
    @StateObject private var cardVM  = CardAccountViewModel()
    @StateObject private var extVM   = ExternalAccountViewModel()
    @StateObject private var cashVM  = ShowroomCashViewModel()
    @State private var showEditRequests = false
    @State private var expandedShowrooms: Set<Int> = []

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = vm.error { ErrorBanner(message: e) }
                    if vm.newDayDetected { newDayBanner }

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
                        ProgressView().frame(maxWidth: .infinity).padding(60)
                    } else if let s = vm.summary {
                        dashboardContent(s)
                    }
                }
                .padding(16)
            }
            .background(Color.mmBackground)
            .navigationTitle("Dashboard")
            .refreshable {
                async let a: () = vm.fetch()
                async let b: () = editVM.fetchPendingCount()
                async let c: () = cardVM.fetchAll()
                async let d: () = extVM.fetchAll()
                async let e: () = cashVM.fetchAll()
                _ = await (a, b, c, d, e)
            }
            .onReceive(NotificationCenter.default.publisher(for: .balancesDidChange)) { _ in
                Task { await vm.fetch(silent: true) }
                Task { await cardVM.fetchAll() }
                Task { await extVM.fetchAll() }
                Task { await cashVM.fetchAll() }
            }
            .task {
                await editVM.fetchPendingCount()
                async let c: () = cardVM.fetchAll()
                async let e: () = extVM.fetchAll()
                async let h: () = cashVM.fetchAll()
                _ = await (c, e, h)
            }
            .navigationDestination(isPresented: $showEditRequests) {
                AdminEditRequestsDestination()
            }
        }
    }

    // MARK: - New Day Banner
    private var newDayBanner: some View {
        HStack {
            Image(systemName: "sun.rise.fill").foregroundStyle(Color.mmWarning)
            Text("New day — data refreshed")
                .font(.system(size: 13))
            Spacer()
            Button("Dismiss") { vm.clearNewDayNotification() }
                .font(.system(size: 12)).foregroundStyle(Color.mmAccent)
        }
        .padding(12)
        .background(Color.mmWarning.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Dashboard Content
    @ViewBuilder
    private func dashboardContent(_ s: DashboardSummary) -> some View {
        // Date strip
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                Text(s.serverDate.displayDate)
                    .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.mmTextPrimary)
            }
            Spacer()
            Text("Updated \(s.lastUpdatedAt.displayDateTime)")
                .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.trailing)
        }

        // 4 summary cards
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(title: "Main Cash",  value: s.today.cashMainAdjusted,
                        raw: s.today.cashMainTotal, icon: "banknote.fill", color: Color.mmPrimary)
            SummaryCard(title: "Mano Cash",  value: s.today.cashManoAdjusted,
                        raw: s.today.cashManoTotal, icon: "person.fill",   color: Color.mmAccent)
            SummaryCard(title: "Card Total", value: s.today.cardAdjusted,
                        raw: s.today.cardTotal,      icon: "creditcard.fill", color: Color(hex: "6366F1"))
            SummaryCard(title: "Grand Total", value: s.today.grandAdjusted,
                        raw: s.today.grandTotal,     icon: "chart.bar.fill",  color: Color.mmSuccess)
        }

        // Live balances strip — external cash accounts
        if !extVM.accounts.isEmpty {
            VStack(spacing: 8) {
                ForEach(extVM.accounts) { acc in
                    let isMain = acc.cashAccountType == "main"
                    LiveBalanceRow(
                        icon: isMain ? "building.columns.fill" : "banknote",
                        iconColor: isMain ? Color.mmPrimary : Color.mmAccent,
                        label: acc.name,
                        sublabel: "Live balance",
                        balance: acc.balance
                    )
                }
            }
        }

        // Per-showroom breakdown — today entries + live card/cash balances
        if !s.today.perShowroom.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Per Showroom — Today")
                ForEach(s.today.perShowroom) { snap in
                    ShowroomSnapshotCard(
                        snap: snap,
                        liveCards: cardVM.accounts.filter { $0.showroomId == snap.showroomId },
                        liveCash: cashVM.showrooms.first { $0.showroomId == snap.showroomId }?.balance ?? 0,
                        isExpanded: expandedShowrooms.contains(snap.showroomId)
                    ) {
                        if expandedShowrooms.contains(snap.showroomId) {
                            expandedShowrooms.remove(snap.showroomId)
                        } else {
                            expandedShowrooms.insert(snap.showroomId)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let value: Double
    let raw: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.12))
                    .cornerRadius(8)
                Spacer()
                if abs(value - raw) > 0.001 {
                    Text("adj")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(color.opacity(0.12))
                        .cornerRadius(4)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                Text(value.currency)
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(color)
                    .minimumScaleFactor(0.7).lineLimit(1)
                if abs(value - raw) > 0.001 {
                    Text("Raw: \(raw.currency)")
                        .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Live Balance Row

private struct LiveBalanceRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let sublabel: String
    let balance: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12))
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 14, weight: .medium))
                Text(sublabel).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
            }
            Spacer()
            Text(balance.currency)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(balance < 0 ? Color.mmError : iconColor)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.mmCard)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Showroom Snapshot Card (expandable)

private struct ShowroomSnapshotCard: View {
    let snap: ShowroomSnapshot
    let liveCards: [CardAccount]
    let liveCash: Double
    let isExpanded: Bool
    let onTap: () -> Void

    private var liveTotalCards: Double { liveCards.reduce(0) { $0 + $1.currentBalance } }

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.mmPrimary.opacity(0.1))
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.showroomName)
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(snap.entryCount) entr\(snap.entryCount == 1 ? "y" : "ies") today")
                            .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                    }
                    Spacer()
                    Text(snap.combinedTotal.currency)
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.mmAccent)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)

                // Today entries summary
                VStack(spacing: 0) {
                    expandRow(label: "Cash Main (today)",  value: snap.cashMainAdjusted,  raw: snap.cashMainTotal,  color: Color.mmPrimary)
                    expandRow(label: "Cash Mano (today)",  value: snap.cashManoAdjusted,  raw: snap.cashManoTotal,  color: Color.mmAccent)
                    expandRow(label: "Card Entry (today)", value: snap.cardAdjusted,       raw: snap.cardTotal,      color: Color(hex: "6366F1"))

                    Divider().padding(.horizontal, 14).padding(.vertical, 4)

                    // Live balances
                    HStack {
                        Label("Main Cash (live)", systemImage: "banknote.fill")
                            .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                        Text(liveCash.currency)
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)

                    HStack {
                        Label("Card Balance (live)", systemImage: "creditcard.fill")
                            .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                        Text(liveTotalCards.currency)
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)

                    if !liveCards.isEmpty {
                        Divider().padding(.horizontal, 14)
                        ForEach(liveCards) { acc in
                            HStack {
                                Text(acc.displayLabel)
                                    .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(acc.currentBalance.currency)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 18).padding(.vertical, 5)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color.mmCard)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    @ViewBuilder
    private func expandRow(label: String, value: Double, raw: Double, color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
            if abs(value - raw) > 0.001 {
                Text("adj").font(.system(size: 9, weight: .semibold)).foregroundStyle(color)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(color.opacity(0.12)).cornerRadius(3)
            }
            Spacer()
            Text(value.currency).font(.system(size: 13, weight: .semibold)).foregroundStyle(color)
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
    }
}

// MARK: - Stat card (kept for backward compat if referenced elsewhere)
struct AdjustedStatCard: View {
    let title: String
    let adjValue: Double
    let rawValue: Double
    var color: Color = .mmAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary).lineLimit(1)
            Text(adjValue.currency).font(.system(size: 15, weight: .bold)).foregroundStyle(color).lineLimit(1)
            if abs(adjValue - rawValue) > 0.001 {
                Text("Raw: \(rawValue.currency)").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary).lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

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

