import Foundation

// MARK: - Error types

enum APIError: LocalizedError {
    case network(String)
    case unauthorised
    case validation(String, [String: [String]])
    case server(Int, String)
    case decoding(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .network(let m):         return m
        case .unauthorised:           return "Session expired. Please login again."
        case .validation(_, let e):
            return e.values.first?.first ?? "Validation failed."
        case .server(_, let m):       return m
        case .decoding(let m):        return "Decoding error: \(m)"
        case .unknown(let m):         return m
        }
    }
}

// MARK: - Pagination wrapper

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let meta: Meta?

    struct Meta: Decodable {
        let currentPage: Int?
        let lastPage: Int?
        let total: Int?
        let totalAmount: Double?

        enum CodingKeys: String, CodingKey {
            case currentPage  = "current_page"
            case lastPage     = "last_page"
            case total
            case totalAmount  = "total_amount"
        }
    }
}

// MARK: - Callback for 401

typealias UnauthorisedHandler = @MainActor () -> Void

// MARK: - API Service

@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    var onUnauthorised: UnauthorisedHandler?

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = AppConfig.connectTimeoutSeconds
        config.timeoutIntervalForResource = AppConfig.receiveTimeoutSeconds
        config.httpAdditionalHeaders = [
            "Accept":       "application/json",
            "Content-Type": "application/json"
        ]
        session = URLSession(configuration: config)
    }

    // MARK: HTTP verbs

    func get<T: Decodable>(_ path: String, query: [String: Any] = [:]) async throws -> T {
        try await request(method: "GET", path: path, query: query, body: nil)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try await request(method: "POST", path: path, query: [:], body: body)
    }

    func put<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try await request(method: "PUT", path: path, query: [:], body: body)
    }

    func patch<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        try await request(method: "PATCH", path: path, query: [:], body: body)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "DELETE", path: path, query: [:], body: nil)
    }

    /// Fire-and-forget version (ignores response body)
    func postVoid(_ path: String, body: [String: Any]? = nil) async throws {
        let _: EmptyResponse = try await request(method: "POST", path: path, query: [:], body: body)
    }

    // MARK: - Private

    private func request<T: Decodable>(
        method: String,
        path: String,
        query: [String: Any],
        body: [String: Any]?
    ) async throws -> T {
        var components = URLComponents(string: AppConfig.baseURL + path)!
        if !query.isEmpty {
            components.queryItems = query.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = try? KeychainService.read(for: AppConfig.tokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        #if DEBUG
        print("→ \(method) \(path)")
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.network("Network error. Please check your connection.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        #if DEBUG
        print("← \(http.statusCode) \(path)")
        #endif

        switch http.statusCode {
        case 200...299:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error.localizedDescription)
            }
        case 401:
            KeychainService.delete(for: AppConfig.tokenKey)
            KeychainService.delete(for: AppConfig.userKey)
            onUnauthorised?()
            throw APIError.unauthorised
        case 422:
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = json["message"] as? String ?? "Validation failed"
                var errors: [String: [String]] = [:]
                if let rawErrors = json["errors"] as? [String: Any] {
                    for (k, v) in rawErrors {
                        if let arr = v as? [String] {
                            errors[k] = arr
                        } else {
                            errors[k] = ["\(v)"]
                        }
                    }
                }
                throw APIError.validation(msg, errors)
            }
            throw APIError.server(422, "Validation failed")
        default:
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw APIError.server(http.statusCode, msg)
        }
    }
}

private struct EmptyResponse: Decodable {}
