import SwiftUI

/// The top bar on the home screen: profile button, search/add buttons, the
/// active-business picker, and the filter row.
///
/// Notice how many `@Binding` properties this view has. It doesn't own any
/// of this state itself — `VentureMapHomeView` does. Passing bindings down
/// like this (rather than copying values) is how a deeply nested child view
/// can still toggle a sheet or change a filter that lives several layers up.
struct HomeHeader: View {
    @Binding var showsSearch: Bool
    @Binding var showsAddEvent: Bool
    @Binding var showsProfile: Bool
    @Binding var timeRange: TimeRange
    @Binding var selectedEventType: EventType?
    let businesses: [Business]
    @Binding var selectedBusinessID: UUID

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    showsProfile = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .frame(width: 38, height: 38)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("Open profile")

                Spacer()

                HStack(spacing: 1) {
                    Button {
                        showsSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .frame(width: 36, height: 38)
                    }
                    Divider()
                        .frame(height: 23)
                    Button {
                        showsAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 38)
                    }
                }
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Search or add event")
            }
            .overlay {
                Menu {
                    ForEach(businesses) { business in
                        Button(business.name) {
                            selectedBusinessID = business.id
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(businesses.first(where: { $0.id == selectedBusinessID })?.name ?? "Business")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(.thinMaterial, in: Capsule())
                }
                .accessibilityLabel("Choose active business")
            }

            EventFilters(
                timeRange: $timeRange,
                selectedEventType: $selectedEventType
            )
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
    }
}
