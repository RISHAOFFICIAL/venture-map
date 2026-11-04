import SwiftUI

/// A small pill-shaped label used by `EventFilters` to show the current
/// filter value, styled differently depending on whether it's "active."
///
/// `AnyShapeStyle` shows up here because the `foregroundStyle`/`background`
/// modifiers need a single concrete type to return, but this code wants to
/// choose between two *different* styles (`.primary` vs `.white`, or
/// `.regularMaterial` vs a solid color) depending on `isSelected`. Wrapping
/// each option in `AnyShapeStyle(...)` erases their specific types down to
/// one common type so the ternary (`?:`) expression compiles.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var showsChevron = false

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.white))
        .padding(.horizontal, 13)
        .frame(height: 31)
        .background(
            isSelected ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.black.opacity(0.78)),
            in: Capsule()
        )
    }
}
