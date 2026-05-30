import SwiftUI

struct AdminRootView: View {
    @StateObject private var dashVM = DashboardViewModel()

    var body: some View {
        TabView {
            AdminDashboardView(vm: dashVM)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            EntriesHubView()
                .tabItem { Label("Entries", systemImage: "list.bullet.rectangle") }

            TransactionsHubView()
                .tabItem { Label("Transfers", systemImage: "arrow.left.arrow.right") }

            ShowroomListView()
                .tabItem { Label("Showrooms", systemImage: "storefront.fill") }

            AdminMoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .tint(Color.mmPrimary)
        .task { await dashVM.fetch() }
        .onAppear { dashVM.startPolling() }
        .onReceive(NotificationCenter.default.publisher(for: .balancesDidChange)) { _ in
            Task { await dashVM.fetch(silent: true) }
        }
    }
}
