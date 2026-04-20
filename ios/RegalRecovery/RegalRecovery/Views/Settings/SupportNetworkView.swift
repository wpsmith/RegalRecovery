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

                                if let addiction = contact.addiction, !addiction.isEmpty {
                                    Text(addiction)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
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
        .navigationTitle("Support Network")
        .sheet(isPresented: $showAddSheet) {
            AddContactSheet(onSave: addContact)
        }
        .sheet(item: $editingContact) { contact in
            EditContactSheet(contact: contact, onSave: { updateContact(contact) })
        }
    }

    private func addContact(name: String, role: String, phone: String, addiction: String?) {
        let userId = users.first?.id ?? UUID()
        let contact = RRSupportContact(
            userId: userId,
            name: name,
            role: role,
            phone: phone,
            addiction: addiction,
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
        case "counselor": return "Counselor"
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
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    let onSave: (String, String, String, String?) -> Void

    @State private var name = ""
    @State private var role = "sponsor"
    @State private var phone = ""
    @State private var selectedAddiction: String?
    @State private var showContactPicker = false

    private let roles = [
        ("sponsor", "Sponsor"),
        ("counselor", "Counselor"),
        ("spouse", "Spouse"),
        ("accountabilityPartner", "Accountability Partner"),
    ]

    private var showAddictionPicker: Bool {
        role == "sponsor" || role == "counselor"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    Button {
                        showContactPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundStyle(Color.rrPrimary)
                            Text("Import from Contacts")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }

                Section {
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }

                    if showAddictionPicker && !addictions.isEmpty {
                        Picker("Addiction (optional)", selection: $selectedAddiction) {
                            Text("None").tag(String?.none)
                            ForEach(addictions) { addiction in
                                Text(addiction.name).tag(Optional(addiction.name))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.isEmpty else { return }
                        let addiction = showAddictionPicker ? selectedAddiction : nil
                        onSave(name, role, phone, addiction)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker(
                    onSelect: { contactName, contactPhone in
                        name = contactName
                        phone = contactPhone
                        showContactPicker = false
                    },
                    onCancel: {
                        showContactPicker = false
                    }
                )
            }
        }
    }
}

// MARK: - Edit Contact Sheet

struct EditContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    let contact: RRSupportContact
    let onSave: () -> Void

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var role: String = ""
    @State private var selectedAddiction: String?

    private let roles = [
        ("sponsor", "Sponsor"),
        ("counselor", "Counselor"),
        ("spouse", "Spouse"),
        ("accountabilityPartner", "Accountability Partner"),
    ]

    private var showAddictionPicker: Bool {
        role == "sponsor" || role == "counselor"
    }

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

                    if showAddictionPicker && !addictions.isEmpty {
                        Picker("Addiction (optional)", selection: $selectedAddiction) {
                            Text("None").tag(String?.none)
                            ForEach(addictions) { addiction in
                                Text(addiction.name).tag(Optional(addiction.name))
                            }
                        }
                    }
                }
            }
            .onAppear {
                name = contact.name
                phone = contact.phone
                role = contact.role
                selectedAddiction = contact.addiction
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
                        contact.addiction = showAddictionPicker ? selectedAddiction : nil
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
