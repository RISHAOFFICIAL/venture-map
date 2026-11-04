import SwiftUI

/// The full-screen search sheet for finding an event by location or
/// neighborhood name, opened from `HomeHeader`'s search button.
///
/// `body` picks between three child views (`SearchStartContent`,
/// `SearchEmptyContent`, `SearchResultsContent`) based on the current
/// `query` and whether it has matches — the same "state decides which view
/// to show" pattern as `ContentView`, just one level deeper in the app.
/// `@FocusState` auto-focuses the text field as soon as the sheet appears.
struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""

    let events: [CommunityEvent]
    let onSelectEvent: (CommunityEvent) -> Void
    let onAddAtPlace: (String) -> Void

    private var matchingEvents: [CommunityEvent] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }
        return events.filter {
            $0.location.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.neighborhood.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(query: $query, isFocused: $isSearchFocused) {
                    dismiss()
                }

                if query.isEmpty {
                    SearchStartContent(events: events, onSelectEvent: onSelectEvent)
                } else if matchingEvents.isEmpty {
                    SearchEmptyContent(query: query) {
                        onAddAtPlace(query)
                    }
                } else {
                    SearchResultsContent(events: matchingEvents, onSelectEvent: onSelectEvent)
                }

                Spacer(minLength: 0)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .task {
                isSearchFocused = true
            }
        }
    }
}
