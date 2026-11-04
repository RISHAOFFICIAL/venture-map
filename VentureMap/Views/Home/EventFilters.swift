import SwiftUI

/// Two dropdown-style filter menus (time range, event type) shown under the
/// home screen's header.
///
/// Both `@Binding` properties mean this view doesn't own the filter state —
/// it just reads and writes whatever `VentureMapHomeView` (via `HomeHeader`)
/// handed it. Selecting a menu item writes straight into the binding, which
/// immediately updates the parent's `@State` and re-filters the map.
struct EventFilters: View {
    @Binding var timeRange: TimeRange
    @Binding var selectedEventType: EventType?

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(TimeRange.allCases) { range in
                    Button(range.title) { timeRange = range }
                }
            } label: {
                FilterChip(title: timeRange.title, isSelected: false, showsChevron: true)
            }

            Menu {
                Button("All event types") { selectedEventType = nil }
                ForEach(EventType.allCases) { type in
                    Button(type.title) { selectedEventType = type }
                }
            } label: {
                FilterChip(
                    title: selectedEventType?.title ?? "Event type",
                    isSelected: selectedEventType != nil,
                    showsChevron: true
                )
            }

            Spacer()
        }
    }
}
