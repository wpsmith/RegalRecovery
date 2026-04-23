import SwiftUI

struct TriggerChipView: View {
    let label: String
    let category: TriggerCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : category.color)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .rrText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : category.color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
                            .opacity(isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(category.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Unselected Chips") {
    VStack(spacing: 12) {
        TriggerChipView(
            label: "Stress",
            category: .emotional,
            isSelected: false,
            onTap: {}
        )

        TriggerChipView(
            label: "Home alone",
            category: .environmental,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}

#Preview("Selected Chips") {
    VStack(spacing: 12) {
        TriggerChipView(
            label: "Stress",
            category: .emotional,
            isSelected: true,
            onTap: {}
        )

        TriggerChipView(
            label: "Fantasy",
            category: .cognitive,
            isSelected: true,
            onTap: {}
        )
    }
    .padding()
}

#Preview("All States") {
    VStack(spacing: 12) {
        TriggerChipView(
            label: "Stress",
            category: .emotional,
            isSelected: false,
            onTap: {}
        )

        TriggerChipView(
            label: "Stress",
            category: .emotional,
            isSelected: true,
            onTap: {}
        )

        TriggerChipView(
            label: "Home alone",
            category: .environmental,
            isSelected: false,
            onTap: {}
        )

        TriggerChipView(
            label: "Fantasy",
            category: .cognitive,
            isSelected: true,
            onTap: {}
        )
    }
    .padding()
}
