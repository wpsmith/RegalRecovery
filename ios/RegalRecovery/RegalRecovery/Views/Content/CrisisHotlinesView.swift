import SwiftUI

struct CrisisHotlinesView: View {
    private var groupedResources: [(category: String, resources: [CrisisResource])] {
        let order = ["Crisis", "Addiction", "Sexual Addiction", "Abuse", "Family Support", "Mental Health", "Faith-Based", "Veterans", "Youth", "Co-occurring"]
        var groups: [String: [CrisisResource]] = [:]
        for resource in ContentData.crisisResources {
            groups[resource.category, default: []].append(resource)
        }
        return order.compactMap { cat in
            guard let items = groups[cat], !items.isEmpty else { return nil }
            return (category: cat, resources: items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(groupedResources, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.category)
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            ForEach(Array(group.resources.enumerated()), id: \.element.id) { index, resource in
                                hotlineRow(resource)

                                if index < group.resources.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Crisis Hotlines")
    }

    private func hotlineRow(_ resource: CrisisResource) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(resource.name)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                Spacer()
                if resource.is24x7 {
                    Text("24/7")
                        .font(RRFont.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.rrSuccess)
                        .clipShape(Capsule())
                }
            }

            Text(resource.description)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            HStack(spacing: 12) {
                if !resource.phone.isEmpty {
                    Button {
                        if let url = URL(string: "tel:\(resource.phone.replacingOccurrences(of: "-", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text(resource.phone)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .foregroundStyle(Color.rrPrimary)
                    }
                }

                if let textOption = resource.textOption {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                        Text(textOption)
                            .font(RRFont.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.rrSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        CrisisHotlinesView()
    }
}
