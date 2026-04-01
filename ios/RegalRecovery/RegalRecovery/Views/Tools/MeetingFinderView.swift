import SwiftUI
import MapKit

struct MeetingFinderView: View {
    @State private var activeFilters: Set<String> = []
    @State private var selectedMeeting: Meeting?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    private let filterOptions = ["SA", "CR", "AA", "Virtual", "In-Person"]

    private static let sampleMeetings: [Meeting] = [
        Meeting(name: "SA Home Group", fellowship: "SA", day: "Saturday", time: "9:00 AM", distance: "1.2 mi", location: "First Baptist Church, Austin TX", isVirtual: false, isSaved: true, latitude: 30.2672, longitude: -97.7431),
        Meeting(name: "SA Men's Meeting", fellowship: "SA", day: "Tuesday", time: "7:00 PM", distance: "2.8 mi", location: "Community Center, Austin TX", isVirtual: false, isSaved: false, latitude: 30.2850, longitude: -97.7340),
        Meeting(name: "SA Virtual Noon", fellowship: "SA", day: "Daily", time: "12:00 PM", distance: nil, location: "Zoom", isVirtual: true, isSaved: true, latitude: 30.2672, longitude: -97.7431),
        Meeting(name: "Celebrate Recovery", fellowship: "CR", day: "Friday", time: "6:30 PM", distance: "3.1 mi", location: "Grace Church, Austin TX", isVirtual: false, isSaved: false, latitude: 30.2500, longitude: -97.7500),
        Meeting(name: "SA Step Study", fellowship: "SA", day: "Thursday", time: "8:00 PM", distance: nil, location: "Zoom", isVirtual: true, isSaved: true, latitude: 30.2672, longitude: -97.7431),
    ]

    private var filteredMeetings: [Meeting] {
        guard !activeFilters.isEmpty else { return Self.sampleMeetings }
        return Self.sampleMeetings.filter { meeting in
            var match = false
            if activeFilters.contains(meeting.fellowship) { match = true }
            if activeFilters.contains("Virtual") && meeting.isVirtual { match = true }
            if activeFilters.contains("In-Person") && !meeting.isVirtual { match = true }
            return match
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Map
                Map(position: $cameraPosition) {
                    ForEach(filteredMeetings) { meeting in
                        Annotation(meeting.name, coordinate: CLLocationCoordinate2D(
                            latitude: meeting.latitude,
                            longitude: meeting.longitude
                        )) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(meeting.fellowship == "SA" ? Color.rrPrimary : .orange)
                        }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                .padding(.top)

                // MARK: - Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filterOptions, id: \.self) { filter in
                            filterChip(filter)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                // MARK: - Meeting List
                LazyVStack(spacing: 12) {
                    ForEach(filteredMeetings) { meeting in
                        Button {
                            selectedMeeting = meeting
                        } label: {
                            meetingRow(meeting)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color.rrBackground)
        .sheet(item: $selectedMeeting) { meeting in
            meetingDetailSheet(meeting)
        }
    }

    // MARK: - Filter Chip

    private func filterChip(_ filter: String) -> some View {
        let isActive = activeFilters.contains(filter)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isActive {
                    activeFilters.remove(filter)
                } else {
                    activeFilters.insert(filter)
                }
            }
        } label: {
            Text(filter)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isActive ? .white : Color.rrText)
                .background(isActive ? Color.rrPrimary : Color.rrSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isActive ? Color.clear : Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Meeting Row

    private func meetingRow(_ meeting: Meeting) -> some View {
        RRCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(meeting.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        RRBadge(
                            text: meeting.fellowship,
                            color: meeting.fellowship == "SA" ? .rrPrimary : .orange
                        )
                    }

                    Text("\(meeting.day) \u{2022} \(meeting.time)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    if meeting.isVirtual {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.caption2)
                            Text("Virtual")
                                .font(RRFont.caption)
                        }
                        .foregroundStyle(Color.rrPrimary)
                    } else if let distance = meeting.distance {
                        Text(distance)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }

                Spacer()

                if meeting.isSaved {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    // MARK: - Detail Sheet

    private func meetingDetailSheet(_ meeting: Meeting) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 10) {
                        Text(meeting.name)
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrText)
                        RRBadge(
                            text: meeting.fellowship,
                            color: meeting.fellowship == "SA" ? .rrPrimary : .orange
                        )
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(icon: "calendar", text: "\(meeting.day) at \(meeting.time)")
                        detailRow(icon: "mappin.and.ellipse", text: meeting.location)
                        if let distance = meeting.distance {
                            detailRow(icon: "car.fill", text: distance)
                        }
                        if meeting.isVirtual {
                            detailRow(icon: "video.fill", text: "Virtual Meeting")
                        }
                    }

                    Divider()

                    // What to Expect
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What to Expect")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        Text(whatToExpect(for: meeting.fellowship))
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedMeeting = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 24)
            Text(text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
        }
    }

    private func whatToExpect(for fellowship: String) -> String {
        switch fellowship {
        case "SA":
            return "SA meetings follow a structured format: opening reading, sharing time, and closing prayer. You'll be welcomed warmly. No one will ask you to share. Just listen and relate."
        case "CR":
            return "Celebrate Recovery meets in a large group for worship and teaching, then breaks into small gender-specific groups for sharing. It's Christ-centered and welcoming."
        default:
            return "Meetings provide a safe, confidential space for sharing and support. First-timers are always welcome."
        }
    }
}

#Preview {
    NavigationStack {
        MeetingFinderView()
    }
}
