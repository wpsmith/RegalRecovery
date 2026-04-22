import SwiftUI
import SwiftData

struct GratitudeDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: RRGratitudeEntry

    @State private var viewModel = GratitudeHistoryViewModel()
    @State private var showShareOptions = false
    @State private var showCopiedConfirmation = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showItemCopiedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                headerCard

                // Photo
                if let photoPath = entry.photoLocalPath {
                    photoSection(photoPath)
                }

                // Items
                itemsCard

                // Actions
                actionsRow
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("Gratitude Entry")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Share Entry", isPresented: $showShareOptions, titleVisibility: .visible) {
            Button("Share as Text") {
                let text = GratitudeSharingService.shareText(for: entry)
                UIPasteboard.general.string = text
                showCopiedConfirmation = true
            }
            Button("Share as Image") {
                let text = GratitudeSharingService.shareText(for: entry)
                shareImage = GratitudeSharingService.styledImage(text: text, date: entry.date, scripture: nil)
                showShareSheet = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay {
            if showCopiedConfirmation || showItemCopiedConfirmation {
                copiedToast
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showCopiedConfirmation = false; showItemCopiedConfirmation = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.date.formatted(date: .complete, time: .shortened))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                if let mood = entry.moodScore {
                    HStack(spacing: 6) {
                        Text("Mood:")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Image(systemName: MoodIcon.symbolName(for: mood))
                            .font(.title2)
                            .foregroundStyle(MoodIcon.color(for: mood))
                        Text("\(MoodIcon.label(for: mood)) (\(mood)/5)")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }

                if let prompt = entry.promptUsed {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow.opacity(0.8))
                        Text(prompt)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Photo

    @ViewBuilder
    private func photoSection(_ path: String) -> some View {
        RRCard {
            // Attempt to load local image
            if let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 240)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                // Placeholder
                HStack {
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundStyle(Color.rrTextSecondary.opacity(0.5))
                    Text("Photo attached")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Items

    private var itemsCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "Items")

                ForEach(Array(entry.items.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)
                                .frame(width: 24, alignment: .trailing)

                            Text(item.text)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleItemFavorite(itemId: item.id, in: entry)
                                }
                            } label: {
                                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                    .font(.body)
                                    .foregroundStyle(item.isFavorite ? Color.rrDestructive : Color.rrTextSecondary)
                            }
                            .buttonStyle(.plain)
                        }

                        if let category = item.category {
                            HStack {
                                Spacer()
                                    .frame(width: 32)
                                RRBadge(text: item.displayCategoryName ?? category.rawValue, color: category.color)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            let text = GratitudeSharingService.shareText(for: item)
                            UIPasteboard.general.string = text
                            showItemCopiedConfirmation = true
                        } label: {
                            Label("Share Item", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleItemFavorite(itemId: item.id, in: entry)
                            }
                        } label: {
                            Label(
                                item.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: item.isFavorite ? "heart.slash" : "heart"
                            )
                        }
                    }

                    if index < entry.items.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsRow: some View {
        HStack(spacing: 12) {
            if entry.isEditable {
                Button {
                    // Edit action - will be wired later
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit")
                            .fontWeight(.medium)
                    }
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.rrPrimary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Button {
                showShareOptions = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                        .fontWeight(.medium)
                }
                .font(RRFont.body)
                .foregroundStyle(Color.rrPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.rrPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        VStack {
            Spacer()
            Text("Copied to clipboard")
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.rrText.opacity(0.85))
                .clipShape(Capsule())
                .padding(.bottom, 32)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: showCopiedConfirmation || showItemCopiedConfirmation)
    }

}

// MARK: - Preview

#Preview {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)

    let entry = RRGratitudeEntry(
        userId: UUID(),
        date: Date(),
        items: [
            GratitudeItem(text: "Morning quiet time with God", category: .faithGod, isFavorite: true, sortOrder: 0),
            GratitudeItem(text: "Rachel's patience and love", category: .relationships, sortOrder: 1),
            GratitudeItem(text: "Progress in Step 8 work", category: .recovery, sortOrder: 2),
        ],
        moodScore: 4,
        photoLocalPath: nil,
        promptUsed: "What are three things you are grateful for today?"
    )

    container.mainContext.insert(entry)

    return NavigationStack {
        GratitudeDetailView(entry: entry)
    }
    .modelContainer(container)
}

// MARK: - Share Sheet (UIActivityViewController wrapper)

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
