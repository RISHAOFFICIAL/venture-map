import SwiftUI

/// What `LocationSearchView` shows before the user types anything: a short
/// "recent searches" style list built from the first few events.
struct SearchStartContent: View {
    let events: [CommunityEvent]
    let onSelectEvent: (CommunityEvent) -> Void

    var body: some View {
        List {
            Section("Recent searches") {
                ForEach(events.prefix(3)) { event in
                    Button {
                        onSelectEvent(event)
                    } label: {
                        Label(event.location, systemImage: "clock")
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
