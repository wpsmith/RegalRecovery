import SwiftUI

struct LocationField: View {
    @Binding var locationLabel: String
    @State private var isCustom = false
    @FocusState private var isTextFieldFocused: Bool

    private let quickOptions = ["@home", "@work", "@church", "@gym", "@meeting"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickOptions, id: \.self) { option in
                        chipButton(label: option, isSelected: locationLabel == option) {
                            isCustom = false
                            isTextFieldFocused = false
                            locationLabel = option
                        }
                    }

                    chipButton(label: "Other...", isSelected: isCustom) {
                        isCustom = true
                        locationLabel = ""
                        isTextFieldFocused = true
                    }
                }
                .padding(.horizontal, 1)
            }

            if isCustom {
                TextField("Enter location", text: $locationLabel)
                    .textFieldStyle(.roundedBorder)
                    .font(RRFont.body)
                    .focused($isTextFieldFocused)
            }
        }
    }

    @ViewBuilder
    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .white : Color.rrText)
                .background(isSelected ? Color.rrPrimary : Color.rrSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var location = ""
    LocationField(locationLabel: $location)
        .padding()
}
