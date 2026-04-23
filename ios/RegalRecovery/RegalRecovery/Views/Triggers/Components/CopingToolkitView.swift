import SwiftUI

struct CopingToolkitView: View {
    let category: TriggerCategory?
    let strategies: [CopingToolkitItem]
    let onSelect: (CopingToolkitItem) -> Void

    struct CopingToolkitItem: Identifiable {
        let id: UUID
        let label: String
        let description: String?
        let isSystem: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Coping Tools")
                .font(.headline)
                .foregroundStyle(.rrText)

            // Category match label
            if let category = category {
                Text("Matched to \(category.displayName) triggers")
                    .font(.caption)
                    .foregroundStyle(.rrTextSecondary)
            }

            // Strategies list
            if !strategies.isEmpty {
                ForEach(strategies) { strategy in
                    Button {
                        onSelect(strategy)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(strategy.label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.rrText)

                                if let description = strategy.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.rrTextSecondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.rrTextSecondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.rrSurface)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Quick Access section
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Access")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.rrText)

                HStack(spacing: 16) {
                    QuickAccessButton(
                        icon: "wind",
                        label: "Breathe",
                        action: {}
                    )

                    QuickAccessButton(
                        icon: "hand.raised.fingers.spread",
                        label: "Ground",
                        action: {}
                    )

                    QuickAccessButton(
                        icon: "water.waves",
                        label: "Urge Surf",
                        action: {}
                    )

                    QuickAccessButton(
                        icon: "phone.fill",
                        label: "Call",
                        action: {}
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Quick Access Button

private struct QuickAccessButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.rrPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.rrPrimary.opacity(0.12))
                    )

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.rrText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Coping Toolkit View") {
    ScrollView {
        VStack(spacing: 20) {
            CopingToolkitView(
                category: .emotional,
                strategies: [
                    CopingToolkitView.CopingToolkitItem(
                        id: UUID(),
                        label: "5-4-3-2-1 Grounding",
                        description: "Ground yourself in the present moment",
                        isSystem: true
                    ),
                    CopingToolkitView.CopingToolkitItem(
                        id: UUID(),
                        label: "Box Breathing",
                        description: "4-4-4-4 breath pattern to calm anxiety",
                        isSystem: true
                    ),
                    CopingToolkitView.CopingToolkitItem(
                        id: UUID(),
                        label: "Call my accountability partner",
                        description: nil,
                        isSystem: false
                    )
                ],
                onSelect: { item in
                    print("Selected: \(item.label)")
                }
            )

            CopingToolkitView(
                category: nil,
                strategies: [],
                onSelect: { _ in }
            )
        }
        .padding()
    }
}
