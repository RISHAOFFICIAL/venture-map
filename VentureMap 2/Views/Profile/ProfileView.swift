import SwiftUI

/// The profile sheet: account/organization settings and the list of
/// businesses, or (for guests) a sign-in prompt instead.
///
/// - **`@Binding var businesses: [Business]`**: this view edits the parent's
///   array of businesses directly through the binding. `ForEach($businesses)
///   { $business in ... }` is a neat trick worth noticing: binding to a
///   collection and then re-binding each element (`$business`) inside the
///   loop lets every row's `TextField` edit that one business in place.
/// - **`isEditingBusinesses`** is a plain `@State` flag that swaps each
///   business row between read-only `Text` and editable `TextField`s, so
///   nothing can be changed until "Edit" is pressed.
/// - Notice the top-level `if allowsSaving { ... } else { ... }` inside
///   `body` — an entire `Form` versus an entire `GuestProfilePrompt`,
///   chosen once per redraw depending on whether this is a guest session.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var accountName: String
    @Binding var organizationFocus: String
    @Binding var businesses: [Business]
    @Binding var selectedBusinessID: UUID
    let allowsSaving: Bool
    let onRequireSignIn: () -> Void
    let onRequireSignUp: () -> Void
    let onSelectGuestFeature: (GuestFeature) -> Void
    // Details captured at sign in / sign up (see `SignInView`, `SignUpView`).
    @AppStorage("accountEmail") private var accountEmail = ""
    @AppStorage("accountLocation") private var accountLocation = ""
    // Account and business rows are read-only until "Edit" is pressed.
    @State private var isEditingAccount = false
    @State private var isEditingBusinesses = false

    /// One label/value line in the Account section: plain text normally, an
    /// editable `TextField` while the section is being edited.
    @ViewBuilder
    private func accountRow(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        LabeledContent(title) {
            if isEditingAccount {
                TextField(placeholder, text: text)
                    .multilineTextAlignment(.trailing)
            } else {
                Text(text.wrappedValue.isEmpty ? "—" : text.wrappedValue)
            }
        }
    }

    /// Removes a business, always keeping at least one, and re-selects
    /// another if the active one was deleted.
    private func deleteBusiness(_ business: Business) {
        guard businesses.count > 1 else { return }
        businesses.removeAll { $0.id == business.id }
        if !businesses.contains(where: { $0.id == selectedBusinessID }) {
            selectedBusinessID = businesses[0].id
        }
    }

    var body: some View {
        NavigationStack {
            if allowsSaving {
                Form {
                    Section {
                        // Read-only text until Edit is pressed, then fields.
                        accountRow("Organization", text: $accountName, placeholder: "Organization name")
                        if isEditingAccount || !accountEmail.isEmpty {
                            accountRow("Email", text: $accountEmail, placeholder: "Email")
                        }
                        if isEditingAccount || !accountLocation.isEmpty {
                            accountRow("Location", text: $accountLocation, placeholder: "City, State")
                        }
                        accountRow("Focus", text: $organizationFocus, placeholder: "Organization focus")
                    } header: {
                        HStack {
                            Text("Account")
                            Spacer()
                            Button(isEditingAccount ? "Confirm" : "Edit") {
                                withAnimation { isEditingAccount.toggle() }
                            }
                            .fontWeight(isEditingAccount ? .semibold : .regular)
                            .textCase(nil)
                        }
                    }

                    Section {
                        ForEach($businesses) { $business in
                            HStack(spacing: 12) {
                                if isEditingBusinesses {
                                    Button {
                                        deleteBusiness(business)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(businesses.count <= 1)
                                    .accessibilityLabel("Delete \(business.name)")
                                }

                                // Plain text until Edit is pressed, so rows
                                // can't be changed by accident.
                                VStack(alignment: .leading) {
                                    if isEditingBusinesses {
                                        TextField("Business name", text: $business.name)
                                        TextField("Business location", text: $business.location)
                                            .font(.caption)
                                    } else {
                                        Text(business.name)
                                        Text(business.location)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isEditingBusinesses {
                                    selectedBusinessID = business.id
                                }
                            }
                        }

                        if isEditingBusinesses {
                            Button {
                                let business = Business(name: "New business", location: "Detroit, MI")
                                businesses.append(business)
                                selectedBusinessID = business.id
                            } label: {
                                Label("Add another business", systemImage: "plus.circle.fill")
                            }
                        }
                    } header: {
                        // The Edit/Confirm button lives here so it only
                        // applies to the businesses list.
                        HStack {
                            Text("Businesses")
                            Spacer()
                            Button(isEditingBusinesses ? "Confirm" : "Edit") {
                                withAnimation { isEditingBusinesses.toggle() }
                            }
                            .fontWeight(isEditingBusinesses ? .semibold : .regular)
                            .textCase(nil)
                        }
                    }
                }
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel("Confirm profile changes")
                    }
                }
            } else {
                GuestProfilePrompt(
                    onSelectFeature: { feature in
                        dismiss()
                        onSelectGuestFeature(feature)
                    },
                    onSignIn: {
                        dismiss()
                        onRequireSignIn()
                    },
                    onSignUp: {
                        dismiss()
                        onRequireSignUp()
                    }
                )
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
    }
}
