import SwiftUI

// MARK: - FASTERResultsView

struct FASTERResultsView: View {
    @Bindable var viewModel: FASTERCheckInViewModel
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        RRSectionHeader(title: "Your Assessment")
                        FASTERThermometerView(
                            assessedStage: viewModel.assessedStage,
                            selectedIndicators: viewModel.selectedIndicators
                        )
                    }
                }

                adaptiveContentCard

                journalSection

                bowtieSuggestion

                VStack(spacing: 12) {
                    RRButton("Save Check-In", icon: "checkmark.circle") {
                        onSave()
                    }

                    Button {
                        viewModel.goBackToIndicators()
                    } label: {
                        Text("Edit Selections")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.rrBackground)
    }

    private var adaptiveContentCard: some View {
        let content = viewModel.assessedStage.adaptiveContent
        return RRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.assessedStage.color)
                        .frame(width: 10, height: 10)
                    Text(content.title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }
                Text(content.body)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var bowtieSuggestion: some View {
        if FeatureFlagStore.shared.isEnabled("activity.bowtie"),
           viewModel.assessedStage.rawValue >= FASTERStage.speedingUp.rawValue {
            RRCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your FASTER Scale shows acceleration. A Bowtie Diagram can help you see what emotional activations are driving it.")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                    NavigationLink {
                        BowtieSessionView()
                    } label: {
                        Label("Start Bowtie Diagram", systemImage: "diamond.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.rrPrimary)
                }
            }
        }
    }

    private var journalSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "Reflect")

                journalField(label: "Ah-ha (insight)", placeholder: "Something I noticed about myself today...", text: $viewModel.journalInsight)

                journalField(label: "Uh-oh (warning sign)", placeholder: "Something I need to watch out for...", text: $viewModel.journalWarning)

                journalField(label: "Anything else?", placeholder: "Optional — whatever is on your mind...", text: $viewModel.journalFreeText)
            }
        }
    }

    private func journalField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
            TextField(placeholder, text: text, axis: .vertical)
                .font(RRFont.body)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.rrBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: text.wrappedValue) { _, newValue in
                    if newValue.count > 1000 { text.wrappedValue = String(newValue.prefix(1000)) }
                }
        }
    }
}

#Preview {
    let vm = FASTERCheckInViewModel()
    vm.selectedIndicators = [
        .forgettingPriorities: ["Isolating from others"],
        .anxiety: ["Sleep problems or insomnia", "Vague worry or dread"],
    ]
    return FASTERResultsView(viewModel: vm, onSave: {})
}
