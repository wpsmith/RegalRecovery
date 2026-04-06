import SwiftUI

struct PeopleField: View {
    @Binding var people: [PersonEntry]
    @State private var isAdding = false
    @State private var newName = ""
    @State private var newGender: String?
    @FocusState private var isNameFocused: Bool

    private let genderOptions = ["Male", "Female"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("People")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            // Existing people pills
            FlowLayout(spacing: 8) {
                ForEach(people) { person in
                    personPill(person)
                }
            }

            if isAdding {
                addPersonForm
            } else {
                Button {
                    isAdding = true
                    isNameFocused = true
                } label: {
                    Label("Add person", systemImage: "plus.circle")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func personPill(_ person: PersonEntry) -> some View {
        HStack(spacing: 4) {
            if let gender = person.gender {
                Image(systemName: gender == "Male" ? "figure.stand" : "figure.stand.dress")
                    .font(.caption2)
            }
            Text(person.name)
                .font(RRFont.caption)
                .fontWeight(.medium)
            Button {
                people.removeAll { $0.id == person.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.rrPrimary.opacity(0.12))
        .clipShape(Capsule())
    }

    private var addPersonForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .font(RRFont.body)
                    .focused($isNameFocused)

                Picker("Gender", selection: $newGender) {
                    Text("--").tag(nil as String?)
                    ForEach(genderOptions, id: \.self) { gender in
                        Text(gender).tag(gender as String?)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            HStack(spacing: 12) {
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    people.append(PersonEntry(name: trimmed, gender: newGender))
                    newName = ""
                    newGender = nil
                }
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrPrimary)
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    isAdding = false
                    newName = ""
                    newGender = nil
                }
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    @Previewable @State var people: [PersonEntry] = [
        PersonEntry(name: "John", gender: "Male"),
        PersonEntry(name: "Sarah", gender: "Female"),
    ]
    PeopleField(people: $people)
        .padding()
}
