import SwiftUI

struct VisionIdentityStepView: View {
    @Bindable var viewModel: VisionWizardViewModel

    private let sampleStatements = [
        "...a man of integrity who keeps his word.",
        "...a present and loving father.",
        "...free from shame and walking in truth.",
        "...a faithful husband who honors his vows.",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("I am becoming...")
                    .font(RRFont.largeTitle)
                    .foregroundStyle(Color.rrPrimary)

                Text("Complete this sentence with the identity you are growing into.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                VStack(alignment: .trailing, spacing: 8) {
                    TextField("...a man who...", text: $viewModel.identityStatement, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onChange(of: viewModel.identityStatement) { _, newValue in
                            if newValue.count > VisionLimits.identityMaxLength {
                                viewModel.identityStatement = String(newValue.prefix(VisionLimits.identityMaxLength))
                            }
                        }

                    Text("\(viewModel.identityStatement.count)/\(VisionLimits.identityMaxLength)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("For inspiration:")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    FlowLayout(spacing: 8) {
                        ForEach(sampleStatements, id: \.self) { sample in
                            Button {
                                if viewModel.identityStatement.isEmpty {
                                    viewModel.identityStatement = sample
                                }
                            } label: {
                                Text(sample)
                                    .font(RRFont.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(Color.rrPrimary)
                                    .background(Color.rrPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    VisionIdentityStepView(viewModel: VisionWizardViewModel())
}
