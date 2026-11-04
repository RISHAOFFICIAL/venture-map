import SwiftUI

/// The round, colored pin drawn on the map for each location cluster, and
/// reused again in search results (`SearchResultsContent`).
///
/// Several parameters have **default values** (`clusterCount: Int? = nil`,
/// `isSelected: Bool = false`), so most call sites can just write
/// `EventMarker(count: ..., color: ...)` and skip the rest.
struct EventMarker: View {
    let count: Int
    let color: Color
    var clusterCount: Int? = nil
    var isSelected: Bool = false

    var body: some View {
        Text(count.formatted())
            .font(.caption.weight(.bold))
            .foregroundStyle(.black)
            .frame(width: 35, height: 35)
            .background(color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                // `if let` inside a view builder: the little cluster-count
                // badge only appears when `clusterCount` is non-nil.
                if let clusterCount {
                    Text("\(clusterCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Color.black.opacity(0.78), in: Circle())
                        .offset(x: 6, y: -6)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0)
                    .padding(-4)
            )
            .scaleEffect(isSelected ? 1.12 : 1.0)
            .shadow(color: color.opacity(0.55), radius: 8, y: 3)
            // `.animation(_, value:)` tells SwiftUI "whenever `isSelected`
            // changes, animate any view properties that changed because of
            // it" — here, the scale and stroke width above.
            .animation(.snappy, value: isSelected)
    }
}
