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
