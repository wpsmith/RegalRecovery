import SwiftUI

struct PersonCheckInCreateView: View {
    @Bindable var viewModel: PersonCheckInViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                // Check-in Type
                Section("Check-in Type") {
                    Picker("Type", selection: $viewModel.selectedCheckInType) {
                        ForEach(PersonCheckInType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Method
                Section("How did you connect?") {
                    Picker("Method", selection: $viewModel.selectedMethod) {
                        ForEach(PersonCheckInMethod.allCases, id: \.self) { method in
                            Label(method.displayName, systemImage: method.iconName).tag(method)
                        }
                    }
                }

                // Contact Name
                Section("Contact") {
                    TextField("Contact Name", text: $viewModel.contactName)
                        .textContentType(.name)
                }

                // Duration
                Section("Duration (minutes)") {
                    HStack {
                        ForEach([5, 10, 15, 30, 45, 60], id: \.self) { mins in
                            Button("\(mins)") {
                                viewModel.durationMinutes = mins
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.durationMinutes == mins ? Color("rrPrimary") : .secondary)
                        }
                    }
                }

                // Quality Rating
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How meaningful was this check-in?")
                            .font(.subheadline)
                        HStack {
                            ForEach(1...5, id: \.self) { rating in
                                Button {
                                    viewModel.qualityRating = rating
                                } label: {
                                    Image(systemName: rating <= viewModel.qualityRating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(rating <= viewModel.qualityRating ? .yellow : .gray.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(viewModel.qualityRatingLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Quality")
                } footer: {
                    Text("This isn't about grading the conversation. It's about noticing whether you're bringing your real self.")
                        .font(.caption2)
                }

                // Topics
                Section("Topics Discussed") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                        ForEach(PersonCheckInTopic.allCases, id: \.self) { topic in
                            TopicChip(
                                topic: topic,
                                isSelected: viewModel.selectedTopics.contains(topic)
                            ) {
                                if viewModel.selectedTopics.contains(topic) {
                                    viewModel.selectedTopics.remove(topic)
                                } else {
                                    viewModel.selectedTopics.insert(topic)
                                }
                            }
                        }
                    }
                }

                // Notes
                Section {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("\(viewModel.notes.count)/1000")
                        .font(.caption2)
                }

                // Follow-up Items
                Section {
                    ForEach(viewModel.followUpItems.indices, id: \.self) { index in
                        HStack {
                            Text(viewModel.followUpItems[index])
                            Spacer()
                            Button {
                                viewModel.removeFollowUpItem(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.followUpItems.count < 3 {
                        HStack {
                            TextField("Add follow-up item", text: $viewModel.currentFollowUpText)
                            Button {
                                viewModel.addFollowUpItem()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(viewModel.currentFollowUpText.isEmpty)
                        }
                    }
                } header: {
                    Text("Follow-up Items")
                } footer: {
                    Text("Up to 3 action items from this check-in")
                        .font(.caption2)
                }
            }
            .navigationTitle("Log Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSubmitting = true
                            defer { isSubmitting = false }
                            try? await viewModel.submit()
                            dismiss()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
}

struct TopicChip: View {
    let topic: PersonCheckInTopic
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(topic.displayName)
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color("rrPrimary").opacity(0.15) : Color("rrSurface"))
                .foregroundStyle(isSelected ? Color("rrPrimary") : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color("rrPrimary") : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PersonCheckInCreateView(viewModel: PersonCheckInViewModel())
}
