import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.mmPrimary.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                Text(AppConfig.appName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                ProgressView().tint(.white)
            }
        }
    }
}
