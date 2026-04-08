import SwiftUI

/// Full-screen prayer reading view with calming design.
/// After exiting, prompts user to log the session (PR-AC1.12 expand flow).
struct PrayerFullScreenView: View {
    let prayer: LibraryPrayerDTO
    let onDismiss: () -> Void
    let onLogSession: () -> Void

    @State private var showLogPrompt = false

    var body: some View {
        ZStack {
            // Calming gradient background.
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.15, blue: 0.25), Color(red: 0.08, green: 0.10, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title.
                    Text(prayer.title)
                        .font(.system(.title2, design: .serif))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    // Scripture connection.
                    if let scripture = prayer.scriptureConnection {
                        Text(scripture)
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Prayer body in serif font, large type.
                    Text(prayer.body)
                        .font(.system(.title3, design: .serif))
                        .foregroundColor(.white.opacity(0.95))
                        .lineSpacing(8)

                    // Source attribution.
                    if let source = prayer.sourceAttribution {
                        Text("-- \(source)")
                            .font(.system(.footnote, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 12)
                    }
                }
                .padding(32)
            }

            // Close button.
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showLogPrompt = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .alert("Log Prayer Session?", isPresented: $showLogPrompt) {
            Button("Log Session") {
                onLogSession()
                onDismiss()
            }
            Button("Skip", role: .cancel) {
                onDismiss()
            }
        } message: {
            Text("Would you like to log this as a prayer session?")
        }
    }
}

// MARK: - Prayer History Row

/// A row view for displaying a prayer session in history.
struct PrayerHistoryRow: View {
    let session: PrayerSessionDTO

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: session.timestamp) else { return session.timestamp }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    private var typeIcon: String {
        switch session.prayerType {
        case "personal": return "person.fill"
        case "guided": return "book.fill"
        case "group": return "person.3.fill"
        case "scriptureBased": return "text.book.closed.fill"
        case "intercessory": return "hands.sparkles.fill"
        case "listening": return "ear.fill"
        default: return "hands.clap.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.prayerType.capitalized)
                        .font(.headline)

                    if let duration = session.durationMinutes {
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let linkedTitle = session.linkedPrayerTitle {
                    Text(linkedTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Mood indicator.
            if let before = session.moodBefore, let after = session.moodAfter {
                HStack(spacing: 2) {
                    Text("\(before)")
                        .foregroundColor(.secondary)
                    Image(systemName: after > before ? "arrow.up" : after < before ? "arrow.down" : "arrow.right")
                        .font(.caption)
                        .foregroundColor(after > before ? .green : after < before ? .red : .secondary)
                    Text("\(after)")
                        .foregroundColor(after > before ? .green : .secondary)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
