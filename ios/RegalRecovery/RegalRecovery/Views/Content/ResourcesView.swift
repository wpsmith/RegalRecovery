import SwiftUI

struct ResourcesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                crisisSection
                saInfoSection
                glossarySection
            }
            .padding()
        }
        .background(Color.rrBackground)
    }

    // MARK: - Crisis Hotlines

    private var crisisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Crisis Hotlines")

            VStack(spacing: 12) {
                ForEach(ContentData.crisisResources) { resource in
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(resource.name)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            Text(resource.phone)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.rrPrimary)

                            Text(resource.description)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - What is SA?

    private var saInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "What is SA?")

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.rrPrimary)

                    Text("Sexaholics Anonymous (SA) is a 12-step fellowship for those who want to stop their sexually self-destructive thinking and behavior. SA defines sobriety as no sex with self and no sex with anyone other than spouse.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Glossary

    private var glossarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Glossary")

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
        }
    }
}

#Preview {
    NavigationStack {
        ResourcesView()
    }
}
