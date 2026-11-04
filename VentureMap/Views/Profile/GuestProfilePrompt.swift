import SwiftUI

/// What `ProfileView` shows instead of the real profile form when browsing
/// as a guest: a note that they're in guest mode, a tappable list of things
/// to try, and sign in/sign up buttons.
struct GuestProfilePrompt: View {
    let onSelectFeature: (GuestFeature) -> Void
    let onSignIn: () -> Void
    let onSignUp: () -> Void

    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    VentureMapLogo(size: 64)
                    VStack(spacing: 6) {
                        Text("You're in Guest Mode")
                            .font(.title3.weight(.bold))
                        Text("Explore VentureMap with sample data. Sign in to track your real community reach.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section("What you can do") {
                featureButton(.exploreMap) {
                    GuestFeatureRow(
                        icon: "map.fill",
                        tint: .green,
                        title: "Explore the map",
                        subtitle: "Tap pins to see sample events"
                    )
                }
                featureButton(.addEvent) {
                    GuestFeatureRow(
                        icon: "plus.circle.fill",
                        tint: .blue,
                        title: "Try adding events",
                        subtitle: "Events added as a guest are never saved"
                    )
                }
                featureButton(.checkReach) {
                    GuestFeatureRow(
                        icon: "chart.bar.fill",
                        tint: .orange,
                        title: "Check your reach",
                        subtitle: "See how outreach stats work"
                    )
                }
                featureButton(.saveProgress) {
                    GuestFeatureRow(
                        icon: "lock.fill",
                        tint: .gray,
                        title: "Save your progress",
                        subtitle: "Sign in to keep real data",
                        isLocked: true
                    )
                }
            }

            Section {
                Button("Sign in", action: onSignIn)
                    .frame(maxWidth: .infinity)
                Button("Create account", action: onSignUp)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Wraps a row in a plain button that reports which feature was tapped.
    private func featureButton<Row: View>(_ feature: GuestFeature, @ViewBuilder row: () -> Row) -> some View {
        Button {
            onSelectFeature(feature)
        } label: {
            row()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
