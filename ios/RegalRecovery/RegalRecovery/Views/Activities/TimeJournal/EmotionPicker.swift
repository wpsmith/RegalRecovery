import SwiftUI

struct EmotionPicker: View {
    @Binding var selectedEmotions: [EmotionEntry]
    @State private var expandedCategory: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emotions")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            // Category pills - horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EmotionCatalog.categories, id: \.name) { category in
                        categoryPill(category)
                    }
                }
                .padding(.horizontal, 1)
            }

            // Expanded category emotions grid
            if let categoryName = expandedCategory,
               let category = EmotionCatalog.categories.first(where: { $0.name == categoryName }) {
                emotionGrid(for: category)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Selected emotions with intensity sliders
            if !selectedEmotions.isEmpty {
                selectedEmotionsSection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: expandedCategory)
    }

    @ViewBuilder
    private func categoryPill(_ category: EmotionCatalog.Category) -> some View {
        let isExpanded = expandedCategory == category.name
        let hasSelection = selectedEmotions.contains { $0.category == category.name }

        Button {
            withAnimation {
                expandedCategory = isExpanded ? nil : category.name
            }
        } label: {
            HStack(spacing: 4) {
                Text(category.name)
                    .font(RRFont.caption)
                    .fontWeight(isExpanded || hasSelection ? .semibold : .regular)
                if hasSelection {
                    let count = selectedEmotions.filter { $0.category == category.name }.count
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(category.color)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isExpanded ? .white : Color.rrText)
            .background(isExpanded ? category.color : category.color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                category.name == "The Three I's" && !isExpanded
                    ? Capsule().strokeBorder(Color.rrDestructive, lineWidth: 1.5)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func emotionGrid(for category: EmotionCatalog.Category) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(category.emotions, id: \.self) { emotion in
                let isSelected = selectedEmotions.contains { $0.name == emotion }
                Button {
                    toggleEmotion(emotion, category: category.name)
                } label: {
                    Text(emotion)
                        .font(RRFont.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? .white : Color.rrText)
                        .background(isSelected ? category.color : category.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var selectedEmotionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected")
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)

            ForEach($selectedEmotions) { $emotion in
                HStack(spacing: 8) {
                    let category = EmotionCatalog.categories.first { $0.name == emotion.category }
                    Circle()
                        .fill(category?.color ?? .gray)
                        .frame(width: 8, height: 8)
                    Text(emotion.name)
                        .font(RRFont.caption)
                        .fontWeight(.medium)
                        .frame(width: 90, alignment: .leading)

                    Slider(value: intensityBinding(for: $emotion), in: 1...10, step: 1)
                        .tint(category?.color ?? .gray)

                    Text("\(emotion.intensity)")
                        .font(RRFont.caption2)
                        .fontWeight(.semibold)
                        .frame(width: 20)

                    Button {
                        selectedEmotions.removeAll { $0.id == emotion.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleEmotion(_ emotion: String, category: String) {
        if let index = selectedEmotions.firstIndex(where: { $0.name == emotion }) {
            selectedEmotions.remove(at: index)
        } else {
            selectedEmotions.append(EmotionEntry(name: emotion, category: category, intensity: 5))
        }
    }

    private func intensityBinding(for emotion: Binding<EmotionEntry>) -> Binding<Double> {
        Binding<Double>(
            get: { Double(emotion.wrappedValue.intensity) },
            set: { emotion.wrappedValue.intensity = Int($0) }
        )
    }
}

#Preview {
    @Previewable @State var emotions: [EmotionEntry] = []
    ScrollView {
        EmotionPicker(selectedEmotions: $emotions)
            .padding()
    }
}
