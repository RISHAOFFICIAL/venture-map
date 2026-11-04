import SwiftUI

/// A static banner shown on the home screen only while browsing as a guest,
/// reminding them that their data isn't being saved. No state, no
/// parameters that change behavior — just a fixed piece of UI.
struct PracticeModeBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("You're in guest mode — explore freely. Tap the menu to sign in or sign up.")
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.18, green: 0.41, blue: 0.24), in: RoundedRectangle(cornerRadius: 10))
    }
}
