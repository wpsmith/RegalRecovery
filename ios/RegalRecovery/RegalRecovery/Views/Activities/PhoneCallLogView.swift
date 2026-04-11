import SwiftUI
import SwiftData
import ContactsUI

// MARK: - Contact Picker (UIViewControllerRepresentable)

struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedName: String
    @Binding var selectedPhone: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            parent.selectedName = name.isEmpty ? "Unknown" : name

            if let phone = contact.phoneNumbers.first?.value.stringValue {
                parent.selectedPhone = phone
            }
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Phone Call Log View

struct PhoneCallLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var entries: [RRPhoneCallLog]
    @Query(sort: \RRSupportContact.name) private var contacts: [RRSupportContact]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var contactName = ""
    @State private var contactRole = ""
    @State private var contactPhone = ""
    @State private var durationMinutes: Double = 15
    @State private var notes = ""
    @State private var showContactPicker = false
    @State private var showManualEntry = false

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    private func contactRoleLabel(_ role: String) -> String {
        switch role {
        case "sponsor": return "Sponsor"
        case "counselor": return "Counselor (CSAT)"
        case "spouse": return "Spouse"
        case "accountabilityPartner": return "AP"
        case "contact": return "Contact"
        default: return role.capitalized
        }
    }

    private func contactRoleIcon(_ role: String) -> String {
        switch role {
        case "sponsor": return "person.fill.checkmark"
        case "counselor": return "stethoscope"
        case "spouse": return "heart.fill"
        case "accountabilityPartner": return "person.2.fill"
        default: return "person.fill"
        }
    }

    private var hasSelectedContact: Bool {
        !contactName.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RRSectionHeader(title: "Log a Call")

                        // Selected contact display
                        if hasSelectedContact {
                            selectedContactView
                        }

                        // Support contact chips
                        if !contacts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Support Contacts")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)

                                FlowLayout(spacing: 8) {
                                    ForEach(contacts) { contact in
                                        supportContactChip(contact)
                                    }
                                }
                            }
                        }

                        // Device contacts button
                        Button {
                            showContactPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.body)
                                Text("Choose from Contacts")
                                    .font(RRFont.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(Color.rrPrimary)
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .frame(minHeight: 44)

                        // Manual entry fallback
                        if showManualEntry {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contact Name")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)
                                TextField("Enter name", text: $contactName)
                                    .font(RRFont.body)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: contactName) {
                                        if contactRole.isEmpty {
                                            contactRole = "contact"
                                        }
                                    }
                            }
                        } else {
                            Button {
                                showManualEntry = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                    Text("Enter manually")
                                        .font(RRFont.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(Color.rrTextSecondary)
                            }
                            .frame(minHeight: 44)
                        }

                        Divider()

                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                Text("\(Int(durationMinutes)) min")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.green)
                            }
                            Slider(value: $durationMinutes, in: 1...120, step: 1)
                                .tint(.green)
                        }

                        Divider()

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                            TextField("What did you talk about?", text: $notes, axis: .vertical)
                                .font(RRFont.body)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }

                        RRButton("Log Call", icon: "phone.fill") {
                            submitCall()
                        }
                    }
                }
                .padding(.horizontal)

                // History
                if !entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "Recent Calls")

                            ForEach(entries) { entry in
                                HStack(alignment: .top) {
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(.green)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(entry.contactName)
                                                .font(RRFont.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color.rrText)
                                            RRBadge(text: "\(entry.durationMinutes) min", color: .green)
                                        }
                                        Text(relativeDay(entry.date))
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                        if !entry.notes.isEmpty {
                                            Text(entry.notes)
                                                .font(RRFont.caption)
                                                .foregroundStyle(Color.rrTextSecondary)
                                        }
                                    }
                                    Spacer()
                                }
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(
                selectedName: $contactName,
                selectedPhone: $contactPhone
            )
        }
        .onChange(of: contactName) {
            // When a device contact is picked, set role to "contact" if not already a support role
            if !contactName.isEmpty && contactRole.isEmpty {
                contactRole = "contact"
            }
        }
    }

    // MARK: - Selected Contact Display

    private var selectedContactView: some View {
        HStack(spacing: 12) {
            Image(systemName: contactRoleIcon(contactRole))
                .font(.title3)
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 36, height: 36)
                .background(Color.rrPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(contactName)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                RRBadge(text: contactRoleLabel(contactRole), color: Color.rrPrimary)
            }

            Spacer()

            Button {
                contactName = ""
                contactRole = ""
                contactPhone = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(12)
        .background(Color.rrPrimary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Support Contact Chip

    private func supportContactChip(_ contact: RRSupportContact) -> some View {
        let isSelected = contactName == contact.name && contactRole == contact.role

        return Button {
            if isSelected {
                contactName = ""
                contactRole = ""
                contactPhone = ""
            } else {
                contactName = contact.name
                contactRole = contact.role
                contactPhone = contact.phone
                showManualEntry = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: contactRoleIcon(contact.role))
                    .font(.caption)
                Text(contact.name)
                    .font(RRFont.caption)
                    .fontWeight(.medium)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : Color.rrPrimary)
            .background(isSelected ? Color.rrPrimary : Color.rrPrimary.opacity(0.1))
            .clipShape(Capsule())
        }
        .frame(minHeight: 44)
    }

    // MARK: - Submit

    private func submitCall() {
        let userId = users.first?.id ?? UUID()
        let entry = RRPhoneCallLog(
            userId: userId,
            date: Date(),
            contactName: contactName.isEmpty ? "Unknown" : contactName,
            contactRole: contactRole.isEmpty ? "other" : contactRole,
            durationMinutes: Int(durationMinutes),
            notes: notes
        )
        modelContext.insert(entry)
        contactName = ""
        contactRole = ""
        contactPhone = ""
        notes = ""
        showManualEntry = false
    }
}

#Preview {
    NavigationStack {
        PhoneCallLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
