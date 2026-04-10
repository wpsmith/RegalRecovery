import SwiftUI

// MARK: - Crisis Support View

/// Crisis support sheet providing immediate resources.
///
/// Accessed from "I need support" button in the pattern dashboard.
///
/// Resources:
/// - 988 Suicide & Crisis Lifeline
/// - Crisis Text Line (741741)
/// - SAMHSA (1-800-662-4357)
/// - Call sponsor/therapist (if configured)
/// - Brief grounding exercise (5-4-3-2-1 or breathing)
/// - Exit to home
///
/// Tone: Compassionate throughout. "Your circles will be here when you're ready."
struct CrisisSupportView: View {

    @State private var showBreathingExercise = false
    @State private var showGroundingExercise = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    header

                    // MARK: - Crisis Resources
                    crisisResources

                    // MARK: - Personal Support
                    personalSupport

                    // MARK: - Grounding Exercises
                    groundingSection

                    // MARK: - Reassurance
                    reassurance

                    // MARK: - Exit
                    exitButton
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBreathingExercise) {
                breathingExerciseSheet
            }
            .sheet(isPresented: $showGroundingExercise) {
                groundingExerciseSheet
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.rrPrimary)

            Text("You reached out. That takes courage.")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            Text("Whatever you are feeling right now is valid. Help is available, and you do not have to face this alone.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Crisis Resources

    private var crisisResources: some View {
        VStack(alignment: .leading, spacing: 4) {
            RRSectionHeader(title: "Crisis Resources")

            VStack(spacing: 0) {
                crisisResourceRow(
                    title: "988 Suicide & Crisis Lifeline",
                    subtitle: "Call or text 988 -- Available 24/7",
                    icon: "phone.fill",
                    color: .rrDestructive,
                    phoneNumber: "988"
                )

                Divider().padding(.leading, 56)

                crisisResourceRow(
                    title: "Crisis Text Line",
                    subtitle: "Text HOME to 741741",
                    icon: "message.fill",
                    color: .rrPrimary,
                    phoneNumber: nil,
                    smsNumber: "741741"
                )

                Divider().padding(.leading, 56)

                crisisResourceRow(
                    title: "SAMHSA National Helpline",
                    subtitle: "1-800-662-4357 -- Free, confidential, 24/7",
                    icon: "phone.fill",
                    color: .rrSuccess,
                    phoneNumber: "18006624357"
                )
            }
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func crisisResourceRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        phoneNumber: String? = nil,
        smsNumber: String? = nil
    ) -> some View {
        Group {
            if let phone = phoneNumber, let url = URL(string: "tel:\(phone)") {
                Link(destination: url) {
                    resourceRowContent(title: title, subtitle: subtitle, icon: icon, color: color)
                }
            } else if let sms = smsNumber, let url = URL(string: "sms:\(sms)&body=HOME") {
                Link(destination: url) {
                    resourceRowContent(title: title, subtitle: subtitle, icon: icon, color: color)
                }
            } else {
                resourceRowContent(title: title, subtitle: subtitle, icon: icon, color: color)
            }
        }
        .buttonStyle(.plain)
    }

    private func resourceRowContent(
        title: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RRFont.subheadline)
                    .fontWeight(.medium)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Personal Support

    private var personalSupport: some View {
        VStack(alignment: .leading, spacing: 4) {
            RRSectionHeader(title: "Your Support Network")

            VStack(spacing: 12) {
                // Call sponsor
                Button {
                    // In production: look up sponsor from SwiftData and place call
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.body)
                            .foregroundStyle(Color.rrPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Call my sponsor")
                                .font(RRFont.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rrText)
                            Text("Reach out to your sponsor directly")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "phone.arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
                .buttonStyle(.plain)

                // Call therapist
                Button {
                    // In production: look up therapist from SwiftData and place call
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stethoscope")
                            .font(.body)
                            .foregroundStyle(Color.rrSuccess)
                            .frame(width: 36, height: 36)
                            .background(Color.rrSuccess.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Call my therapist")
                                .font(RRFont.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rrText)
                            Text("If configured in your support contacts")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "phone.arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.rrSuccess)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Grounding Section

    private var groundingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            RRSectionHeader(title: "Grounding Exercises")

            HStack(spacing: 12) {
                Button {
                    showBreathingExercise = true
                } label: {
                    groundingCard(
                        icon: "wind",
                        title: "4-7-8 Breathing",
                        color: .rrPrimary
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showGroundingExercise = true
                } label: {
                    groundingCard(
                        icon: "leaf",
                        title: "5-4-3-2-1 Senses",
                        color: .rrSuccess
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func groundingCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Reassurance

    private var reassurance: some View {
        VStack(spacing: 8) {
            Text("Your circles will be here when you are ready.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            Text("Right now, just focus on this moment.")
                .font(RRFont.footnote)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.rrPrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Exit Button

    private var exitButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "house")
                Text("Exit to home")
            }
            .font(RRFont.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.rrTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Breathing Exercise Sheet

    private var breathingExerciseSheet: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "wind")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.rrPrimary)

                Text("4-7-8 Breathing")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                VStack(spacing: 20) {
                    breathingStep(phase: "Breathe in", seconds: 4)
                    breathingStep(phase: "Hold", seconds: 7)
                    breathingStep(phase: "Breathe out", seconds: 8)
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Repeat 3-4 times, or as many as you need.")
                    .font(RRFont.footnote)
                    .foregroundStyle(Color.rrTextSecondary)
                    .italic()

                Spacer()
            }
            .padding()
            .background(Color.rrBackground)
            .navigationTitle("Breathing Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showBreathingExercise = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func breathingStep(phase: String, seconds: Int) -> some View {
        HStack(spacing: 16) {
            Text("\(seconds)s")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 48)

            Text(phase)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            Spacer()
        }
    }

    // MARK: - Grounding Exercise Sheet

    private var groundingExerciseSheet: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.rrSuccess)

                Text("5-4-3-2-1 Grounding")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                VStack(alignment: .leading, spacing: 16) {
                    sensesStep(number: 5, sense: "things you can see")
                    sensesStep(number: 4, sense: "things you can touch")
                    sensesStep(number: 3, sense: "things you can hear")
                    sensesStep(number: 2, sense: "things you can smell")
                    sensesStep(number: 1, sense: "thing you can taste")
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

    private func sensesStep(number: Int, sense: String) -> some View {
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
}

#Preview {
    CrisisSupportView()
}
