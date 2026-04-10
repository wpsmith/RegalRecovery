import SwiftUI

struct SessionCompleteView: View {
    let sessionType: AffirmationSessionType // .morning or .evening
    let totalSessions: Int?
    let milestone: AffirmationMilestone?
    var onDone: () -> Void

    @State private var showCheckmark = false

    private var compassionateMessage: String {
        switch sessionType {
        case .morning:
            return "You showed up today. That matters."
        case .evening:
            return "A moment of reflection is a gift to yourself."
        case .sos:
            return "You reached out. That takes courage."
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Checkmark circle
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.rrSuccess)
                .scaleEffect(showCheckmark ? 1.0 : 0.5)
                .opacity(showCheckmark ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)

            // Compassionate message
            Text(compassionateMessage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Cumulative session count (never streaks)
            if let totalSessions {
                Text("\(totalSessions) session\(totalSessions == 1 ? "" : "s") completed \u{2014} that is \(totalSessions) moment\(totalSessions == 1 ? "" : "s") you chose recovery.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Milestone display
            if let milestone, let message = milestone.message {
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.rrPrimary)

                    Text(message)
                        .font(RRFont.callout)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("That is real work.")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.rrPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 32)
            }

            Spacer()

            // Done button
            Button(action: onDone) {
                Text("Done")
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.rrPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
        .onAppear {
            showCheckmark = true
        }
    }
}

#Preview("Morning - With Milestone") {
    SessionCompleteView(
        sessionType: .morning,
        totalSessions: 10,
        milestone: AffirmationMilestone(
            type: "session-count",
            threshold: 10,
            message: "10 sessions completed",
            achievedAt: Date()
        ),
        onDone: {}
    )
}

#Preview("Evening - No Milestone") {
    SessionCompleteView(
        sessionType: .evening,
        totalSessions: 5,
        milestone: nil,
        onDone: {}
    )
}
