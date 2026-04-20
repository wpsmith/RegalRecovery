import SwiftUI

struct GlossaryView: View {
    @State private var searchText = ""

    private var filteredGlossary: [GlossaryTerm] {
        let sorted = ContentData.glossary.sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { item in
            item.term.localizedCaseInsensitiveContains(searchText) ||
            item.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredGlossary) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.term)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrPrimary)
                        Text(item.definition)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if item.id != filteredGlossary.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Glossary")
        .searchable(text: $searchText, prompt: "Search terms")
    }
}

#Preview {
    NavigationStack {
        GlossaryView()
    }
}
