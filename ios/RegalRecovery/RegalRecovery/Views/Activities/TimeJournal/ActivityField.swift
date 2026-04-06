import SwiftUI

struct ActivityField: View {
    @Binding var activity: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            ZStack(alignment: .topLeading) {
                if activity.isEmpty && !isFocused {
                    Text("What were you doing?")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                }

                TextEditor(text: $activity)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 56)
                    .padding(4)
            }
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
            )

            HStack {
                Spacer()
                // Mic button placeholder (P1 feature)
                Button {
                    // TODO: Voice-to-text (P1)
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary.opacity(0.4))
                }
                .disabled(true)
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    @Previewable @State var activity = ""
    ActivityField(activity: $activity)
        .padding()
}
