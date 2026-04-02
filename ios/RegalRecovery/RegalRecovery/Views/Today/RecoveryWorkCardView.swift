import SwiftUI

/// Card for occasional/reactive activities surfaced on the Today view.
struct RecoveryWorkCardView: View {
    let card: RecoveryWorkCard
    var onStart: () -> Void = {}
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)

                Text("RECOVERY WORK DUE")
                    .font(RRFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .tracking(0.3)
            }

            Text(card.activityName)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            Text(card.triggerReason)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            HStack(spacing: 12) {
                Button(action: onStart) {
                    Text("Start")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.rrPrimary)
                        .clipShape(Capsule())
                }

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(RRFont.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.rrTextSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.rrTextSecondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}
