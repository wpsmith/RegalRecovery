import SwiftUI
import SwiftData

struct PhoneCallLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var entries: [RRPhoneCallLog]
    @Query(sort: \RRSupportContact.name) private var contacts: [RRSupportContact]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var selectedContactIndex = 0
    @State private var durationMinutes: Double = 15
    @State private var notes = ""

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
        case "accountabilityPartner": return "Accountability Partner"
        default: return role.capitalized
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RRSectionHeader(title: "Log a Call")

                        // Contact picker
                        if !contacts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contact")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)
                                Picker("Contact", selection: $selectedContactIndex) {
                                    ForEach(Array(contacts.enumerated()), id: \.offset) { index, contact in
                                        Text("\(contact.name) (\(contactRoleLabel(contact.role)))").tag(index)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.rrPrimary)
                            }
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
    }

    private func submitCall() {
        let userId = users.first?.id ?? UUID()
        let contact = contacts.indices.contains(selectedContactIndex) ? contacts[selectedContactIndex] : nil
        let entry = RRPhoneCallLog(
            userId: userId,
            date: Date(),
            contactName: contact?.name ?? "Unknown",
            contactRole: contact?.role ?? "other",
            durationMinutes: Int(durationMinutes),
            notes: notes
        )
        modelContext.insert(entry)
        notes = ""
    }
}

#Preview {
    NavigationStack {
        PhoneCallLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
