import SwiftUI

/// The "create an account" screen — essentially the same shell as
/// `SignInView` (both use `AuthenticationForm`), but with a different set of
/// fields and no "saved account" shortcut, since there's nothing saved yet.
struct SignUpView: View {
    @State private var organizationName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var primaryLocation = ""
    // The signed-in account's details, shown later in `ProfileView`.
    @AppStorage("accountOrganization") private var accountOrganization = ""
    @AppStorage("accountEmail") private var accountEmail = ""
    @AppStorage("accountLocation") private var accountLocation = ""

    let onCancel: () -> Void
    let onComplete: () -> Void

    var body: some View {
        AuthenticationForm(
            title: "Create your profile",
            subtitle: "Set up your organization and start tracking your impact.",
            primaryActionTitle: "Create account",
            onCancel: onCancel,
            onComplete: {
                accountOrganization = organizationName.trimmingCharacters(in: .whitespacesAndNewlines)
                accountEmail = email
                accountLocation = primaryLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                onComplete()
            }
        ) {
            TextField("Organization name", text: $organizationName)
                .textInputAutocapitalization(.words)
            TextField("Primary location", text: $primaryLocation)
                .textInputAutocapitalization(.words)
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            SecureField("Create password", text: $password)
        }
    }
}
