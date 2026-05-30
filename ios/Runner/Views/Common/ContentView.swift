import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            switch auth.state {
            case .initial:
                SplashView()
                    .onAppear { auth.checkAuth() }
            case .loading:
                SplashView()
            case .unauthenticated:
                LoginView()
            case .authenticated:
                if auth.isAdmin {
                    AdminRootView()
                } else {
                    StaffRootView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.state)
    }
}
