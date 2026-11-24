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
///
/// `Codable` lets the app save the businesses list to UserDefaults as
/// JSON, so businesses a user adds survive app relaunches (see
/// `BusinessStore` in `VentureMapHomeView`). `Equatable` lets the home
/// view watch the list for changes with `.onChange(of:)`, so it knows
/// when to save. Both are synthesized: every property is already
/// `Codable` and `Equatable`, so the compiler writes the methods.
struct Business: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var location: String

    init(id: UUID = UUID(), name: String, location: String) {
        self.id = id
        self.name = name
        self.location = location
    }

    // `static` properties belong to the type itself, not to any one
    // instance — so you reach them with `Business.sampleBusinesses` rather
    // than `someBusiness.sampleBusinesses`. They're used here as ready-made
    // sample data for previews and for signed-in accounts.
    //
    // The sample businesses use fixed ids on purpose: saved events point at
    // a business by id, so the ids must stay the same across launches or
    // saved events would stop matching any business after a restart.
    // Businesses created in the app (see ProfileView) still get a fresh
    // random id from the `init` default above.
    static let sampleBusinesses = [
        Business(id: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!, name: "VentureMap Tech", location: "Detroit, MI"),
        Business(id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!, name: "VentureMap Labs", location: "Dearborn, MI")
    ]

    // A single, clearly-labeled business for guests so practice mode never
    // looks like a real signed-in account's data.
    static let practiceBusinesses = [
        Business(id: UUID(uuidString: "33333333-3333-4333-8333-333333333333")!, name: "Practice Business", location: "Sample City, MI")
    ]
}
