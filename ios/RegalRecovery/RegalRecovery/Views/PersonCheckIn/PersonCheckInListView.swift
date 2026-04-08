import SwiftUI

struct PersonCheckInListView: View {
    @State private var viewModel = PersonCheckInViewModel()
    @State private var showCreateSheet = false
    @State private var selectedFilter: PersonCheckInType?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Streak summary bar
                streakSummaryBar

                // Filter chips
                filterChips

                // Check-in list
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredHistory.isEmpty {
                    emptyState
                } else {
                    List(filteredHistory) { entry in
                        PersonCheckInRow(entry: entry)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Person Check-ins")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                PersonCheckInCreateView(viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
            .overlay {
                if let encouragement = viewModel.encouragement {
                    encouragementBanner(encouragement)
                }
            }
        }
    }

    // MARK: - Subviews

    private var streakSummaryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.streaks, id: \.checkInType) { streak in
                    StreakChip(streak: streak)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color("rrSurface"))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(PersonCheckInType.allCases, id: \.self) { type in
                    FilterChip(title: type.displayName, isSelected: selectedFilter == type) {
                        selectedFilter = type
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No check-ins yet")
                .font(.headline)

            Text("Recovery doesn't happen alone. Track your conversations with the people who support your journey.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Log a Check-in") {
                showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func encouragementBanner(_ message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Color("rrSuccess").opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        viewModel.encouragement = nil
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var filteredHistory: [PersonCheckInEntry] {
        if let filter = selectedFilter {
            return viewModel.history.filter { $0.checkInType == filter }
        }
        return viewModel.history
    }
}

// MARK: - Row View

struct PersonCheckInRow: View {
    let entry: PersonCheckInEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.method.iconName)
                    .foregroundStyle(colorForType(entry.checkInType))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.checkInType.displayName)
                        .font(.headline)
                    if let name = entry.contactName {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let rating = entry.qualityRating {
                        QualityRatingBadge(rating: rating)
                    }
                    Text(entry.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !entry.topicsDiscussed.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(entry.topicsDiscussed, id: \.self) { topic in
                            Text(topic.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color("rrSurface"))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ type: PersonCheckInType) -> Color {
        switch type {
        case .spouse: return .pink
        case .sponsor: return .blue
        case .counselorCoach: return .green
        }
    }
}

// MARK: - Supporting Views

struct StreakChip: View {
    let streak: PersonCheckInStreakInfo

    var body: some View {
        VStack(spacing: 2) {
            Text(streak.checkInType.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("\(streak.currentStreak)")
                    .font(.headline)
                Text(streak.streakUnit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color("rrBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color("rrPrimary") : Color("rrSurface"))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct QualityRatingBadge: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
            }
        }
    }
}

#Preview {
    PersonCheckInListView()
}
