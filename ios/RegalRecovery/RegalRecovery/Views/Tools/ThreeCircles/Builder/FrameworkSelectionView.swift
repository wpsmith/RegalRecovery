import SwiftUI

/// Framework preference selection screen.
///
/// Allows the user to optionally choose a recovery framework, which
/// affects terminology and template suggestions throughout the app.
struct FrameworkSelectionView: View {
    let viewModel: ThreeCirclesBuilderViewModel

    /// Framework display data with descriptions.
    private let frameworkInfo: [(framework: FrameworkPreference, description: String)] = [
        (.SA, "Sexaholics Anonymous"),
        (.SLAA, "Sex and Love Addicts Anonymous"),
        (.AA, "Alcoholics Anonymous"),
        (.NA, "Narcotics Anonymous"),
        (.SMART, "SMART Recovery (secular, science-based)"),
        (.OA, "Overeaters Anonymous"),
        (.GA, "Gamblers Anonymous"),
        (.DA, "Debtors Anonymous"),
        (.CoDA, "Co-Dependents Anonymous"),
        (.ITAA, "Internet and Technology Addicts Anonymous"),
        (.WA, "Workaholics Anonymous"),
        (.other, "Another framework not listed here"),
        (.none, "No framework preference"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("Recovery Framework")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("If you follow a specific recovery program, selecting it helps us use familiar language and suggest relevant items for your circles.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                // Framework options
                VStack(spacing: 8) {
                    ForEach(frameworkInfo, id: \.framework) { info in
                        frameworkRow(info.framework, description: info.description)
                    }
                }
                .padding(.horizontal)

                // Explanation note
                RRCard {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.rrPrimary)

                        Text("This only affects suggestions and terminology. You can change it later, and it does not limit what you can add to your circles.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Framework Row

    private func frameworkRow(_ framework: FrameworkPreference, description: String) -> some View {
        let isSelected = viewModel.selectedFramework == framework

        return Button {
            if isSelected {
                viewModel.selectedFramework = nil
            } else {
                viewModel.selectedFramework = framework
            }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.rrPrimary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(framework.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Text(description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.rrPrimary.opacity(0.06) : Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.rrPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(framework.displayName), \(description)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FrameworkSelectionView(viewModel: ThreeCirclesBuilderViewModel())
    }
}
