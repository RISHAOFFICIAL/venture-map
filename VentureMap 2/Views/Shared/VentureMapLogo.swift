import SwiftUI

/// A reusable app logo badge (gradient circle + icon), sized by the caller.
/// Used in `WelcomeView` and `GuestProfilePrompt`.
///
/// `size` is a single `CGFloat` that drives both the circle's diameter and
/// the icon's font size proportionally (`size * 0.42`) — a common technique
/// for making a reusable component that scales cleanly at any size, instead
/// of hard-coding pixel values.
struct VentureMapLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.indigo.gradient)
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: .indigo.opacity(0.24), radius: 14, y: 8)
        .accessibilityLabel("VentureMap")
    }
}
