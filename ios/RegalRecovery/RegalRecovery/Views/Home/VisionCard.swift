import SwiftUI
import SwiftData

struct VisionCard: View {
    let identityStatement: String
    let scriptureReference: String?

    var body: some View {
        NavigationLink {
            VisionHubView()
        } label: {
            RRCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                        Text("My Vision")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Text("I am becoming \(identityStatement)")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if let ref = scriptureReference {
                        Text(ref)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.rrPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VisionCard(
        identityStatement: "a man of integrity who keeps his word",
        scriptureReference: "Proverbs 29:18"
    )
    .padding()
}
