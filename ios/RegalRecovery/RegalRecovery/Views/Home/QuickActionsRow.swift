import SwiftUI

struct QuickActionsRow: View {
    @State private var showFASTER = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Quick Actions")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button { showFASTER = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.with.dots.needle.33percent")
                                .font(.caption)
                            Text("FASTER")
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                            Text("NEW")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundStyle(.white)
                                .background(Color.rrSecondary)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color.rrPrimary)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    NavigationLink { UrgeLogView() } label: {
                        quickActionLabel("Log Urge", icon: "exclamationmark.triangle.fill")
                    }

                    NavigationLink { JournalView() } label: {
                        quickActionLabel("Journal", icon: "note.text")
                    }

                    NavigationLink { EmotionalJournalView() } label: {
                        quickActionLabel("EmoJournal", icon: "heart.text.square.fill")
                    }

                    NavigationLink { PrayerLogView() } label: {
                        quickActionLabel("Prayer", icon: "hands.clap.fill")
                    }

                    NavigationLink { MoodRatingView() } label: {
                        quickActionLabel("Mood", icon: "face.smiling")
                    }

                    NavigationLink { GratitudeTabView() } label: {
                        quickActionLabel("Gratitude", icon: "leaf.fill")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFASTER) {
            FASTERCheckInFlowView()
        }
    }

    private func quickActionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(RRFont.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(Color.rrPrimary)
        .background(Color.rrPrimary.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        QuickActionsRow()
            .padding()
            .background(Color.rrBackground)
    }
}
