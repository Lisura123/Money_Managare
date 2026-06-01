import SwiftUI

// MARK: - Color palette (mirrors Flutter AppColors)

extension Color {
    static let mmPrimary        = Color(hex: "1B2A4A")
    static let mmAccent         = Color(hex: "00BFA6")
    static let mmSuccess        = Color(hex: "4CAF50")
    static let mmError          = Color(hex: "EF5363")
    static let mmWarning        = Color(hex: "FFC107")
    static let mmBackground     = Color(hex: "F5F7FA")
    static let mmCard           = Color.white
    static let mmTextPrimary    = Color(hex: "1B2A4A")
    static let mmTextSecondary  = Color(hex: "6B7280")
    static let mmDivider        = Color(hex: "E5E7EB")
    static let mmInputFill      = Color(hex: "F9FAFB")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Currency formatter

extension Double {
    var currency: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let str = f.string(from: NSNumber(value: self)) ?? "0.00"
        return "\(AppConfig.currencyPrefix) \(str)"
    }
}

// MARK: - Date formatting

extension String {
    /// "2024-05-30" or ISO timestamp → "May 30, 2024"
    var displayDate: String {
        let out = DateFormatter()
        out.dateStyle = .medium; out.timeStyle = .none

        // Try plain date first
        let plain = DateFormatter()
        plain.dateFormat = "yyyy-MM-dd"
        if let d = plain.date(from: self) { return out.string(from: d) }

        // Try ISO8601 with fractional seconds
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: self) { return out.string(from: d) }

        // Try ISO8601 without fractional seconds
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: self) { return out.string(from: d) }

        // Fallback: extract date part before 'T'
        let datePart = String(self.prefix(10))
        plain.dateFormat = "yyyy-MM-dd"
        if let d = plain.date(from: datePart) { return out.string(from: d) }

        return self
    }

    /// ISO8601 → "May 30, 2024 02:45 PM"
    var displayDateTime: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: self) {
            let out = DateFormatter()
            out.dateStyle = .medium; out.timeStyle = .short
            return out.string(from: d)
        }
        return self
    }
}
