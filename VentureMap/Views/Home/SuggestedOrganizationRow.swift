import SwiftUI

/// One suggested organization: its name, a short description, and tappable
/// contact details (website, phone, email) when the search found them.
struct SuggestedOrganizationRow: View {
    let organization: SuggestedOrganization

    private var websiteURL: URL? {
        organization.website.flatMap { URL(string: $0) }
    }

    private var phoneURL: URL? {
        guard let phone = organization.phone else { return nil }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(digits)")
    }

    private var emailURL: URL? {
        organization.email.flatMap { URL(string: "mailto:\($0)") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(organization.name)
                .font(.body.weight(.semibold))

            if let summary = organization.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            VStack(alignment: .leading, spacing: 3) {
                if let phoneURL, let phone = organization.phone {
                    Link(destination: phoneURL) { Label(phone, systemImage: "phone") }
                }
                if let emailURL, let email = organization.email {
                    Link(destination: emailURL) { Label(email, systemImage: "envelope") }
                }
                if let websiteURL {
                    Link(destination: websiteURL) {
                        Label(websiteURL.host() ?? "Website", systemImage: "globe")
                    }
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
