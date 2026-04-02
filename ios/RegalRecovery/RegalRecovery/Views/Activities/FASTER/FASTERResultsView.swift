import SwiftUI

struct FASTERResultsView: View {
    let assessedStage: FASTERStage
    let selectedIndicators: [FASTERStage: Set<String>]
    @Binding var journalInsight: String
    @Binding var journalWarning: String
    @Binding var journalFreeText: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Thermometer
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    RRSectionHeader(title: "Your Assessment")
                    FASTERThermometerView(
                        assessedStage: assessedStage,
                        selectedIndicators: selectedIndicators
                    )
                }
            }

            // Adaptive content
            adaptiveContentCard

            // Journal
            journalSection

            // Save button
            RRButton("Save Check-In", icon: "checkmark.circle") {
                onSave()
            }
        }
    }

    // MARK: - Adaptive Content

    private var adaptiveContentCard: some View {
        let content = assessedStage.adaptiveContent
        return RRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(assessedStage.color)
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

    // MARK: - Journal

    private var journalSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "Reflect")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ah-ha (insight)")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Something I noticed about myself today...", text: $journalInsight, axis: .vertical)
                        .font(RRFont.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: journalInsight) { _, newValue in
                            if newValue.count > 1000 { journalInsight = String(newValue.prefix(1000)) }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Uh-oh (warning sign)")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Something I need to watch out for...", text: $journalWarning, axis: .vertical)
                        .font(RRFont.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: journalWarning) { _, newValue in
                            if newValue.count > 1000 { journalWarning = String(newValue.prefix(1000)) }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Anything else?")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Optional — whatever is on your mind...", text: $journalFreeText, axis: .vertical)
                        .font(RRFont.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: journalFreeText) { _, newValue in
                            if newValue.count > 1000 { journalFreeText = String(newValue.prefix(1000)) }
                        }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        FASTERResultsView(
            assessedStage: .anxiety,
            selectedIndicators: [
                .forgettingPriorities: ["Isolating"],
                .anxiety: ["Sleep problems", "Vague worry or dread"],
            ],
            journalInsight: .constant(""),
            journalWarning: .constant(""),
            journalFreeText: .constant(""),
            onSave: {}
        )
        .padding()
    }
    .background(Color.rrBackground)
}
