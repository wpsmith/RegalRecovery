import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text("Regal Recovery")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                    Text("v1.0.0 (Demo)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section {
                NavigationLink("Glossary of Terms") {
                    GlossaryListView()
                }
            }

            Section {
                Text("Licenses")
                    .foregroundStyle(Color.rrText)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Glossary List

struct GlossaryListView: View {
    var body: some View {
        List {
            ForEach(ContentData.glossary) { term in
                DisclosureGroup {
                    Text(term.definition)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .padding(.vertical, 4)
                } label: {
                    Text(term.term)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
