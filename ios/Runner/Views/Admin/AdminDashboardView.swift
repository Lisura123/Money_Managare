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

        // Summary cards — totals match the sum of the per-showroom live balances below
        let liveTotalCash = cashVM.showrooms.reduce(0) { $0 + $1.balance }
        let liveTotalBank = cardVM.accounts.reduce(0) { $0 + $1.currentBalance }
        let liveTotalMano = extVM.accounts.filter { $0.cashAccountType == "mano" }.reduce(0) { $0 + $1.balance }
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(title: "Total Cash Amount",  value: liveTotalCash,
                        raw: liveTotalCash, icon: "banknote.fill", color: Color.mmPrimary)
            SummaryCard(title: "Total Mano's Amount",  value: liveTotalMano,
                        raw: liveTotalMano, icon: "person.fill",   color: Color.mmAccent)
            SummaryCard(title: "Total Bank Amount", value: liveTotalBank,
                        raw: liveTotalBank,      icon: "creditcard.fill", color: Color(hex: "6366F1"))
        }

        // Per-showroom breakdown — live cash + bank balances
        if !s.today.perShowroom.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Per Showroom")
                ForEach(orderedShowrooms(s.today.perShowroom)) { snap in
                    ShowroomSnapshotCard(
                        snap: snap,
                        isMain: isMainShowroom(snap.showroomName),
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

    // MARK: - Showroom ordering helpers

    /// The two flagship showrooms shown at the top and highlighted.
    private func isMainShowroom(_ name: String) -> Bool {
        let upper = name.uppercased()
        return upper.contains("CAMERALK") || upper.contains("SONY")
    }

    /// Main showrooms first (CAMERALK, then SONY), remaining showrooms after.
    private func orderedShowrooms(_ list: [ShowroomSnapshot]) -> [ShowroomSnapshot] {
        func rank(_ s: ShowroomSnapshot) -> Int {
            let upper = s.showroomName.uppercased()
            if upper.contains("CAMERALK") { return 0 }
            if upper.contains("SONY")     { return 1 }
            return 2
        }
        return list.sorted { a, b in
            let ra = rank(a), rb = rank(b)
            if ra != rb { return ra < rb }
            return a.showroomName < b.showroomName
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
    var sublabel: String? = nil

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
                if let sub = sublabel {
                    Text(sub)
                        .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                } else if abs(value - raw) > 0.001 {
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
    let isMain: Bool
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
                    Image(systemName: isMain ? "star.fill" : "storefront.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(isMain ? Color.mmWarning : Color.mmPrimary)
                        .frame(width: 32, height: 32)
                        .background((isMain ? Color.mmWarning : Color.mmPrimary).opacity(0.12))
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.showroomName)
                            .font(.system(size: 14, weight: isMain ? .bold : .semibold))
                        if isMain {
                            Text("Main showroom")
                                .font(.system(size: 11, weight: .medium)).foregroundStyle(Color.mmWarning)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 9)).foregroundStyle(Color.mmPrimary)
                            Text(liveCash.currency)
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.mmPrimary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 9)).foregroundStyle(Color(hex: "6366F1"))
                            Text(liveTotalCards.currency)
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: "6366F1"))
                        }
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    // Totals
                    HStack {
                        Label("Total Main Cash Amount", systemImage: "banknote.fill")
                            .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                        Text(liveCash.currency)
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)

                    HStack {
                        Label("Total Bank Amount", systemImage: "creditcard.fill")
                            .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                        Text(liveTotalCards.currency)
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)

                    // Individual bank account balances
                    if !liveCards.isEmpty {
                        Divider().padding(.horizontal, 14).padding(.vertical, 4)
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isMain ? Color.mmWarning.opacity(0.5) : Color.clear, lineWidth: isMain ? 1.5 : 0)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
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
                    Text("Bank").font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
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
