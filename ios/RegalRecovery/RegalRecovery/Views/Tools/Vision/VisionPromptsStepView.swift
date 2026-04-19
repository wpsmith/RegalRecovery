import SwiftUI

struct VisionPromptsStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    let promptIndex: Int

    private var prompt: VisionPrompt? {
        VisionPrompt(rawValue: promptIndex)
    }

    private var responseBinding: Binding<String> {
        Binding(
            get: { viewModel.promptResponses[promptIndex] ?? "" },
            set: { viewModel.promptResponses[promptIndex] = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let prompt {
                    Text(prompt.text)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .trailing, spacing: 8) {
                    TextEditor(text: responseBinding)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onChange(of: responseBinding.wrappedValue) { _, newValue in
                            if newValue.count > VisionPrompt.maxLength {
                                viewModel.promptResponses[promptIndex] = String(newValue.prefix(VisionPrompt.maxLength))
                            }
                        }

                    Text("\(responseBinding.wrappedValue.count)/\(VisionPrompt.maxLength)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text("Take your time. There are no wrong answers.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .italic()
            }
            .padding()
        }
    }
}

#Preview {
    VisionPromptsStepView(viewModel: VisionWizardViewModel(), promptIndex: 0)
}
