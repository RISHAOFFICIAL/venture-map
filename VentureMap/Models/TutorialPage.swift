import SwiftUI

/// The content for one page of the guest onboarding carousel
/// (`GuestTutorialView` / `TutorialPageView`).
///
/// This is about as simple as a model gets: four stored properties, no
/// computed properties, no methods. Not every type needs behavior — plain
/// "bags of data" like this are extremely common and perfectly idiomatic.
struct TutorialPage {
    let icon: String
    let tint: Color
    let title: String
    let description: String
}
