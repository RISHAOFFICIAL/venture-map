import SwiftUI

/// The "sign in" screen. It builds its form fields and hands them to the
/// shared `AuthenticationForm` layout (see that file for the reusable shell).
///
/// Interesting things to notice:
/// - `@AppStorage` is used three times here to remember the last signed-in
///   account's organization/email across app launches, and whether "stay
///   signed in" was on. Each `@AppStorage` key (`"staysSignedIn"`, etc.) maps
///   to a slot in `UserDefaults` — change the key and it becomes a different
///   stored value.
/// - `hasSavedAccount` is a **computed property**, recalculated every time
///   it's read, rather than a stored `Bool` — it always reflects the current
///   `savedAccountOrganization` instead of getting out of sync with it.
/// - This view has no navigation/dismiss logic of its own; `onCancel` and
///   `onComplete` closures, passed in from `ContentView`, are how it reports
///   back up the view hierarchy.
struct SignInView: View {
    @State private var organizationName = ""
    @State private var email = ""
    @State private var password = ""
    @AppStorage("staysSignedIn") private var staysSignedIn = false
    @AppStorage("savedAccountOrganization") private var savedAccountOrganization = ""
    @AppStorage("savedAccountEmail") private var savedAccountEmail = ""
    @AppStorage("accountOrganization") private var accountOrganization = ""
    @AppStorage("accountEmail") private var accountEmail = ""
    @AppStorage("accountLocation") private var accountLocation = ""
    @State private var showsManualForm = false

    let onCancel: () -> Void
    let onComplete: () -> Void

    private var hasSavedAccount: Bool {
        !savedAccountOrganization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Records who signed in (so `ProfileView` can show it), then finishes.
    private func completeSignIn() {
        let typedOrganization = organizationName.trimmingCharacters(in: .whitespacesAndNewlines)
        // With the one-tap saved account showing, the text fields are empty,
        // so fall back to the saved account's details.
        let usesSavedAccount = typedOrganization.isEmpty && hasSavedAccount && !showsManualForm
        let organization = usesSavedAccount ? savedAccountOrganization : typedOrganization
        let accountEmailValue = usesSavedAccount ? savedAccountEmail : email

        if !organization.isEmpty {
            accountOrganization = organization
            accountEmail = accountEmailValue
            accountLocation = ""

            // Remember this account so next time "Stay signed in" offers a
            // one-tap option instead of asking the person to retype everything.
            if staysSignedIn {
                savedAccountOrganization = organization
                savedAccountEmail = accountEmailValue
            }
        }
        onComplete()
    }

    var body: some View {
        AuthenticationForm(
            title: "Welcome back",
            subtitle: "Sign in to continue mapping your community reach.",
            primaryActionTitle: "Sign in",
            onCancel: onCancel,
            onComplete: {
                completeSignIn()
            }
        ) {
            // This trailing closure is passed as the generic `Fields` view
            // builder parameter of `AuthenticationForm` — see that file for
            // how `@ViewBuilder` makes this possible.
            if hasSavedAccount && !showsManualForm {
                SavedAccountRow(
                    organizationName: savedAccountOrganization,
                    email: savedAccountEmail,
                    onSelect: completeSignIn,
                    onUseAnotherAccount: { showsManualForm = true }
                )
            } else {
                TextField("Organization name", text: $organizationName)
                    .textInputAutocapitalization(.words)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                Toggle("Stay signed in", isOn: $staysSignedIn)

                if hasSavedAccount {
                    Button("Use \(savedAccountOrganization) instead") {
                        showsManualForm = false
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
    }
}
