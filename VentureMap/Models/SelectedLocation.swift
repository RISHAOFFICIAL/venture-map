/// Wraps a location name so it can be used with SwiftUI's `.sheet(item:)`
/// and as `@State`.
///
/// Why wrap a plain `String` in a struct at all? `.sheet(item:)` needs an
/// `Identifiable`, *optional* value — when it's `nil`, no sheet shows; when
/// it becomes non-nil, SwiftUI presents a sheet. A bare `String?` can't
/// conform to `Identifiable`, so this tiny wrapper type exists purely to make
/// that pattern work. You'll see this same trick anywhere the app opens a
/// sheet based on "is something selected" (see `OutreachMap`'s
/// `selectedLocation`).
struct SelectedLocation: Identifiable {
    let location: String

    var id: String { location }
}
