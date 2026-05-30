import SwiftUI

@main
struct MoneyManagerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
        }
    }
}
