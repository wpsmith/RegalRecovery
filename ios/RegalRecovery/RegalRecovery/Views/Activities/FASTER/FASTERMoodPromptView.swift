import SwiftUI

struct FASTERMoodPromptView: View {
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("How are you feeling overall?")
                .font(RRFont.title2)
                .foregroundStyle(Color.rrText)

            Text("This helps us understand your current state before assessing specific indicators.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach([
                    (score: 5, label: "Great", emoji: "😊", color: Color.rrSuccess),
                    (score: 4, label: "Good", emoji: "🙂", color: Color.rrPrimary),
                    (score: 3, label: "Okay", emoji: "😐", color: Color.yellow),
                    (score: 2, label: "Struggling", emoji: "😟", color: Color.orange),
                    (score: 1, label: "Very Difficult", emoji: "😰", color: Color.rrDestructive)
                ], id: \.score) { item in
                    Button {
                        onSelect(item.score)
                    } label: {
                        HStack {
                            Text(item.emoji)
                                .font(.title)

                            Text(item.label)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            Spacer()
                        }
                        .padding()
                        .background(item.color.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

#Preview {
    FASTERMoodPromptView { score in
        print("Selected mood: \(score)")
    }
}
