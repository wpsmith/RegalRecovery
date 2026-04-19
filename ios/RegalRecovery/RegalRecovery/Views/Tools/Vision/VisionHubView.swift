import SwiftUI
import SwiftData

struct VisionHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<RRVisionStatement> { $0.isCurrent == true })
    private var currentVisions: [RRVisionStatement]

    @State private var showWizard = false
    @State private var showDeleteConfirmation = false
    @State private var isExpanded = false

    private var currentVision: RRVisionStatement? {
        currentVisions.first
    }

    var body: some View {
        ScrollView {
            if let vision = currentVision {
                populatedState(vision)
            } else {
                emptyState
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Vision Statement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if currentVision != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            VisionHistoryView()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(Color.rrPrimary)
                        }

                        Button {
                            showWizard = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showWizard) {
            if let vision = currentVision {
                VisionWizardView(editing: vision)
            } else {
                VisionWizardView()
            }
        }
        .alert("Delete Vision Statement?", isPresented: $showDeleteConfirmation) {
            Button("Delete All Versions", role: .destructive) {
                deleteAllVisions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove your vision statement and all previous versions.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrPrimary)

            Text("Your recovery needs a destination")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            Text("A vision statement answers:\nWhat kind of man am I becoming?")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)

            RRButton("Create My Vision", icon: "plus") {
                showWizard = true
            }
            .padding(.horizontal, 32)

            Text("Your vision is not a promise you are making.\nIt is a direction you are facing.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    // MARK: - Populated State

    private func populatedState(_ vision: RRVisionStatement) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("I am becoming...")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    Text(vision.identityStatement)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !vision.visionBody.isEmpty {
                        Divider()
                        if isExpanded || vision.visionBody.count <= 200 {
                            Text(vision.visionBody)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(vision.visionBody)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(4)

                            Button {
                                withAnimation { isExpanded = true }
                            } label: {
                                Text("Read more")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                        }
                    }

                    if !vision.coreValues.isEmpty {
                        Divider()
                        FlowLayout(spacing: 8) {
                            ForEach(Array(vision.coreValues.enumerated()), id: \.element) { index, value in
                                Text(value)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(index < 5 ? .white : Color.rrPrimary)
                                    .background(index < 5 ? Color.rrPrimary : Color.rrPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if let ref = vision.scriptureReference {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ref)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            if let text = vision.scriptureText {
                                Text(text)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                        }
                    }
                }
            }

            let daysAgo = Calendar.current.dateComponents([.day], from: vision.modifiedAt, to: Date()).day ?? 0
            let updateText = daysAgo == 0 ? "Updated today" : "Last updated \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago"
            Text(updateText)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Delete Vision Statement")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrDestructive)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private func deleteAllVisions() {
        let descriptor = FetchDescriptor<RRVisionStatement>()
        if let allVisions = try? modelContext.fetch(descriptor) {
            for vision in allVisions {
                modelContext.delete(vision)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VisionHubView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
