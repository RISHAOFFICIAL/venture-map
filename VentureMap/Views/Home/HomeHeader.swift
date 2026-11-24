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
    // Nil when the account has no business yet (sample data off, user
    // hasn't added one). The + button and the center control both handle
    // that by routing to the profile to add a business first.
    @Binding var selectedBusinessID: UUID?

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
                .tourAnchor(.profileButton)
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
                        if businesses.isEmpty {
                            // No business to attach an event to yet:
                            // send the user to add one first.
                            showsProfile = true
                        } else {
                            showsAddEvent = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 38)
                    }
                    .tourAnchor(.addButton)
                }
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Search or add event")
            }
            .overlay {
                if businesses.isEmpty {
                    // No business yet: the picker has nothing to pick,
                    // so the center control becomes the way to add one.
                    Button {
                        showsProfile = true
                    } label: {
                        HStack(spacing: 5) {
                            Text("Add a business")
                                .lineLimit(1)
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(.thinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Add your first business")
                } else {
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
