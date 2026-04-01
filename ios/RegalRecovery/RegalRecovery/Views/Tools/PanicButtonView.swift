import SwiftUI
import SwiftData

struct PanicButtonView: View {
    @Query(filter: #Predicate<RRSupportContact> { $0.role == "sponsor" })
    private var sponsors: [RRSupportContact]

    @Query private var streaks: [RRStreak]

    @State private var showPanicMode = false

    private var sponsor: RRSupportContact? { sponsors.first }
    private var currentStreakDays: Int { streaks.first?.currentDays ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundStyle(Color.rrDestructive)
                    Text("Emergency Tools")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrDestructive)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                // MARK: - Panic Mode
                Button {
                    showPanicMode = true
                } label: {
                    emergencyCard(
                        icon: "camera.fill",
                        title: "Panic Mode",
                        subtitle: "Front camera with motivations overlay",
                        color: .rrDestructive
                    )
                }
                .buttonStyle(.plain)

                // MARK: - Call Sponsor
                if let sponsor {
                    Link(destination: URL(string: "tel:\(sponsor.phone.filter(\.isNumber))")!) {
                        emergencyCard(
                            icon: "phone.fill",
                            title: "Call Sponsor",
                            subtitle: "\(sponsor.name) \u{2014} Sponsor \u{2022} \(sponsor.phone)",
                            color: .rrSuccess
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    emergencyCard(
                        icon: "phone.fill",
                        title: "Call Sponsor",
                        subtitle: "No sponsor configured",
                        color: .rrSuccess
                    )
                }

                // MARK: - Breathing Exercise
                NavigationLink(destination: breathingPlaceholder) {
                    emergencyCard(
                        icon: "wind",
                        title: "Breathing Exercise",
                        subtitle: "4-7-8 Breathing",
                        color: .rrPrimary
                    )
                }
                .buttonStyle(.plain)

                // MARK: - Crisis Hotline
                Link(destination: URL(string: "tel:8664248777")!) {
                    emergencyCard(
                        icon: "phone.arrow.up.right",
                        title: "Crisis Hotline",
                        subtitle: "SA Helpline: 866-424-8777",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color.rrBackground)
        .sheet(isPresented: $showPanicMode) {
            panicModeSheet
        }
    }

    // MARK: - Emergency Card

    private func emergencyCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        RRCard {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text(subtitle)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    // MARK: - Panic Mode Sheet

    private var panicModeSheet: some View {
        ZStack {
            // Camera placeholder
            Color.black
                .ignoresSafeArea()

            // Motivations overlay
            VStack(spacing: 24) {
                Spacer()

                Text("\(currentStreakDays) Days Strong")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You are God's child")
                    .font(RRFont.title)
                    .foregroundStyle(.white.opacity(0.9))

                Divider()
                    .background(.white.opacity(0.3))
                    .padding(.horizontal, 40)

                Text("Breathe in... hold... breathe out...")
                    .font(RRFont.headline)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button {
                    showPanicMode = false
                } label: {
                    Text("Close")
                        .font(RRFont.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Breathing Placeholder

    /// References BreathingExerciseView from Emergency folder.
    /// Falls back to a placeholder if that view hasn't been created yet.
    private var breathingPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "wind")
                .font(.system(size: 64))
                .foregroundStyle(Color.rrPrimary)
            Text("4-7-8 Breathing")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
            Text("Breathe in for 4 seconds\nHold for 7 seconds\nBreathe out for 8 seconds")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.rrBackground)
    }
}

#Preview {
    NavigationStack {
        PanicButtonView()
    }
}
