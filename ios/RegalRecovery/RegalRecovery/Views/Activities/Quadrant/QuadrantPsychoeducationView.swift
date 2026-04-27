import SwiftUI

struct QuadrantPsychoeducationView: View {
    let onBegin: () -> Void
    let onSkip: () -> Void

    private let quadrantItems: [(icon: String, color: Color, name: String, description: String)] = [
        ("figure.walk", Color(.systemGreen), String(localized: "Body"), String(localized: "Physical stewardship of your body")),
        ("brain.head.profile", Color(.systemBlue), String(localized: "Mind"), String(localized: "Renewing your mind daily")),
        ("heart.circle", Color(.systemOrange), String(localized: "Heart"), String(localized: "Authentic relational connection")),
        ("sparkles", Color(.systemPurple), String(localized: "Spirit"), String(localized: "Your soul thirsting for God")),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                        .foregroundStyle(Color(.systemPurple))

                    VStack(spacing: 6) {
                        Text(String(localized: "Recovery Quadrant"))
                            .font(RRFont.largeTitle)
                            .foregroundStyle(Color.rrText)
                            .multilineTextAlignment(.center)

                        Text(String(localized: "See the shape of your recovery"))
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 8)

                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "\u{201C}Love the Lord your God with all your heart and with all your soul and with all your mind and with all your strength.\u{201D}"))
                            .font(RRFont.body)
                            .italic()
                            .foregroundStyle(Color.rrText)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(String(localized: "— Mark 12:30"))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(quadrantItems, id: \.name) { item in
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(item.color)
                                .frame(width: 36, height: 36)
                                .background(item.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                Text(item.description)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    Text(String(localized: "About 3 minutes each week"))
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                VStack(spacing: 12) {
                    RRButton(String(localized: "Begin Assessment"), action: onBegin)

                    Button(action: onSkip) {
                        Text(String(localized: "Skip for now"))
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.rrBackground)
        .navigationTitle(String(localized: "Recovery Quadrant"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        QuadrantPsychoeducationView(onBegin: {}, onSkip: {})
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
