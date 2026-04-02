import SwiftUI

struct FASTERMoodPromptView: View {
    let onSelect: (Int) -> Void

    private let moods: [(score: Int, icon: String, label: String)] = [
        (1, "face.smiling.inverse", "Great"),
        (2, "face.smiling", "Good"),
        (3, "minus.circle", "Okay"),
        (4, "cloud", "Struggling"),
        (5, "cloud.rain", "Rough"),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("How are you doing right now?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .multilineTextAlignment(.center)

                Text("Just a quick gut check before we begin.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                ForEach(moods, id: \.score) { mood in
                    Button {
                        onSelect(mood.score)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: mood.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(moodColor(mood.score))
                            Text(mood.label)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label), mood \(mood.score) of 5")
                }
            }
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }

    private func moodColor(_ score: Int) -> Color {
        switch score {
        case 1: return Color(red: 0.176, green: 0.416, blue: 0.310)  // restoration green
        case 2: return Color(red: 0.482, green: 0.620, blue: 0.239)  // olive green
        case 3: return Color(red: 0.788, green: 0.635, blue: 0.153)  // amber
        case 4: return Color(red: 0.831, green: 0.502, blue: 0.165)  // orange
        case 5: return Color(red: 0.651, green: 0.239, blue: 0.251)  // crimson
        default: return Color.rrTextSecondary
        }
    }
}

#Preview {
    FASTERMoodPromptView { score in
        print("Selected mood: \(score)")
    }
    .background(Color.rrBackground)
}
