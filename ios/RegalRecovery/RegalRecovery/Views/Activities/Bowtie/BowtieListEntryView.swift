import SwiftUI

struct BowtieListEntryView: View {
    let markers: [RRBowtieMarker]
    let side: BowtieSide
    let roleIds: [UUID]
    let roles: [RRUserRole]
    let vocabulary: EmotionVocabulary
    let onAddMarker: (Int) -> Void
    let onEditMarker: (RRBowtieMarker) -> Void
    let onDeleteMarker: (RRBowtieMarker) -> Void
    let onProcessMarker: (RRBowtieMarker) -> Void

    private var orderedIntervals: [Int] {
        let intervals = BowtieSide.timeIntervals
        return side == .past ? intervals.reversed() : intervals
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(side.displayName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)
                .padding(.bottom, 4)

            ForEach(orderedIntervals, id: \.self) { interval in
                intervalSection(interval)
            }
        }
    }

    // MARK: - Interval Section

    private func intervalSection(_ interval: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(side.labelForInterval(interval))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrTextSecondary)

                Spacer()

                Button {
                    onAddMarker(interval)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.rrPrimary)
                }
                .buttonStyle(.plain)
            }

            let intervalMarkers = markers.filter { $0.timeIntervalHours == interval }
            if intervalMarkers.isEmpty {
                RRCard {
                    HStack {
                        Text(String(localized: "No markers"))
                            .font(.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                    }
                }
            } else {
                ForEach(intervalMarkers, id: \.id) { marker in
                    markerCard(marker)
                }
            }

            Divider()
                .padding(.vertical, 4)
        }
    }

    // MARK: - Marker Card

    private func markerCard(_ marker: RRBowtieMarker) -> some View {
        Button {
            onEditMarker(marker)
        } label: {
            RRCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Role name
                        Text(roleName(for: marker.roleId))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        if marker.isProcessed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                        }
                    }

                    // I-type chips
                    iTypeChips(for: marker)

                    // Big ticket chips
                    if let bigTickets = marker.bigTicketEmotions, !bigTickets.isEmpty {
                        bigTicketChips(for: bigTickets)
                    }

                    // Description preview
                    if let desc = marker.briefDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(2)
                    }

                    // Process button
                    if !marker.isProcessed {
                        Button {
                            onProcessMarker(marker)
                        } label: {
                            Text(String(localized: "Process this"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rrPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDeleteMarker(marker)
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
    }

    // MARK: - Chips

    private func iTypeChips(for marker: RRBowtieMarker) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(marker.iActivations, id: \.iType) { activation in
                HStack(spacing: 4) {
                    Image(systemName: activation.iType.icon)
                        .font(.caption2)
                    Text(activation.iType.displayName)
                        .font(.caption2)
                    RRBadge(
                        text: "\(activation.intensity)",
                        color: activation.iType.color
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(activation.iType.color.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    private func bigTicketChips(for activations: [BigTicketActivation]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(activations, id: \.emotion) { activation in
                HStack(spacing: 4) {
                    Image(systemName: activation.emotion.icon)
                        .font(.caption2)
                    Text(activation.emotion.displayName)
                        .font(.caption2)
                    RRBadge(
                        text: "\(activation.intensity)",
                        color: activation.emotion.color
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(activation.emotion.color.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Helpers

    private func roleName(for roleId: UUID) -> String {
        roles.first { $0.id == roleId }?.label ?? String(localized: "Unknown Role")
    }
}
