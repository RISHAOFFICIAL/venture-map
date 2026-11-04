import SwiftUI

/// A business/organization that owns community outreach events.
///
/// `Business` is a `struct`, not a `class`. In Swift, structs are **value
/// types**: every time one is assigned to a new variable or passed into a
/// function, you get an independent copy. This is why, elsewhere in the app,
/// updating a business (like editing its name in `ProfileView`) requires
/// writing the whole modified struct back into the array that holds it —
/// there's no shared reference that mutates in place.
///
/// Conforming to `Identifiable` (just by having an `id` property) lets
/// SwiftUI use this type directly in `ForEach` and `.sheet(item:)` without
/// any extra boilerplate — SwiftUI uses `id` to know which row is which.
struct Business: Identifiable {
    let id = UUID()
    var name: String
    var location: String

    // `static` properties belong to the type itself, not to any one
    // instance — so you reach them with `Business.sampleBusinesses` rather
    // than `someBusiness.sampleBusinesses`. They're used here as ready-made
    // sample data for previews and for signed-in accounts.
    static let sampleBusinesses = [
        Business(name: "VentureMap Tech", location: "Detroit, MI"),
        Business(name: "VentureMap Labs", location: "Dearborn, MI")
    ]

    // A single, clearly-labeled business for guests so practice mode never
    // looks like a real signed-in account's data.
    static let practiceBusinesses = [
        Business(name: "Practice Business", location: "Sample City, MI")
    ]
}
