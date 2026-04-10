import SwiftUI

struct DayRatingView: View {
    @Binding var rating: Int // 1-5, 0 = unselected
    var onContinue: () -> Void

    private let options: [(value: Int, label: String)] = [
        (1, "Really tough"),
        (2, "Difficult"),
        (3, "Okay"),
        (4, "Good"),
        (5, "Wonderful"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How did today feel?")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(options, id: \.value) { option in
                    ratingButton(option)
                }
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rrPrimary)
                    .clipShape(Capsule())
            }
            .disabled(rating == 0)
            .opacity(rating == 0 ? 0.4 : 1.0)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }

    @ViewBuilder
    private func ratingButton(_ option: (value: Int, label: String)) -> some View {
        let isSelected = rating == option.value

        Button {
            rating = option.value
        } label: {
            Text(option.label)
                .font(RRFont.body)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color.rrText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 4)
                .background(isSelected ? Color.rrPrimary : Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.clear : Color.rrTextSecondary.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var rating = 0
    DayRatingView(rating: $rating, onContinue: {})
}
