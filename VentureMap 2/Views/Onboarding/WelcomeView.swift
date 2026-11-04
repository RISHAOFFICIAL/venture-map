import SwiftUI

/// An alternate "welcome" screen with its own copy and layout.
///
/// Note: nothing currently presents this view — `ContentView` shows
/// `SplashView` instead. It's left in the project as an example of a second,
/// unused design for the same moment in the app; a good one to experiment
/// with since changing it can't break the rest of the app.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.18), Color.cyan.opacity(0.08), Color(uiColor: .systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                VentureMapLogo(size: 96)

                VStack(spacing: 10) {
                    Text("VentureMap")
                        .font(.largeTitle.weight(.bold))
                    Text("See your community reach. Find the next place to make an impact.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 38)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Sign up") {
                        onContinue()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Button("Sign in to your profile") {
                        onContinue()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }
}
