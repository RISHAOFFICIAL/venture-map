import SwiftUI

/// Renders a single page of the guest tutorial from a `TutorialPage` model.
/// `GuestTutorialView` puts several of these inside a swipeable `TabView`.
struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.tint.gradient)
                    .frame(width: 96, height: 96)
                Image(systemName: page.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: page.tint.opacity(0.35), radius: 16, y: 8)

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.title2.weight(.bold))
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
