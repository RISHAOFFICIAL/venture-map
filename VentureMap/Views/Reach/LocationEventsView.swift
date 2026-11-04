import SwiftUI

/// A list of every event logged at one location, with its own local
/// `selectedEvent` state to drive an edit sheet — separate from whatever
/// selection state exists on the screen that pushed this view.
struct LocationEventsView: View {
    let location: String
    let events: [CommunityEvent]
    let onUpdateEvent: (CommunityEvent) -> Void
    @State private var selectedEvent: CommunityEvent?

    var body: some View {
        List {
            Section("\(events.count) event\(events.count == 1 ? "" : "s")") {
                ForEach(events.sorted { $0.date > $1.date }) { event in
                    EventHistoryRow(event: event) {
                        selectedEvent = event
                    }
                }
            }
        }
        .navigationTitle(location)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, onSave: onUpdateEvent)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}
