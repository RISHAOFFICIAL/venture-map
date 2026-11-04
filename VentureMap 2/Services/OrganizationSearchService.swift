import Foundation

/// Asks VentureMap's own server for organizations matching a focus area.
///
/// The app never talks to Tavily directly: the Tavily API key lives on the
/// server (see `Server/organizations-proxy.mjs`), because a key bundled into
/// an app can be extracted by anyone who downloads it.
struct OrganizationSearchService {
    /// Where the proxy server runs. `localhost` works in the iOS Simulator
    /// while testing; replace this with your deployed `https://` URL before
    /// shipping.
    static let baseURL = URL(string: "http://localhost:8787")

    enum SearchError: LocalizedError {
        case notConfigured
        case badResponse

        var errorDescription: String? {
            switch self {
            case .notConfigured: "The organization search server isn't configured."
            case .badResponse: "Couldn't reach the organization search server."
            }
        }
    }

    func suggestions(focus: String, location: String) async throws -> [SuggestedOrganization] {
        guard let baseURL = Self.baseURL,
              var components = URLComponents(url: baseURL.appending(path: "organizations"), resolvingAgainstBaseURL: false)
        else { throw SearchError.notConfigured }

        components.queryItems = [
            URLQueryItem(name: "focus", value: focus),
            URLQueryItem(name: "location", value: location)
        ]
        guard let url = components.url else { throw SearchError.notConfigured }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SearchError.badResponse
        }
        return try JSONDecoder().decode([SuggestedOrganization].self, from: data)
    }
}
