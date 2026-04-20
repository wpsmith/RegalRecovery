import SwiftUI

struct DebugEmotionEmojiView: View {

    // MARK: - All Mappings Data

    private struct EmojiMapping: Identifiable {
        let id = UUID()
        let label: String
        let emoji: SensaEmoji
        let detail: String?

        init(_ label: String, _ emoji: SensaEmoji, detail: String? = nil) {
            self.label = label
            self.emoji = emoji
            self.detail = detail
        }
    }

    private let primaryEmotions: [EmojiMapping] = [
        EmojiMapping("Happy", .beaming),
        EmojiMapping("Sad", .crying),
        EmojiMapping("Angry", .angry),
        EmojiMapping("Fearful", .fearful),
        EmojiMapping("Disgusted", .nauseated),
        EmojiMapping("Surprised", .astonished),
    ]

    private let happySecondaries: [EmojiMapping] = [
        EmojiMapping("Joyful", .partying),
        EmojiMapping("Grateful", .heartEyes),
        EmojiMapping("Content", .smilingEyes),
        EmojiMapping("Peaceful", .relieved),
        EmojiMapping("Hopeful", .slightlySmiling),
        EmojiMapping("Proud", .starStruck),
    ]

    private let sadSecondaries: [EmojiMapping] = [
        EmojiMapping("Lonely", .pensive),
        EmojiMapping("Grieving", .loudlyCrying),
        EmojiMapping("Disappointed", .disappointed),
        EmojiMapping("Hopeless", .downcastSweat),
        EmojiMapping("Ashamed", .frowning),
        EmojiMapping("Empty", .expressionless),
    ]

    private let angrySecondaries: [EmojiMapping] = [
        EmojiMapping("Frustrated", .steamFromNose),
        EmojiMapping("Resentful", .pouting),
        EmojiMapping("Irritated", .angry),
        EmojiMapping("Bitter", .confounded),
        EmojiMapping("Jealous", .slightlyFrowning),
        EmojiMapping("Betrayed", .pouting),
    ]

    private let fearfulSecondaries: [EmojiMapping] = [
        EmojiMapping("Anxious", .anxious),
        EmojiMapping("Insecure", .worried),
        EmojiMapping("Overwhelmed", .downcastSweat),
        EmojiMapping("Vulnerable", .slightlyFrowning),
        EmojiMapping("Panicked", .fearful),
        EmojiMapping("Worried", .worried),
    ]

    private let disgustedSecondaries: [EmojiMapping] = [
        EmojiMapping("Contemptuous", .confounded),
        EmojiMapping("Repulsed", .nauseated),
        EmojiMapping("Self-loathing", .frowning),
        EmojiMapping("Judgmental", .neutral),
    ]

    private let surprisedSecondaries: [EmojiMapping] = [
        EmojiMapping("Shocked", .explodingHead),
        EmojiMapping("Confused", .thinking),
        EmojiMapping("Amazed", .astonished),
        EmojiMapping("Startled", .hushed),
    ]

    private let moodScore10: [EmojiMapping] = [
        EmojiMapping("1-2", .loudlyCrying, detail: "Lowest"),
        EmojiMapping("3-4", .worried, detail: "Low"),
        EmojiMapping("5-6", .neutral, detail: "Moderate"),
        EmojiMapping("7-8", .smilingEyes, detail: "Good"),
        EmojiMapping("9-10", .beaming, detail: "Great"),
    ]

    private let moodPrimary: [EmojiMapping] = [
        EmojiMapping("Love", .heartEyes),
        EmojiMapping("Joy", .beaming),
        EmojiMapping("Surprise", .astonished),
        EmojiMapping("Anger", .angry),
        EmojiMapping("Sadness", .crying),
        EmojiMapping("Fear", .fearful),
    ]

    private let fasterMood: [EmojiMapping] = [
        EmojiMapping("1 (Great)", .beaming),
        EmojiMapping("2", .slightlySmiling),
        EmojiMapping("3", .neutral),
        EmojiMapping("4", .worried),
        EmojiMapping("5 (Rough)", .loudlyCrying),
    ]

    private let emotionCategories: [EmojiMapping] = [
        EmojiMapping("Happy", .beaming),
        EmojiMapping("Sad", .crying),
        EmojiMapping("Angry", .angry),
        EmojiMapping("Fearful", .fearful),
        EmojiMapping("Shame", .frowning),
        EmojiMapping("The Three I's", .downcastSweat),
        EmojiMapping("Numb", .expressionless),
        EmojiMapping("Surprise", .astonished),
        EmojiMapping("Connected", .hugging),
    ]

    private let gratitudeMood: [EmojiMapping] = [
        EmojiMapping("1 (Low)", .loudlyCrying),
        EmojiMapping("2", .slightlyFrowning),
        EmojiMapping("3", .neutral),
        EmojiMapping("4", .smilingEyes),
        EmojiMapping("5 (Great)", .starStruck),
    ]

    private var allMappings: [EmojiMapping] {
        primaryEmotions
            + happySecondaries + sadSecondaries + angrySecondaries
            + fearfulSecondaries + disgustedSecondaries + surprisedSecondaries
            + moodScore10 + moodPrimary + fasterMood
            + emotionCategories + gratitudeMood
    }

    private var uniqueEmojis: Set<SensaEmoji> {
        Set(allMappings.map(\.emoji))
    }

    private var unmappedEmojis: [SensaEmoji] {
        let used = uniqueEmojis
        return SensaEmoji.allCases.filter { !used.contains($0) }
    }

    // MARK: - Body

    var body: some View {
        List {
            summarySection
            primaryEmotionsSection
            secondaryEmotionsSection
            moodScore10Section
            moodPrimarySection
            fasterMoodSection
            emotionCategorySection
            gratitudeMoodSection
            fullCatalogSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Emotions & Emojis")
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section {
            HStack {
                Text("Total Mappings")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(allMappings.count)")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
            }
            HStack {
                Text("Unique Emojis Used")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(uniqueEmojis.count) of \(SensaEmoji.allCases.count)")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
            }
            HStack {
                Text("Unmapped Emojis")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(unmappedEmojis.count)")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        } header: {
            Text("Summary")
        }
    }

    // MARK: - Primary Emotions

    private var primaryEmotionsSection: some View {
        Section {
            ForEach(primaryEmotions) { mapping in
                emojiRow(mapping.label, emoji: mapping.emoji)
            }
        } header: {
            Text("Primary Emotions (Emotional Journal)")
        } footer: {
            Text("SensaEmoji.forPrimaryEmotion(_:)")
                .font(RRFont.caption2)
        }
    }

    // MARK: - Secondary Emotions

    private var secondaryEmotionsSection: some View {
        Section {
            secondaryGroup("Happy", mappings: happySecondaries)
            secondaryGroup("Sad", mappings: sadSecondaries)
            secondaryGroup("Angry", mappings: angrySecondaries)
            secondaryGroup("Fearful", mappings: fearfulSecondaries)
            secondaryGroup("Disgusted", mappings: disgustedSecondaries)
            secondaryGroup("Surprised", mappings: surprisedSecondaries)
        } header: {
            Text("Secondary Emotions (Emotional Journal)")
        } footer: {
            Text("SensaEmoji.forSecondaryEmotion(_:)")
                .font(RRFont.caption2)
        }
    }

    @ViewBuilder
    private func secondaryGroup(_ title: String, mappings: [EmojiMapping]) -> some View {
        Text(title)
            .font(RRFont.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.rrTextSecondary)
            .listRowBackground(Color.rrBackground)
        ForEach(mappings) { mapping in
            emojiRow(mapping.label, emoji: mapping.emoji)
        }
    }

    // MARK: - Mood Score 1-10

    private var moodScore10Section: some View {
        Section {
            ForEach(moodScore10) { mapping in
                emojiRow(mapping.label, emoji: mapping.emoji, detail: mapping.detail)
            }
        } header: {
            Text("Mood Score 1-10 (Mood Rating)")
        } footer: {
            Text("SensaEmoji.forMoodScore10(_:)")
                .font(RRFont.caption2)
        }
    }

    // MARK: - Mood Primary

    private var moodPrimarySection: some View {
        Section {
            ForEach(moodPrimary) { mapping in
                emojiRow(mapping.label, emoji: mapping.emoji)
            }
        } header: {
            Text("Mood Primary (Layered Check-In)")
        } footer: {
            Text("SensaEmoji.forMoodPrimary(_:)")
                .font(RRFont.caption2)
        }
    }

    // MARK: - FASTER Mood

    private var fasterMoodSection: some View {
        Section {
            ForEach(fasterMood) { mapping in
                emojiRow(mapping.label, emoji: mapping.emoji)
            }
        } header: {
            Text("FASTER Mood 1-5")
        } footer: {
            Text("SensaEmoji.forFASTERMood(_:)")
                .font(RRFont.caption2)
        }
    }

    // MARK: - Emotion Categories (Time Journal)

    private var emotionCategorySection: some View {
        Section {
            ForEach(emotionCategories) { mapping in
                emojiRow(mapping.label, emoji: mapping.emoji)
            }
        } header: {
            Text("Emotion Categories (Time Journal)")
        } footer: {
            Text("SensaEmoji.forEmotionCategory(_:)")
                .font(RRFont.caption2)
        }
    }

    // MARK: - Gratitude Mood

    private var gratitudeMoodSection: some View {
        Section {
            ForEach(gratitudeMood) { mapping in
                emojiRow(mapping.label, emoji: mapping.emoji)
            }
        } header: {
            Text("Gratitude Mood 1-5")
        } footer: {
            Text("SensaEmoji.forGratitudeMood(_:)")
                .font(RRFont.caption2)
        }
    }

    // MARK: - Full Catalog

    private var fullCatalogSection: some View {
        Section {
            ForEach(SensaEmoji.allCases, id: \.self) { emoji in
                HStack(spacing: 12) {
                    emoji.image(size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(describing: emoji))
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                        Text(emoji.assetName)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    Spacer()
                    if !uniqueEmojis.contains(emoji) {
                        Text("UNMAPPED")
                            .font(RRFont.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.rrTextSecondary.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }
        } header: {
            Text("Full Catalog (\(SensaEmoji.allCases.count) emojis)")
        } footer: {
            Text("SensaEmoji.allCases — emojis not used in any mapping are tagged UNMAPPED.")
                .font(RRFont.caption2)
        }
    }

    // MARK: - Row Helper

    private func emojiRow(_ label: String, emoji: SensaEmoji, detail: String? = nil) -> some View {
        HStack(spacing: 12) {
            emoji.image(size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Text(detail ?? emoji.assetName)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DebugEmotionEmojiView()
    }
}
