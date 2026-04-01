import SwiftUI

struct GlossaryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(ContentData.glossary) { item in
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

                    if item.id != ContentData.glossary.last?.id {
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
    }
}

#Preview {
    NavigationStack {
        GlossaryView()
    }
}
