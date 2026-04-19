import SwiftUI

struct VisionReviewStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Review Your Vision")
                    .font(RRFont.largeTitle)
                    .foregroundStyle(Color.rrText)

                Text("Your vision is not a promise you are making. It is a direction you are facing.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .italic()

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("I am becoming...")
                    Text(viewModel.identityStatement)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("My Vision")
                    if viewModel.visionBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        TextField("Write your full vision here (optional)...", text: $viewModel.visionBody, axis: .vertical)
                            .lineLimit(4...10)
                            .padding(12)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: viewModel.visionBody) { _, newValue in
                                if newValue.count > VisionLimits.visionBodyMaxLength {
                                    viewModel.visionBody = String(newValue.prefix(VisionLimits.visionBodyMaxLength))
                                }
                            }

                        Text("\(viewModel.visionBody.count)/\(VisionLimits.visionBodyMaxLength)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text(viewModel.visionBody)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                let nonEmpty = viewModel.promptResponses.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !nonEmpty.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Reflections")
                        ForEach(nonEmpty.sorted(by: { $0.key < $1.key }), id: \.key) { index, response in
                            if let prompt = VisionPrompt(rawValue: index) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prompt.text)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                    Text(response)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.rrSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }

                if !viewModel.selectedValues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Core Values")
                        FlowLayout(spacing: 8) {
                            ForEach(Array(viewModel.selectedValues.enumerated()), id: \.element) { index, value in
                                HStack(spacing: 4) {
                                    if index < 5 {
                                        Text("#\(index + 1)")
                                            .font(RRFont.caption2)
                                            .fontWeight(.bold)
                                    }
                                    Text(value)
                                        .font(RRFont.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .background(Color.rrPrimary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                if let ref = viewModel.scriptureReference {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Scripture")
                        Text(ref)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        if let text = viewModel.scriptureText {
                            Text(text)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                                .italic()
                        }
                    }
                }

                RRButton("Save Vision", icon: "checkmark.circle") {
                    onSave()
                }
                .disabled(!viewModel.canProceed)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(RRFont.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.rrTextSecondary)
            .tracking(1)
    }
}

#Preview {
    VisionReviewStepView(viewModel: VisionWizardViewModel()) {}
}
