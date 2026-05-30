import SwiftUI

struct StaffRootView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var tab: Tab = .home
    @StateObject private var statusVM = StaffStatusViewModel()

    enum Tab { case home, history, profile }

    var body: some View {
        TabView(selection: $tab) {
            StaffHomeTab(statusVM: statusVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }.tag(Tab.home)

            StaffHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }.tag(Tab.history)

            StaffProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }.tag(Tab.profile)
        }
        .tint(Color.mmPrimary)
        .task { await statusVM.fetch() }
    }
}
