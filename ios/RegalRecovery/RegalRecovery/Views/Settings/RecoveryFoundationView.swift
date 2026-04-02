import SwiftUI

struct RecoveryFoundationView: View {
    var body: some View {
        List {
            Section {
                Text("One-time setup and periodic review of your core recovery tools.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
            }

            Section {
                NavigationLink {
                    ThreeCirclesView()
                } label: {
                    FoundationItemRow(
                        icon: "circles.hexagongrid.fill",
                        iconColor: .rrDestructive,
                        title: "3 Circles Tool",
                        description: "Map your inner, middle, and outer circle behaviors",
                        lastReviewed: Calendar.current.date(byAdding: .day, value: -62, to: Date()),
                        reviewStatus: .reviewSuggested
                    )
                }

                NavigationLink {
                    placeholderView("Relapse Prevention Plan")
                } label: {
                    FoundationItemRow(
                        icon: "doc.text.magnifyingglass",
                        iconColor: .orange,
                        title: "Relapse Prevention Plan",
                        description: "Build personalized prevention strategies",
                        lastReviewed: Calendar.current.date(byAdding: .day, value: -45, to: Date()),
                        reviewStatus: .upToDate
                    )
                }

                NavigationLink {
                    placeholderView("Vision Statement")
                } label: {
                    FoundationItemRow(
                        icon: "eye.fill",
                        iconColor: .rrSecondary,
                        title: "Vision Statement",
                        description: "Define your recovery vision and values",
                        lastReviewed: nil,
                        reviewStatus: .neverCompleted
                    )
                }

                NavigationLink {
                    SupportNetworkView()
                } label: {
                    FoundationItemRow(
                        icon: "person.3.fill",
                        iconColor: .rrPrimary,
                        title: "Support Network",
                        description: "Configure your recovery team",
                        lastReviewed: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                        reviewStatus: .upToDate
                    )
                }

                NavigationLink {
                    placeholderView("My Recovery Plan")
                } label: {
                    FoundationItemRow(
                        icon: "calendar.badge.checkmark",
                        iconColor: .rrSuccess,
                        title: "My Recovery Plan",
                        description: "Configure daily activities and schedule",
                        lastReviewed: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                        reviewStatus: .upToDate
                    )
                }
            } header: {
                Text("Foundation Tools")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Recovery Foundation")
    }

    private func placeholderView(_ title: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.rrTextSecondary)
            Text(title)
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
            Text("Coming soon")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
    }
}

// MARK: - Review Status

enum FoundationReviewStatus {
    case upToDate
    case reviewSuggested
    case neverCompleted

    var label: String {
        switch self {
        case .upToDate: return "Up to Date"
        case .reviewSuggested: return "Review Suggested"
        case .neverCompleted: return "Never Completed"
        }
    }

    var color: Color {
        switch self {
        case .upToDate: return .rrSuccess
        case .reviewSuggested: return .orange
        case .neverCompleted: return .gray
        }
    }
}

// MARK: - Foundation Item Row

struct FoundationItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let lastReviewed: Date?
    let reviewStatus: FoundationReviewStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text(description)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .lineLimit(2)

                if let lastReviewed {
                    Text("Last reviewed \(lastReviewed, style: .relative) ago")
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            Spacer()

            RRBadge(text: reviewStatus.label, color: reviewStatus.color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RecoveryFoundationView()
    }
}
