import SwiftUI

/// A tappable "welcome back" card shown on `SignInView` when a previous
/// account was saved, so returning users can sign in with one tap instead of
/// retyping everything.
struct SavedAccountRow: View {
    let organizationName: String
    let email: String
    let onSelect: () -> Void
    let onUseAnotherAccount: () -> Void

    // A computed property that derives initials (e.g. "VentureMap Tech" ->
    // "VT") from the organization name, recalculated fresh every time it's
    // read — there's no separate "initials" field to keep in sync.
    private var initials: String {
        let letters = organizationName.split(separator: " ").prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.18))
                        Text(initials)
                            .font(.headline)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(organizationName)
                            .font(.subheadline.weight(.semibold))
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(12)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .foregroundStyle(.white)
            .accessibilityLabel("Sign in as \(organizationName)")

            Button("Use another account", action: onUseAnotherAccount)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
