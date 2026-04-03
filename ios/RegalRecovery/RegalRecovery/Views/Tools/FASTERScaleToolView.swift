import SwiftUI
import SwiftData

struct FASTERScaleToolView: View {
    @Query(sort: \RRFASTEREntry.date, order: .reverse)
    private var entries: [RRFASTEREntry]

    @State private var expandedStage: FASTERStage?
    @State private var selectedEntry: RRFASTEREntry?

    private var last30Entries: [RRFASTEREntry] {
        Array(entries.prefix(30))
    }

    private var checkInsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Engagement counter
                if !entries.isEmpty {
                    RRCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(checkInsThisMonth)")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.rrText)
                                Text("check-ins this month")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                    .padding(.horizontal)
                }

                // Stage reference cards
                RRSectionHeader(title: "The FASTER Scale")
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    ForEach(FASTERStage.allCases) { stage in
                        stageReferenceCard(stage)
                    }
                }
                .padding(.horizontal)

                // History dots
                if !last30Entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RRSectionHeader(title: "Last 30 Days")

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                                ForEach(last30Entries.reversed()) { entry in
                                    let stage = FASTERStage(rawValue: entry.assessedStage) ?? .restoration
                                    Button {
                                        selectedEntry = entry
                                    } label: {
                                        RRColorDot(stage.color, size: 20)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Legend
                            FlowLayout(spacing: 10) {
                                ForEach(FASTERStage.allCases) { stage in
                                    HStack(spacing: 4) {
                                        RRColorDot(stage.color, size: 8)
                                        Text(stage.letter)
                                            .font(RRFont.caption2)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .sheet(item: $selectedEntry) { entry in
            entryDetailSheet(entry)
        }
    }

    // MARK: - Stage Reference Card

    private func stageReferenceCard(_ stage: FASTERStage) -> some View {
        let isExpanded = expandedStage == stage

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedStage = isExpanded ? nil : stage
                }
            } label: {
                HStack(spacing: 14) {
                    Text(stage.letter)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(stage.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(stage.subtitle)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    Text(stage.description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowLayout(spacing: 8) {
                        ForEach(stage.indicators, id: \.self) { indicator in
                            Text(indicator)
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(stage.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(stage.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Entry Detail Sheet

    private func entryDetailSheet(_ entry: RRFASTEREntry) -> some View {
        let stage = FASTERStage(rawValue: entry.assessedStage) ?? .restoration

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date and stage
                    HStack(spacing: 10) {
                        Text(stage.letter)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(stage.color)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.name)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }

                    // Mood
                    HStack(spacing: 6) {
                        Text("Mood:")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text("\(entry.moodScore)/5")
                            .font(RRFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)
                    }

                    // Indicators
                    let indicators = entry.selectedIndicators
                    if !indicators.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Indicators (\(indicators.count))")
                                .font(RRFont.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rrTextSecondary)
                            FlowLayout(spacing: 6) {
                                ForEach(indicators, id: \.self) { indicator in
                                    Text(indicator)
                                        .font(RRFont.caption2)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.rrBackground)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Journal
                    if !entry.journalInsight.isEmpty {
                        journalField("Ah-ha", entry.journalInsight)
                    }
                    if !entry.journalWarning.isEmpty {
                        journalField("Uh-oh", entry.journalWarning)
                    }
                    if !entry.journalFreeText.isEmpty {
                        journalField("Notes", entry.journalFreeText)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("Check-In Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func journalField(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
            Text(text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
        }
    }
}

extension RRFASTEREntry: @retroactive Identifiable {}

#Preview {
    NavigationStack {
        FASTERScaleToolView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
