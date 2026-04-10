import SwiftUI

// MARK: - Drift Alert Banner View

/// Gentle drift alert banner shown at the top of the pattern view.
///
/// Design (PRD 2 compassion rules):
/// - Warm orange-tinted background, never alarming red
/// - Observational tone: "That's useful information" not "You're in danger"
/// - Action buttons: Call sponsor, Review circles, Grounding exercise
/// - Dismissible, never punitive, never shaming
struct DriftAlertBannerView: View {

    let alert: DriftAlert
    let onDismiss: () -> Void

    @State private var showGroundingExercise = false

    /// Default message when the alert doesn't provide one.
    private var displayMessage: String {
        alert.message ?? "You've been in your middle circle a few times this week. That's useful information -- your awareness is a strength."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header & Dismiss
            HStack(alignment: .top) {
                Image(systemName: "heart.text.clipboard")
                    .font(.title3)
                    .foregroundStyle(warmOrange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("A gentle heads-up")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Text(displayMessage)
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrText.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("Dismiss alert")
            }

            // MARK: - Action Buttons
            HStack(spacing: 10) {
                driftActionButton(
                    title: "Call sponsor",
                    icon: "phone",
                    action: callSponsor
                )

                driftActionButton(
                    title: "Review circles",
                    icon: "circle.grid.3x3",
                    action: reviewCircles
                )

                driftActionButton(
                    title: "Grounding",
                    icon: "leaf",
                    action: { showGroundingExercise = true }
                )
            }

            // MARK: - Reassurance
            Text("Noticing patterns is part of recovery. You're paying attention, and that matters.")
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)
                .italic()
        }
        .padding()
        .background(warmBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(warmOrange.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showGroundingExercise) {
            groundingExerciseSheet
        }
    }

    // MARK: - Action Button

    private func driftActionButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(RRFont.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(warmOrange)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(warmOrange.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sponsor Call

    private func callSponsor() {
        // Opens the phone dialer if sponsor is configured.
        // In production this would look up the sponsor from SwiftData.
    }

    // MARK: - Review Circles

    private func reviewCircles() {
        // Navigation to the circle editor.
        // In production this would push to the ThreeCirclesView.
    }

    // MARK: - Grounding Exercise Sheet

    private var groundingExerciseSheet: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.rrSuccess)

                Text("5-4-3-2-1 Grounding")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                VStack(alignment: .leading, spacing: 16) {
                    groundingStep(number: 5, sense: "things you can see")
                    groundingStep(number: 4, sense: "things you can touch")
                    groundingStep(number: 3, sense: "things you can hear")
                    groundingStep(number: 2, sense: "things you can smell")
                    groundingStep(number: 1, sense: "thing you can taste")
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Take your time. There is no rush.")
                    .font(RRFont.footnote)
                    .foregroundStyle(Color.rrTextSecondary)
                    .italic()

                Spacer()
            }
            .padding()
            .background(Color.rrBackground)
            .navigationTitle("Grounding Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showGroundingExercise = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func groundingStep(number: Int, sense: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 32)

            Text("Name \(number) \(sense)")
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
        }
    }

    // MARK: - Colors

    /// Warm orange tint -- intentionally not `.rrDestructive` or alarming red.
    private var warmOrange: Color {
        Color(red: 0.90, green: 0.60, blue: 0.25)
    }

    private var warmBackground: Color {
        warmOrange.opacity(0.06)
    }
}

#Preview {
    VStack {
        DriftAlertBannerView(
            alert: DriftAlert(
                alertId: "alert-1",
                windowStart: "2026-04-01",
                windowEnd: "2026-04-07",
                middleCircleDays: 3,
                message: "You've been in your middle circle a few times this week. That's useful information -- your awareness is a strength.",
                dismissed: false,
                createdAt: Date()
            ),
            onDismiss: {}
        )
    }
    .padding()
}
