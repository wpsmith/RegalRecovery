import SwiftUI
import SwiftData

struct LBIDimensionEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Bindable var viewModel: LBISetupViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.progressLabel)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text("Life Balance Index")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    ProgressView(value: viewModel.progressFraction)
                        .progressViewStyle(.linear)
                        .tint(Color.rrPrimary)
                }
                .padding(.horizontal)

                if let content = viewModel.currentDimensionContent {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(content.title)
                            .font(RRFont.largeTitle)
                            .foregroundStyle(Color.rrText)

                        Text(content.description)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(content.promptQuestion)
                            .font(RRFont.body)
                            .italic()
                            .foregroundStyle(Color.rrText)
                            .fixedSize(horizontal: false, vertical: true)

                        RRCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Examples:")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)

                                Text("Tap any example to add it as your indicator")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(content.exampleBehaviors, id: \.self) { behavior in
                                        let alreadyAdded = viewModel.currentIndicatorTexts.contains(behavior)
                                        Button {
                                            if !alreadyAdded {
                                                viewModel.addExampleAsIndicator(behavior)
                                            }
                                        } label: {
                                            HStack(alignment: .center, spacing: 8) {
                                                Image(systemName: alreadyAdded ? "checkmark.circle.fill" : "plus.circle")
                                                    .font(RRFont.callout)
                                                    .foregroundStyle(alreadyAdded ? Color.rrSuccess : Color.rrPrimary)
                                                Text(behavior)
                                                    .font(RRFont.callout)
                                                    .foregroundStyle(alreadyAdded ? Color.rrTextSecondary : Color.rrText)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Spacer()
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 4)
                                            .contentShape(Rectangle())
                                        }
                                        .disabled(alreadyAdded)
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        if let note = content.positiveNote {
                            RRCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(RRFont.title3)
                                        .foregroundStyle(Color.rrPrimary)
                                    Text(note)
                                        .font(RRFont.callout)
                                        .foregroundStyle(Color.rrText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 8)
                        }

                        VStack(spacing: 16) {
                            Text("Your indicators:")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            ForEach(viewModel.currentIndicatorTexts.indices, id: \.self) { index in
                                if index < viewModel.currentIndicatorTexts.count {
                                    HStack(spacing: 12) {
                                        TextField("Indicator \(index + 1)", text: bindingForIndex(index))
                                            .font(RRFont.body)
                                            .padding(12)
                                            .background(Color.rrSurface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(Color.rrTextSecondary.opacity(0.2), lineWidth: 1)
                                            )

                                        if viewModel.currentIndicatorTexts.count > 1 {
                                            Button {
                                                withAnimation {
                                                    viewModel.removeIndicatorField(at: index)
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(Color.red.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                            }

                            if viewModel.currentIndicatorTexts.count < 5 {
                                Button {
                                    withAnimation {
                                        viewModel.addIndicatorField()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add another indicator")
                                    }
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.top, 8)

                        HStack(spacing: 16) {
                            Button {
                                viewModel.skipDimension()
                                autosaveDraft()
                            } label: {
                                Text("Skip")
                                    .font(RRFont.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.rrSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            Button {
                                viewModel.saveCurrentDimensionIndicators()
                                viewModel.nextDimension()
                                autosaveDraft()
                            } label: {
                                Text(viewModel.isLastDimension ? "Continue" : "Next")
                                    .font(RRFont.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.rrPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(.top, 24)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            viewModel.loadCurrentDimensionIndicators()
        }
    }

    private func bindingForIndex(_ index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < viewModel.currentIndicatorTexts.count else { return "" }
                return viewModel.currentIndicatorTexts[index]
            },
            set: { newValue in
                guard index < viewModel.currentIndicatorTexts.count else { return }
                if newValue.count <= 200 {
                    viewModel.currentIndicatorTexts[index] = newValue
                }
            }
        )
    }

    private func autosaveDraft() {
        let userId = users.first?.id ?? UUID()
        viewModel.saveDraftProgress(context: modelContext, userId: userId)
    }
}
