import SwiftUI
import SwiftData

struct FASTERScaleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var entries: [RRFASTEREntry]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var selectedStage: FASTERStage = .forgettingPriorities

    private var last30Entries: [RRFASTEREntry] {
        Array(entries.prefix(30))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stage cards
                VStack(spacing: 12) {
                    ForEach(FASTERStage.allCases) { stage in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStage = stage
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(stage.letter)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(selectedStage == stage ? .white : stage.color)
                                    .frame(width: 44, height: 44)
                                    .background(selectedStage == stage ? stage.color : stage.color.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(stage.name)
                                            .font(RRFont.headline)
                                            .foregroundStyle(Color.rrText)
                                        Spacer()
                                        if selectedStage == stage {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(stage.color)
                                        }
                                    }
                                    Text(stage.description)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }
                            }
                            .padding(12)
                            .background(selectedStage == stage ? stage.color.opacity(0.12) : Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(selectedStage == stage ? stage.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal)

                RRButton("Log FASTER Scale", icon: "gauge.with.needle") {
                    submitFASTER()
                }
                .padding(.horizontal)

                // History dots
                if !last30Entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RRSectionHeader(title: "Last 30 Days")

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                                ForEach(last30Entries.reversed()) { entry in
                                    let stage = FASTERStage(rawValue: entry.stage) ?? .forgettingPriorities
                                    RRColorDot(stage.color, size: 20)
                                }
                            }

                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    RRColorDot(.rrSuccess, size: 10)
                                    Text("Green")
                                        .font(RRFont.caption2)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                                HStack(spacing: 4) {
                                    RRColorDot(.yellow, size: 10)
                                    Text("Anxiety")
                                        .font(RRFont.caption2)
                                        .foregroundStyle(Color.rrTextSecondary)
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
    }

    private func submitFASTER() {
        let userId = users.first?.id ?? UUID()
        let entry = RRFASTEREntry(
            userId: userId,
            date: Date(),
            stage: selectedStage.rawValue
        )
        modelContext.insert(entry)
    }
}

#Preview {
    NavigationStack {
        FASTERScaleView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
