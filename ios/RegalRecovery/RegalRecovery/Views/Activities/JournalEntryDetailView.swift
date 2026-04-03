import SwiftUI
import SwiftData
import UIKit

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let entry: RRJournalEntry

    @State private var isEditing = false
    @State private var editText: NSAttributedString = NSAttributedString(string: "")
    @State private var editRange = NSRange(location: 0, length: 0)

    private var wordCount: Int {
        entry.content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private var formattedDate: String {
        entry.date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Prompt card
                if let prompt = entry.prompt {
                    RRCard {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.subheadline)
                            Text(prompt)
                                .font(RRFont.body)
                                .italic()
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .opacity(0.85)
                }

                // Metadata row
                HStack(spacing: 6) {
                    Text(entry.mode.capitalized)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    Text("\u{2022}")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    Text("\(wordCount) words")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                // Content
                if isEditing {
                    VStack(spacing: 12) {
                        FormattingToolbar(
                            attributedText: $editText,
                            selectedRange: $editRange
                        )

                        RRCard {
                            RichTextEditor(attributedText: $editText, selectedRange: $editRange)
                                .frame(minHeight: 300)
                        }

                        RRButton("Save Changes", icon: "checkmark.circle") {
                            entry.setRichContent(from: editText)
                            entry.modifiedAt = Date()
                            isEditing = false
                        }

                        Button("Cancel") {
                            editText = entry.attributedContent ?? NSAttributedString(
                                string: entry.content,
                                attributes: [
                                    .font: UIFont.preferredFont(forTextStyle: .body),
                                    .foregroundColor: UIColor.label,
                                ]
                            )
                            isEditing = false
                        }
                        .foregroundStyle(Color.rrTextSecondary)
                    }
                } else {
                    RRCard {
                        if let attributed = entry.attributedContent {
                            Text(AttributedString(attributed))
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(entry.content)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editText = entry.attributedContent ?? NSAttributedString(
                            string: entry.content,
                            attributes: [
                                .font: UIFont.preferredFont(forTextStyle: .body),
                                .foregroundColor: UIColor.label,
                            ]
                        )
                        editRange = NSRange(location: 0, length: 0)
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)
    let entry = RRJournalEntry(
        userId: UUID(),
        date: Date(),
        mode: "journal",
        content: "Today was a good day. I felt strong in my recovery and connected with my sponsor. We talked about step four and how important it is to be honest with ourselves.",
        prompt: "How did you show up for your recovery?"
    )
    container.mainContext.insert(entry)

    return NavigationStack {
        JournalEntryDetailView(entry: entry)
    }
    .modelContainer(container)
}
