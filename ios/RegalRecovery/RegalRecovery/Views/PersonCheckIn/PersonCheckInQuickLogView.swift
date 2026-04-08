import SwiftUI

struct PersonCheckInQuickLogView: View {
    @Bindable var viewModel: PersonCheckInViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Quick Log")
                .font(.title2.bold())

            Text("One tap to record a check-in. You can add details later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(PersonCheckInType.allCases, id: \.self) { type in
                    QuickLogButton(type: type) {
                        Task {
                            try? await viewModel.quickLog(type: type)
                            dismiss()
                        }
                    }
                }
            }

            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

struct QuickLogButton: View {
    let type: PersonCheckInType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(colorForType(type))
                    .frame(width: 12, height: 12)

                Text(type.displayName)
                    .font(.headline)

                Spacer()

                Image(systemName: "checkmark.circle")
                    .font(.title3)
            }
            .padding()
            .background(Color("rrSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func colorForType(_ type: PersonCheckInType) -> Color {
        switch type {
        case .spouse: return .pink
        case .sponsor: return .blue
        case .counselorCoach: return .green
        }
    }
}

#Preview {
    PersonCheckInQuickLogView(viewModel: PersonCheckInViewModel())
}
