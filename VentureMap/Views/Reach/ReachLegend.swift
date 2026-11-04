import SwiftUI

/// One "dot + label" legend entry (e.g. a red dot next to "10+ reached"),
/// used inside `ReachCard`. About as small as a reusable view gets.
struct ReachLegend: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1))
            Text(title)
                .font(.caption2)
        }
    }
}
