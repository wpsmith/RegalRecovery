import SwiftUI
import SwiftData

struct VisionHistoryView: View {
    @Query(sort: \RRVisionStatement.version, order: .reverse)
    private var allVersions: [RRVisionStatement]

    @State private var selectedVersion: RRVisionStatement?

    var body: some View {
        ScrollView {
            if allVersions.isEmpty {
                Text("No version history yet.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(allVersions) { vision in
                        Button {
                            selectedVersion = vision
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(vision.isCurrent ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                    if vision.id != allVersions.last?.id {
                                        Rectangle()
                                            .fill(Color.rrTextSecondary.opacity(0.2))
                                            .frame(width: 2)
                                            .frame(maxHeight: .infinity)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Version \(vision.version)")
                                            .font(RRFont.headline)
                                            .foregroundStyle(Color.rrText)
                                        if vision.isCurrent {
                                            RRBadge(text: "Current", color: .rrPrimary)
                                        }
                                        Spacer()
                                    }

                                    Text(vision.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)

                                    Text(String(vision.identityStatement.prefix(100)))
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .lineLimit(2)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedVersion) { vision in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Version \(vision.version)")
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrText)

                        Text(vision.modifiedAt.formatted(date: .long, time: .shortened))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        Divider()

                        Text("I am becoming...")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(vision.identityStatement)
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrPrimary)

                        if !vision.visionBody.isEmpty {
                            Text(vision.visionBody)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }

                        if !vision.coreValues.isEmpty {
                            Divider()
                            FlowLayout(spacing: 8) {
                                ForEach(vision.coreValues, id: \.self) { value in
                                    Text(value)
                                        .font(RRFont.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(Color.rrPrimary)
                                        .background(Color.rrPrimary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        if let ref = vision.scriptureReference {
                            Divider()
                            Text(ref)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            if let text = vision.scriptureText {
                                Text(text)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.rrBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { selectedVersion = nil }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    NavigationStack {
        VisionHistoryView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
