import Foundation

// Utility to decode JSON values that may be String, Int, or Double
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self)    { value = i; return }
        if let d = try? c.decode(Double.self)  { value = d; return }
        if let s = try? c.decode(String.self)  { value = s; return }
        if let b = try? c.decode(Bool.self)    { value = b; return }
        value = NSNull()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let i as Int:    try c.encode(i)
        case let d as Double: try c.encode(d)
        case let s as String: try c.encode(s)
        case let b as Bool:   try c.encode(b)
        default:              try c.encodeNil()
        }
    }
}

// Convenience helper for Double-from-JSON (handles String or Number)
extension Double {
    static func from(json: Any?) -> Double {
        guard let v = json else { return 0 }
        if let d = v as? Double  { return d }
        if let i = v as? Int     { return Double(i) }
        if let s = v as? String  { return Double(s) ?? 0 }
        return 0
    }
}
