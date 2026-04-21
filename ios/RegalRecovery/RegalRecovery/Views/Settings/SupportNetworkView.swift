import Contacts
import ContactsUI
import SwiftData
import SwiftUI

// MARK: - Contact Picker (UIViewControllerRepresentable)

// Note: Ensure NSContactsUsageDescription is set in Info.plist.
// CNContactPickerViewController runs in a separate process and does not require
// an explicit CNContactStore.requestAccess call.

struct ContactPicker: UIViewControllerRepresentable {
    let onSelect: (String, String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_: CNContactPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker
        init(_ parent: ContactPicker) { self.parent = parent }

        func contactPicker(_: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            parent.onSelect(name, phone)
        }

        func contactPickerDidCancel(_: CNContactPickerViewController) {
            parent.onCancel()
        }
    }
}

struct SupportNetworkView: View {
    @Query private var contacts: [RRSupportContact]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var showContactSourcePicker = false
    @State private var showContactPicker = false
    @State private var prefillName = ""
    @State private var prefillPhone = ""
    @State private var editingContact: RRSupportContact?

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
                    }
                }
                .onDelete(perform: deleteContacts)
            }

            Section {
                Button {
                    prefillName = ""
                    prefillPhone = ""
                    showContactSourcePicker = true
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
        .navigationTitle("Support Network")
        .confirmationDialog("Add Contact", isPresented: $showContactSourcePicker) {
            Button("From Contacts") { showContactPicker = true }
            Button("Enter Manually") { showAddSheet = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPicker(
                onSelect: { name, phone in
                    prefillName = name
                    prefillPhone = phone
                    showContactPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddSheet = true
                    }
                },
                onCancel: {
                    showContactPicker = false
                }
            )
        }
        .sheet(isPresented: $showAddSheet) {
            AddContactSheet(prefillName: prefillName, prefillPhone: prefillPhone, onSave: addContact)
        }
        .sheet(item: $editingContact) { contact in
            EditContactSheet(contact: contact, onSave: { updateContact(contact) })
        }
    }

    private func addContact(name: String, role: String, phone: String) {
        let userId = users.first?.id ?? UUID()
        let contact = RRSupportContact(
            userId: userId,
            name: name,
            role: role,
            phone: phone,
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
        case "sponsor": return String(localized: "Sponsor")
        case "counselor": return String(localized: "Counselor (CSAT)")
        case "spouse": return String(localized: "Spouse")
        case "accountabilityPartner": return String(localized: "Accountability Partner")
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

    @State private var name: String
    @State private var role = "sponsor"
    @State private var phone: String

    init(prefillName: String = "", prefillPhone: String = "", onSave: @escaping (String, String, String) -> Void) {
        _name = State(initialValue: prefillName)
        _phone = State(initialValue: prefillPhone)
        self.onSave = onSave
    }

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
