import SwiftUI

/// The shared visual shell used by both `SignInView` and `SignUpView`: a
/// green background, logo, title/subtitle, a divider-free form area, and
/// then whatever form fields the caller provides.
///
/// This is the most advanced Swift feature in the whole project, so it's
/// worth slowing down on:
///
/// - **Generics** (`<Fields: View>`): instead of hard-coding what the form
///   fields look like, this view is generic over *any* type that conforms to
///   `View`. `SignInView` and `SignUpView` each pass in their own completely
///   different set of fields, and this same `AuthenticationForm` struct
///   handles both — the compiler specializes it for each call site.
/// - **`@ViewBuilder`**: normally a property can only hold one value, but
///   `@ViewBuilder let fields: Fields` combined with the trailing-closure
///   call syntax (`AuthenticationForm(...) { TextField(...); TextField(...) }`)
///   lets the caller write several views in a row, which SwiftUI silently
///   combines into one. This is the exact same mechanism that makes `VStack {
///   ... }` and `Form { ... }` able to accept multiple children.
struct AuthenticationForm<Fields: View>: View {
    let title: String
    let subtitle: String
    let primaryActionTitle: String
    let onCancel: () -> Void
    let onComplete: () -> Void
    @ViewBuilder let fields: Fields

    var body: some View {
        ZStack {
            Color(red: 0.18, green: 0.41, blue: 0.24)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Spacer()
                        Button(action: onCancel) {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(.white.opacity(0.16), in: Circle())
                        }
                        .foregroundStyle(.white)
                        .accessibilityLabel("Exit")
                    }

                    Image("VentureMapSplash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 170)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.largeTitle.weight(.bold))
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.76))
                    }
                    .foregroundStyle(.white)

                    // `fields` is the generic content passed in by whoever
                    // created this `AuthenticationForm` — this is where
                    // SignInView's or SignUpView's text fields actually get
                    // inserted into the layout.
                    VStack(spacing: 14) {
                        fields
                    }
                    .textFieldStyle(.roundedBorder)

                    Button(primaryActionTitle, action: onComplete)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(Color(red: 0.18, green: 0.41, blue: 0.24))
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
        }
    }
}
