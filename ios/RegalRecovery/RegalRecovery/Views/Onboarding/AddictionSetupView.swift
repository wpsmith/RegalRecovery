import SwiftUI

struct AddictionSetupView: View {
    @Binding var selectedAddictions: [(name: String, date: Date)]
    let onNext: () -> Void

    private let addictionTypes = [
        "Sex Addiction (SA)", "Pornography", "Substance Use",
        "Alcohol", "Drugs", "Gambling", "Other"
    ]

    private var selectedNames: Set<String> {
        Set(selectedAddictions.map(\.name))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Recovery")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What are you recovering from?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(addictionTypes, id: \.self) { type in
                            Button {
                                toggleAddiction(type)
                            } label: {
                                Text(type)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedNames.contains(type) ? .white : Color.rrText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedNames.contains(type) ? Color.rrPrimary : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedNames.contains(type) ? Color.clear : Color.rrTextSecondary.opacity(0.4),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }

                if !selectedAddictions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sobriety Dates")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        ForEach(Array(selectedAddictions.enumerated()), id: \.element.name) { index, entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.name)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    if index == 0 {
                                        Text("Primary")
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrPrimary)
                                    }
                                    Spacer()
                                }
                                DatePicker(
                                    "Sobriety date",
                                    selection: Binding(
                                        get: { selectedAddictions[index].date },
                                        set: { selectedAddictions[index].date = $0 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            .padding(12)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                Spacer(minLength: 24)

                RRButton("Continue", icon: "arrow.right") {
                    onNext()
                }
                .disabled(selectedAddictions.isEmpty)
                .opacity(selectedAddictions.isEmpty ? 0.5 : 1)
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }

    private func toggleAddiction(_ name: String) {
        if let idx = selectedAddictions.firstIndex(where: { $0.name == name }) {
            selectedAddictions.remove(at: idx)
        } else {
            selectedAddictions.append((name: name, date: Date()))
        }
    }
}

#Preview {
    AddictionSetupView(
        selectedAddictions: .constant([
            (name: "Sex Addiction (SA)", date: Date()),
            (name: "Pornography", date: Date())
        ]),
        onNext: {}
    )
}
