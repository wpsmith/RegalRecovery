import SwiftUI

// MARK: - Card

struct RRCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Badge Pill

struct RRBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(RRFont.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Primary Button

struct RRButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Color.rrPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Section Header

struct RRSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(RRFont.title3)
            .foregroundStyle(Color.rrText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Quick Action Pill

struct RRQuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(RRFont.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(Color.rrPrimary)
            .background(Color.rrPrimary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Activity Row

struct RRActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let trailing: String?

    init(icon: String, iconColor: Color = .rrPrimary, title: String, subtitle: String, trailing: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Text(subtitle)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Milestone Coin

struct RRMilestoneCoin: View {
    let days: Int
    let earned: Bool
    let size: CGFloat

    init(days: Int, earned: Bool = true, size: CGFloat = 48) {
        self.days = days
        self.earned = earned
        self.size = size
    }

    private var coinColor: Color {
        guard earned else { return Color.rrTextSecondary.opacity(0.2) }
        switch days {
        case 0...7:       return Color(red: 0.55, green: 0.47, blue: 0.37) // Bronze
        case 8...30:      return Color(red: 0.55, green: 0.47, blue: 0.37) // Bronze
        case 31...90:     return Color(red: 0.65, green: 0.67, blue: 0.68) // Silver
        case 91...365:    return Color(red: 0.85, green: 0.72, blue: 0.25) // Gold
        case 366...730:   return Color(red: 0.74, green: 0.83, blue: 0.90) // Platinum
        default:          return Color(red: 0.56, green: 0.36, blue: 0.72) // Diamond (2yr+)
        }
    }

    private var label: String {
        if days >= 365 {
            let years = days / 365
            return "\(years)yr"
        }
        return "\(days)"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(coinColor)
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(earned ? coinColor.opacity(0.6) : Color.clear, lineWidth: 2)
                .frame(width: size - 6, height: size - 6)
            Text(label)
                .font(.system(size: size * (days >= 365 ? 0.25 : 0.3), weight: .bold, design: .rounded))
                .foregroundStyle(earned ? .white : Color.rrTextSecondary)
        }
    }
}

// MARK: - Color Dot

struct RRColorDot: View {
    let color: Color
    let size: CGFloat

    init(_ color: Color, size: CGFloat = 10) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

// MARK: - Stat Card

struct RRStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.rrText)
            Text(title)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
