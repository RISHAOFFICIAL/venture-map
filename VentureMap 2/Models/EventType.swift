/// The kind of outreach event someone logs — shown in pickers throughout the
/// app (see `AddEventView`, `EventEditorView`, `EventInformation`).
///
/// A few things worth noticing about this enum:
/// - `: String` means each case has a hidden "raw value" (the case name,
///   lowercased), which is handy for storage/debugging even though we never
///   print it directly here.
/// - `CaseIterable` auto-generates `EventType.allCases`, an array of every
///   case in declaration order. That's what lets the `ForEach(EventType.allCases)`
///   loops elsewhere build a picker without us having to list the cases twice.
/// - `Identifiable` (via the `id` computed property) lets SwiftUI tell cases
///   apart inside a `ForEach`.
enum EventType: String, CaseIterable, Identifiable {
    case communityEvent
    case workshop
    case listeningSession

    var id: String { rawValue }

    /// Human-readable text for display — kept separate from the raw value so
    /// the on-screen wording can change without affecting the underlying case.
    var title: String {
        switch self {
        case .communityEvent: "Community event"
        case .workshop: "Workshop"
        case .listeningSession: "Listening session"
        }
    }

    /// Each event type maps to a default `EventCategory`, which in turn
    /// decides the marker color on the map. This keeps "workshops are
    /// orange" defined in exactly one place.
    var category: EventCategory {
        switch self {
        case .communityEvent: .communityEvent
        case .workshop: .orange
        case .listeningSession: .red
        }
    }
}
