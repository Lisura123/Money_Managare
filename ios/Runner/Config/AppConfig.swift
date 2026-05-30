import Foundation

enum AppEnvironment {
    case dev
    case production
}

enum AppConfig {
    // Change to .dev for local development
    static let environment: AppEnvironment = {
        if let env = ProcessInfo.processInfo.environment["APP_ENV"], env == "dev" {
            return .dev
        }
        return .production
    }()

    static let productionURL = "https://money.cameralkstore.com/api"
    static let devURL        = "http://localhost:8000/api"

    static var baseURL: String {
        switch environment {
        case .production: return productionURL
        case .dev:        return devURL
        }
    }

    static let connectTimeoutSeconds: TimeInterval = 15
    static let receiveTimeoutSeconds: TimeInterval = 15
    static let tokenKey   = "auth_token"
    static let userKey    = "current_user"
    static let appName    = "Money Manager"
    static let appVersion = "1.0.0"
    static let currencyPrefix = "Rs."
}
