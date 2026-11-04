import SwiftUI
import MapKit

/// An alternate, full-screen address search sheet.
///
/// Note: nothing currently presents this view — `AddEventView` does its own
/// inline address lookup instead (see its `addressSuggestions` state and
/// `updateAddressSuggestions()`). This file is kept as a second worked
/// example of the same idea: using `.task` to kick off an `async` network
/// call (`MKLocalSearch`) as soon as a view appears.
///
/// - **`.task { await searchAddresses() }`**: runs an `async` function tied
///   to this view's lifetime — if the view disappears before the search
///   finishes, SwiftUI automatically cancels the underlying task.
/// - **`async`/`await`**: `searchAddresses()` is marked `async` because it
///   calls `try await MKLocalSearch(request:).start()`, which performs real
///   network I/O. `await` is where this function pauses and lets the rest of
///   the app keep running until the search result comes back.
struct AddressLookupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var results: [AddressLookupResult] = []
    @State private var isSearching = true

    let query: String
    let onSelect: (AddressLookupResult) -> Void

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching Apple Maps…")
                    }
                } else if results.isEmpty {
                    // `ContentUnavailableView` is a standard SwiftUI
                    // "nothing to show" placeholder — a title, an icon, and
                    // optional description, styled consistently with the
                    // rest of the system.
                    ContentUnavailableView(
                        "Address not found",
                        systemImage: "mappin.slash",
                        description: Text("Try a full street address, city, and state.")
                    )
                } else {
                    Section("Choose the correct location") {
                        ForEach(results) { result in
                            Button {
                                onSelect(result)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(result.address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Find address")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Exit address search")
                }
            }
            .task {
                await searchAddresses()
            }
        }
    }

    private func searchAddresses() async {
        // `defer` schedules code to run when the function exits, no matter
        // which `return` path it takes — a tidy way to guarantee
        // `isSearching` always gets turned off, success or failure.
        defer { isSearching = false }

        let request = MKLocalSearch.Request(
            naturalLanguageQuery: query,
            region: CommunityEvent.detroitRegion
        )

        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems.compactMap { item in
                // iOS 26 deprecated `MKMapItem.placemark`. Its replacements
                // are `location` (a CLLocation), `address` (a structured
                // MKAddress), and `addressRepresentations` — so the old
                // `placemark.coordinate` becomes `location?.coordinate` and
                // the old `placemark.title` (formatted address) becomes
                // `address?.fullAddress`. `item.name` is not deprecated.
                // `location` is non-optional in iOS 26 (the compiler enforces
                // this — no `?` needed), while `address` is still optional.
                let coordinate = item.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }

                let addressString = item.address?.fullAddress
                let name = item.name ?? addressString ?? query
                return AddressLookupResult(
                    name: name,
                    address: addressString ?? name,
                    coordinate: coordinate
                )
            }
        } catch {
            results = []
        }
    }
}
