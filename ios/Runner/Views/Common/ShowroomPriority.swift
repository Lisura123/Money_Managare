import SwiftUI

// MARK: - Flagship showroom prioritisation
//
// The two flagship showrooms — CAMERALK (PVT) LTD and SONY ASIA PACIFIC (PVT) LTD —
// should always appear at the top of every showroom dropdown and be visually
// highlighted for easier selection.

/// True when a showroom name belongs to one of the flagship showrooms.
func isFlagshipShowroomName(_ name: String) -> Bool {
    let upper = name.uppercased()
    return upper.contains("CAMERALK") || upper.contains("SONY")
}

extension Showroom {
    var isFlagship: Bool { isFlagshipShowroomName(name) }
}

extension ShowroomCashBalance {
    var isFlagship: Bool { isFlagshipShowroomName(showroomName) }
}

/// Anything that can be displayed in a showroom dropdown.
protocol ShowroomDisplayable: Identifiable {
    var displayName: String { get }
    var isFlagshipShowroom: Bool { get }
}

extension Showroom: ShowroomDisplayable {
    var displayName: String { name }
    var isFlagshipShowroom: Bool { isFlagship }
}

extension ShowroomCashBalance: ShowroomDisplayable {
    var displayName: String { showroomName }
    var isFlagshipShowroom: Bool { isFlagship }
}

extension Array where Element: ShowroomDisplayable {
    /// Flagship showrooms first (in their original relative order), then the rest.
    func prioritized() -> [Element] {
        let flagships = filter { $0.isFlagshipShowroom }
        let others    = filter { !$0.isFlagshipShowroom }
        return flagships + others
    }
}

// MARK: - Dropdown option label

/// Styled label for a showroom inside a Picker / Menu. Flagship showrooms get a
/// star icon and bold text so they stand out at the top of the list.
struct ShowroomOptionLabel: View {
    let name: String
    let isFlagship: Bool

    init(name: String, isFlagship: Bool) {
        self.name = name
        self.isFlagship = isFlagship
    }

    init(_ showroom: any ShowroomDisplayable) {
        self.name = showroom.displayName
        self.isFlagship = showroom.isFlagshipShowroom
    }

    var body: some View {
        if isFlagship {
            Label(name, systemImage: "star.fill")
                .fontWeight(.semibold)
        } else {
            Text(name)
        }
    }
}
