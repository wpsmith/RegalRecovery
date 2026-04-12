import SwiftUI
import SwiftData

struct MeetingsAttendedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var entries: [RRMeetingLog]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var meetingName = ""
    @State private var meetingDate = Date()
    @State private var duration: Double = 60
    @State private var notes = ""

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick log
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RRSectionHeader(title: "Log a Meeting")

                        // Meeting name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meeting Name")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                            TextField("e.g. SA Home Group", text: $meetingName)
                                .font(RRFont.body)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        // Date picker (max 48hrs ago, no future dates)
                        DatePicker(
                            "Date",
                            selection: $meetingDate,
                            in: Date().addingTimeInterval(-48 * 3600)...Date(),
                            displayedComponents: .date
                        )
                        .font(RRFont.subheadline)

                        Divider()

                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                Text("\(Int(duration)) min")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            Slider(value: $duration, in: 15...120, step: 5)
                                .tint(Color.rrPrimary)
                        }

                        Divider()

                        // Notes
                        TextField("Notes", text: $notes, axis: .vertical)
                            .font(RRFont.body)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)

                        RRButton("Log Meeting", icon: "person.3.fill") {
                            submitMeeting()
                        }
                    }
                }
                .padding(.horizontal)

                // History
                if !entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "Attendance History")

                            ForEach(entries) { entry in
                                HStack(alignment: .top) {
                                    Image(systemName: "person.3.fill")
                                        .foregroundStyle(Color.rrPrimary)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.meetingName)
                                            .font(RRFont.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.rrText)
                                        Text(relativeDay(entry.date))
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                    Spacer()
                                    Text("\(entry.durationMinutes) min")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
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

    private func submitMeeting() {
        let userId = users.first?.id ?? UUID()
        guard !meetingName.isEmpty else { return }
        let minDate = Date().addingTimeInterval(-48 * 3600)
        guard meetingDate >= minDate, meetingDate <= Date() else { return }
        let entry = RRMeetingLog(
            userId: userId,
            date: meetingDate,
            meetingName: meetingName,
            durationMinutes: Int(duration),
            notes: notes
        )
        modelContext.insert(entry)
        meetingName = ""
        notes = ""
    }
}

#Preview {
    NavigationStack {
        MeetingsAttendedView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
