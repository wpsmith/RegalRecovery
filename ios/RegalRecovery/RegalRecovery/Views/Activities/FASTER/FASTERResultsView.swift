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
            // Header
            VStack(spacing: 8) {
                Text("Assessment Complete")
                    .font(RRFont.title2)
                    .foregroundStyle(Color.rrText)

                Text("Your FASTER stage: \(assessedStage.name)")
                    .font(RRFont.headline)
                    .foregroundStyle(assessedStage.color)
            }

            // Thermometer
            FASTERThermometerView(currentStage: assessedStage)
                .frame(height: 200)

            // Selected indicators summary
            if !allSelectedIndicators.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Indicators")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    ForEach(allSelectedIndicators, id: \.self) { indicator in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(assessedStage.color)
                            Text(indicator)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                }
                .padding()
                .background(Color.rrCardBackground)
                .cornerRadius(12)
            }

            // Journal prompts
            VStack(alignment: .leading, spacing: 16) {
                Text("Reflection (Optional)")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What insight or realization do you have?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    TextField("", text: $journalInsight, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What warning sign should you watch for?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    TextField("", text: $journalWarning, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional notes")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    TextField("", text: $journalFreeText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .padding()
            .background(Color.rrCardBackground)
            .cornerRadius(12)

            // Save button
            Button(action: onSave) {
                Text("Save Check-in")
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.rrPrimary)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }

    private var allSelectedIndicators: [String] {
        selectedIndicators.values.flatMap { $0 }.sorted()
    }
}

#Preview {
    FASTERResultsView(
        assessedStage: .anxious,
        selectedIndicators: [
            .anxious: ["Worry", "Tension"]
        ],
        journalInsight: .constant(""),
        journalWarning: .constant(""),
        journalFreeText: .constant("")
    ) {
        print("Saved")
    }
}
