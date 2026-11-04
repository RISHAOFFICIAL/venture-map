import SwiftUI

/// A full-screen, swipeable onboarding tutorial shown automatically the
/// first time someone enters the app as a guest (see
/// `VentureMapHomeView.onAppear`).
///
/// - `pages` is a `let` constant array of `TutorialPage` values — the content
///   is fixed; only `page` (which index is currently showing) changes.
/// - `TabView(selection: $page)` combined with `.tabViewStyle(.page(...))`
///   turns a `TabView` into a swipeable, dot-indicator carousel instead of
///   its default top-tab appearance.
/// - `ForEach(Array(pages.enumerated()), id: \.offset)` is a common pattern
///   for looping with both an element *and* its index: `.enumerated()` pairs
///   each element with its position, and `id: \.offset` tells `ForEach` to
///   use that position as the unique identifier (since `TutorialPage` itself
///   isn't `Identifiable`).
struct GuestTutorialView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "map.fill",
            tint: .green,
            title: "Explore the Map",
            description: "Pan and zoom around a sample neighborhood with practice events already plotted for you."
        ),
        TutorialPage(
            icon: "mappin.and.ellipse",
            tint: .red,
            title: "Tap a Pin",
            description: "Select any marker to open a full callout with event details, right on the map."
        ),
        TutorialPage(
            icon: "plus.circle.fill",
            tint: .blue,
            title: "Add a Practice Event",
            description: "Try the + button to see how logging an event works. Practice entries are just for learning and won't be saved."
        ),
        TutorialPage(
            icon: "person.crop.circle.badge.checkmark",
            tint: .purple,
            title: "Sign In Anytime",
            description: "Ready to track your real outreach? Tap the menu button to sign in or create an account."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, tutorialPage in
                    TutorialPageView(page: tutorialPage)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Start exploring" : "Next") {
                    if page == pages.count - 1 {
                        onFinish()
                    } else {
                        // `withAnimation` wraps a state change so SwiftUI
                        // animates the resulting UI update instead of jumping
                        // instantly to the new value.
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                if page < pages.count - 1 {
                    Button("Skip", action: onFinish)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
