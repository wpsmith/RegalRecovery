import SwiftUI

// MARK: - Sponsor Review View

/// Sponsor sharing and comment management view. Allows generating share links,
/// viewing existing shares, reading sponsor comments, and marking comments as read.
struct SponsorReviewView: View {

    // MARK: - Properties

    let apiClient: ThreeCirclesAPIClient
    let viewModel: CircleSetDetailViewModel

    // MARK: - State

    @State private var selectedExpiry: ShareExpiry = .sevenDays
    @State private var selectedPermission: SharePermission = .comment
    @State private var isGenerating = false
    @State private var copiedToClipboard = false
    @State private var showGenerateSheet = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current share section
                if let shareData = viewModel.shareData {
                    activeShareCard(shareData)
                } else {
                    noShareCard
                }

                Divider()
                    .padding(.vertical, 4)

                // Comments section
                commentsSection
            }
            .padding()
        }
        .background(Color.rrBackground)
        .sheet(isPresented: $showGenerateSheet) {
            generateShareSheet
        }
        .task {
            await viewModel.loadComments()
        }
    }

    // MARK: - Share Sections

    private var noShareCard: some View {
        RRCard {
            VStack(spacing: 16) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.rrPrimary.opacity(0.6))

                Text("Share with Your Sponsor")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text("Generate a secure link so your sponsor, therapist, or accountability partner can review your circles and leave comments. Sharing is an important part of recovery.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)

                RRButton("Generate Share Link", icon: "link") {
                    showGenerateSheet = true
                }
            }
        }
    }

    private func activeShareCard(_ shareData: ShareLinkData) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.rrPrimary)
                    Text("Active Share")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    RRBadge(text: "Active", color: .rrSuccess)
                }

                // Share code
                HStack {
                    Text("Code")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                    Spacer()
                    Text(shareData.shareCode)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.rrText)
                        .fontWeight(.semibold)
                }

                // Expiry
                if let expiresAt = shareData.expiresAt {
                    HStack {
                        Text("Expires")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text(expiresAt.formatted(date: .abbreviated, time: .shortened))
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }

                // Permissions
                if let permissions = shareData.permissions {
                    HStack {
                        Text("Permissions")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text(permissions.joined(separator: ", ").capitalized)
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }

                Divider()

                // Action buttons
                HStack(spacing: 12) {
                    // Copy link button
                    Button {
                        copyToClipboard(shareData.shareLink)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                            Text(copiedToClipboard ? "Copied" : "Copy Link")
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(copiedToClipboard ? Color.rrSuccess : Color.rrPrimary)
                        .background(
                            (copiedToClipboard ? Color.rrSuccess : Color.rrPrimary).opacity(0.1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel(copiedToClipboard ? "Link copied" : "Copy share link")

                    // Copy code button
                    Button {
                        copyToClipboard(shareData.shareCode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "number")
                                .font(.caption)
                            Text("Copy Code")
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color.rrPrimary)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel("Copy share code")
                }

                // Generate new link
                Button {
                    showGenerateSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                        Text("Generate New Link")
                            .font(RRFont.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sponsor Comments")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                if viewModel.unreadCommentCount > 0 {
                    Text("\(viewModel.unreadCommentCount)")
                        .font(RRFont.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.rrDestructive)
                        .clipShape(Circle())
                        .accessibilityLabel("\(viewModel.unreadCommentCount) unread comments")
                }

                Spacer()

                if viewModel.unreadCommentCount > 0 {
                    Button {
                        viewModel.markCommentsAsRead()
                    } label: {
                        Text("Mark All Read")
                            .font(RRFont.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }

            if viewModel.comments.isEmpty {
                noCommentsView
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRow(comment: comment, viewModel: viewModel)
                }
            }
        }
    }

    private var noCommentsView: some View {
        RRCard {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.rrTextSecondary.opacity(0.5))

                Text("No comments yet")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                Text("Once you share your circles, your sponsor can leave comments and suggestions here.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Generate Share Sheet

    private var generateShareSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Expires After", selection: $selectedExpiry) {
                        Text("24 Hours").tag(ShareExpiry.twentyFourHours)
                        Text("7 Days").tag(ShareExpiry.sevenDays)
                        Text("Never").tag(ShareExpiry.never)
                    }
                } header: {
                    Text("Expiration")
                } footer: {
                    Text("Choose how long the share link remains active.")
                }

                Section {
                    Picker("Permission", selection: $selectedPermission) {
                        Text("View Only").tag(SharePermission.view)
                        Text("View & Comment").tag(SharePermission.comment)
                    }
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("\"View & Comment\" allows your sponsor to leave feedback on specific items.")
                }

                Section {
                    Button {
                        Task { await generateLink() }
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Generate Link", systemImage: "link.badge.plus")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isGenerating)
                }
            }
            .navigationTitle("Share Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showGenerateSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func generateLink() async {
        isGenerating = true
        defer { isGenerating = false }

        await viewModel.generateShareLink(
            expiresIn: selectedExpiry,
            permissions: [selectedPermission]
        )

        if viewModel.actionError == nil {
            showGenerateSheet = false
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        withAnimation {
            copiedToClipboard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }
}

// MARK: - Comment Row

/// Individual sponsor comment with item reference, text, and action buttons.
private struct CommentRow: View {

    let comment: SponsorComment
    let viewModel: CircleSetDetailViewModel

    @State private var showActions = false

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                // Header: commenter + timestamp
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.rrPrimary)
                        Text(comment.commenterName ?? "Sponsor")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)
                    }

                    Spacer()

                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                // Referenced item
                if let item = viewModel.findItem(by: comment.itemId) {
                    HStack(spacing: 6) {
                        RRColorDot(colorForCircle(item.circle), size: 6)
                        Text("Re: \(item.behaviorName)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    }
                }

                // Comment text
                Text(comment.text)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                // Action buttons
                HStack(spacing: 16) {
                    Spacer()
                    commentActionButton(
                        icon: "checkmark.circle",
                        label: "Accept",
                        color: .rrSuccess
                    )
                    commentActionButton(
                        icon: "xmark.circle",
                        label: "Decline",
                        color: .rrTextSecondary
                    )
                    commentActionButton(
                        icon: "pencil.circle",
                        label: "Modify",
                        color: .rrPrimary
                    )
                }
            }
        }
    }

    private func commentActionButton(icon: String, label: String, color: Color) -> some View {
        Button {
            // Action handling — accept/reject/modify flows
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(RRFont.caption2)
            }
            .foregroundStyle(color)
            .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("\(label) this comment")
    }

    private func colorForCircle(_ type: CircleType) -> Color {
        switch type {
        case .inner: return .rrDestructive
        case .middle: return .orange
        case .outer: return .rrSuccess
        }
    }
}

// MARK: - Preview

#Preview {
    Text("SponsorReviewView requires dependencies")
}
