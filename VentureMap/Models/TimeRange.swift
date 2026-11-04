import SwiftUI

/// A selectable date filter ("30 days", "90 days", "This year") used by
/// `EventFilters` to narrow down which events show on the map.
enum TimeRange: CaseIterable, Identifiable {
    case thirtyDays
    case ninetyDays
    case thisYear

    // `Self` here means "whatever type this is" — i.e. `TimeRange`. Using an
    // enum case as its own `id` is a common shortcut when the cases
    // themselves are already unique and `Equatable`.
    var id: Self { self }

    var title: String {
        switch self {
        case .thirtyDays: "30 days"
        case .ninetyDays: "90 days"
        case .thisYear: "This year"
        }
    }

    /// Checks whether a given date falls inside this range, counting
    /// backwards from right now. This is a regular **method** (a function
    /// that belongs to the type), not a computed property, because it needs
    /// an input (`date`) to produce an answer.
    func includes(_ date: Date) -> Bool {
        let calendar = Calendar.current

        switch self {
        case .thirtyDays:
            return date >= calendar.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        case .ninetyDays:
            return date >= calendar.date(byAdding: .day, value: -90, to: .now) ?? .distantPast
        case .thisYear:
            return date >= calendar.dateInterval(of: .year, for: .now)?.start ?? .distantPast
        }
    }
}
