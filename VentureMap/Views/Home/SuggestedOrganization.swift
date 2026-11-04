/// A real organization found by the web search, shown under "Suggested
/// organizations" in `ProfileView`.
///
/// `Decodable` lets `JSONDecoder` build this directly from the server's JSON
/// response — property names must match the JSON keys. Optional properties
/// (`String?`) are fine when a key is missing, which is common because not
/// every website publishes a phone number or email.
struct SuggestedOrganization: Identifiable, Decodable {
    let name: String
    let website: String?
    let phone: String?
    let email: String?
    let summary: String?

    var id: String { website ?? name }
}

extension SuggestedOrganization {
    /// Clearly-labeled sample data. The app shows this whenever the proxy
    /// server can't be reached, so the feature still demonstrates in class
    /// with nobody starting a server — and the section says so outright,
    /// so sample data can never be mistaken for live results.
    ///
    /// Contact details use the reserved `example.org` domain and 555 phone
    /// numbers on purpose: they are guaranteed not to reach any real
    /// person or organization.
    static let demoCategories = ["STEM education", "Digital skills"]

    static let demoOrganizations: [SuggestedOrganization] = [
        SuggestedOrganization(
            name: "Bright Future Code Academy",
            website: "https://example.org/bright-future",
            phone: "(313) 555-0100",
            email: "hello@example.org",
            summary: "Sample data — free weekend coding workshops for Detroit teens."
        ),
        SuggestedOrganization(
            name: "Motor City Digital Literacy Project",
            website: "https://example.org/motor-city-digital",
            phone: "(313) 555-0148",
            email: "learn@example.org",
            summary: "Sample data — computer basics and internet safety classes for adults."
        ),
        SuggestedOrganization(
            name: "Second Shift Tech Mentors",
            website: "https://example.org/second-shift",
            phone: nil,
            email: "mentors@example.org",
            summary: "Sample data — volunteer mentors for career changers entering tech."
        ),
    ]
}
