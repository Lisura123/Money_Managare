import SwiftUI

struct StaffHomeTab: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject var statusVM: StaffStatusViewModel
    @State private var showCashEntry  = false
    @State private var showCardEntry  = false
    @State private var showMyRequests = false
    @StateObject private var editVM = EditRequestViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(greeting)!")
                                .font(.system(size: 14)).foregroundStyle(Color.mmTextSecondary)
                            Text(auth.user?.name ?? "")
                                .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.mmPrimary)
                            if let sn = auth.user?.showroomName {
                                Label(sn, systemImage: "storefront")
                                    .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                        Spacer()
                        if let user = auth.user {
                            AvatarView(initials: user.initials, size: 48)
                        }
                    }
                    .padding(20)
                    .background(Color.mmCard)
                    .cornerRadius(16)

                    // Pending edit requests banner
                    let pendingCount = editVM.myRequests.filter { $0.status == "pending" }.count
                    if pendingCount > 0 {
                        Button { showMyRequests = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundStyle(Color.mmWarning)
                                Text("\(pendingCount) edit request\(pendingCount == 1 ? "" : "s") pending review")
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

                    // Today's status
                    if statusVM.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    } else if let s = statusVM.todayStatus {
                        TodayStatusCard(status: s)
                    }

                    // Quick actions
                    VStack(spacing: 12) {
                        SectionHeader(title: "Quick Entry")
                        HStack(spacing: 12) {
                            ActionButton(title: "Cash Entry", icon: "banknote", color: .mmAccent) {
                                showCashEntry = true
                            }
                            ActionButton(title: "Bank Entry", icon: "creditcard", color: .mmPrimary) {
                                showCardEntry = true
                            }
                        }
                    }

                    if let e = statusVM.error {
                        ErrorBanner(message: e)
                    }
                }
                .padding(16)
            }
            .background(Color.mmBackground)
            .navigationTitle(AppConfig.appName)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await statusVM.fetch()
                await editVM.fetchMyRequests(refresh: true)
            }
            .sheet(isPresented: $showCashEntry, onDismiss: { Task { await statusVM.fetch() } }) {
                CashEntryView()
            }
            .sheet(isPresented: $showCardEntry, onDismiss: { Task { await statusVM.fetch() } }) {
                CardEntryView()
            }
            .sheet(isPresented: $showMyRequests) {
                MyEditRequestsView()
            }
            .task {
                await editVM.fetchMyRequests(refresh: true)
            }
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Morning" }
        if h < 17 { return "Afternoon" }
        return "Evening"
    }
}

// MARK: - Today status card

struct TodayStatusCard: View {
    let status: TodayStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today — \(status.date.displayDate)")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmTextSecondary)
                Spacer()
            }

            HStack(spacing: 12) {
                EntryStatusPill(
                    label: "Main Cash",
                    submitted: status.mainCash.submitted,
                    amount: status.mainCash.amount
                )
                EntryStatusPill(
                    label: "Mano Cash",
                    submitted: status.manoCash.submitted,
                    amount: status.manoCash.amount
                )
            }

            if status.card.count > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bank Entries (\(status.card.count))")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                    Text(status.card.total.currency)
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(Color.mmPrimary)
                }
            } else {
                Text("No bank entries today")
                    .font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(16)
        .background(Color.mmCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct EntryStatusPill: View {
    let label: String
    let submitted: Bool
    let amount: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
            if submitted, let a = amount {
                Text(a.currency).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.mmSuccess)
            } else {
                Text("Not submitted")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.mmError)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(submitted ? Color.mmSuccess.opacity(0.08) : Color.mmError.opacity(0.08))
        .cornerRadius(10)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 28)).foregroundStyle(color)
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.mmTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.mmCard)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}
