import SwiftData
import SwiftUI

struct SupportNetworkView: View {
    @Query private var contacts: [RRSupportContact]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var editingContact: RRSupportContact?

    private let dataCategories = ["Sobriety", "Check-ins", "Activities", "Journal", "Financial"]

    var body: some View {
        List {
            if contacts.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text("No support contacts yet")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text("Add sponsors, counselors, and accountability partners to build your recovery network.")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                ForEach(contacts) { contact in
                    Section {
                        Button {
                            editingContact = contact
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(contact.name)
                                        .font(RRFont.title3)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                    RRBadge(text: displayRole(contact.role), color: roleColor(contact.role))
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.rrPrimary)
                                    Text(contact.phone)
                                        .font(RRFont.footnote)
                                        .foregroundStyle(Color.rrText)
                                }

                                Text("Tap to edit")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            .padding(.vertical, 4)
                        }

                        // Data access toggles
                        ForEach(dataCategories, id: \.self) { category in
                            Toggle(isOn: Binding(
                                get: { contact.permissions.contains(category) },
                                set: { enabled in
                                    if enabled {
                                        if !contact.permissions.contains(category) {
                                            contact.permissions.append(category)
                                        }
                                    } else {
                                        contact.permissions.removeAll { $0 == category }
                                    }
                                    contact.modifiedAt = Date()
                                }
                            )) {
                                Text(category)
                                    .font(RRFont.body)
                            }
                            .tint(Color.rrPrimary)
                        }
                    }
                }
                .onDelete(perform: deleteContacts)
            }

            Section {
                Button {
                    showAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.rrPrimary)
                        Text("Add Support Contact")
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showAddSheet) {
            AddContactSheet(onSave: addContact)
        }
        .sheet(item: $editingContact) { contact in
            EditContactSheet(contact: contact, onSave: { updateContact(contact) })
        }
    }

    private func addContact(name: String, role: String, phone: String) {
        let userId = users.first?.id ?? UUID()
        let defaultPermissions: [String]
        switch role {
        case "spouse", "counselor":
            defaultPermissions = dataCategories
        case "sponsor", "accountabilityPartner":
            defaultPermissions = ["Sobriety", "Check-ins", "Activities"]
        default:
            defaultPermissions = ["Sobriety"]
        }
        let contact = RRSupportContact(
            userId: userId,
            name: name,
            role: role,
            phone: phone,
            permissions: defaultPermissions,
            linkedDate: Date()
        )
        modelContext.insert(contact)
    }

    private func updateContact(_ contact: RRSupportContact) {
        contact.modifiedAt = Date()
    }

    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(contacts[index])
        }
    }

    private func displayRole(_ role: String) -> String {
        switch role {
        case "sponsor": return "Sponsor"
        case "counselor": return "Counselor (CSAT)"
        case "spouse": return "Spouse"
        case "accountabilityPartner": return "Accountability Partner"
        default: return role.capitalized
        }
    }

    private func roleColor(_ role: String) -> Color {
        switch role {
        case "sponsor": return .rrPrimary
        case "counselor": return .purple
        case "spouse": return .rrDestructive
        case "accountabilityPartner": return .rrSecondary
        default: return .rrTextSecondary
        }
    }
}

// MARK: - Add Contact Sheet

struct AddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String, String) -> Void

    @State private var name = ""
    @State private var role = "sponsor"
    @State private var phone = ""

    private let roles = [
        ("sponsor", "Sponsor"),
        ("counselor", "Counselor (CSAT)"),
        ("spouse", "Spouse"),
        ("accountabilityPartner", "Accountability Partner"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section {
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.isEmpty else { return }
                        onSave(name, role, phone)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Contact Sheet

struct EditContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    let contact: RRSupportContact
    let onSave: () -> Void

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var role: String = ""

    private let roles = [
        ("sponsor", "Sponsor"),
        ("counselor", "Counselor (CSAT)"),
        ("spouse", "Spouse"),
        ("accountabilityPartner", "Accountability Partner"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section {
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                }
            }
            .onAppear {
                name = contact.name
                phone = contact.phone
                role = contact.role
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        contact.name = name
                        contact.phone = phone
                        contact.role = role
                        contact.modifiedAt = Date()
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SupportNetworkView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
