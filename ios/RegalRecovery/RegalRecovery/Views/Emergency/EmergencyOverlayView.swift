import SwiftUI
import SwiftData

struct EmergencyOverlayView: View {
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext

    @Query private var users: [RRUser]

    @Query(filter: #Predicate<RRSupportContact> { $0.role == "sponsor" })
    private var sponsors: [RRSupportContact]

    @Query private var streaks: [RRStreak]

    @State private var showUrgeSurfingTimer = false
    @State private var showUrgeSheet = false
    @State private var showPanicSheet = false
    @State private var showBreathingSheet = false
    @State private var autoLoggedUrgeId: UUID?
    @State private var showAutoLogDismiss = false

    // Urge logging state
    @State private var urgeStep = 1
    @State private var urgeIntensity: Double = 5
    @State private var selectedTriggers: Set<String> = []
    @State private var urgeNotes = ""

    private let triggers = ["Stress", "Loneliness", "Boredom", "Anger", "Tiredness", "Social Media", "Late Night", "Conflict"]

    private var sponsor: RRSupportContact? { sponsors.first }
    private var currentStreakDays: Int { streaks.first?.currentDays ?? 0 }
    private var userId: UUID { users.first?.id ?? UUID() }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    Text("I'm struggling right now")
                        .font(RRFont.largeTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 56)
                        .padding(.bottom, 8)

                    // 0. Urge Surfing Timer
                    emergencyCard(
                        icon: "water.waves",
                        iconColor: .rrPrimary,
                        title: "Urge Surfing Timer",
                        subtitle: "Ride the wave for 20 minutes"
                    ) {
                        showUrgeSurfingTimer = true
                    }

                    // 1. Log Urge
                    emergencyCard(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "Log Urge",
                        subtitle: "Track intensity, triggers, and notes"
                    ) {
                        urgeStep = 1
                        urgeIntensity = 5
                        selectedTriggers = []
                        urgeNotes = ""
                        showUrgeSheet = true
                    }

                    // 2. Panic Button
                    emergencyCard(
                        icon: "camera.fill",
                        iconColor: .rrDestructive,
                        title: "Panic Button",
                        subtitle: "See how far you've come"
                    ) {
                        showPanicSheet = true
                    }

                    // 3. Call Sponsor
                    emergencyCard(
                        icon: "phone.fill",
                        iconColor: .rrSuccess,
                        title: "Call Sponsor",
                        subtitle: sponsor.map { "\($0.name) — \($0.phone)" } ?? "No sponsor configured"
                    ) {
                        if let phone = sponsor?.phone,
                           let url = URL(string: "tel:\(phone.filter(\.isNumber))") {
                            UIApplication.shared.open(url)
                        }
                    }

                    // 4. Breathing Exercise
                    emergencyCard(
                        icon: "wind",
                        iconColor: .rrPrimary,
                        title: "Breathing Exercise",
                        subtitle: "4-7-8 guided breathing"
                    ) {
                        showBreathingSheet = true
                    }

                    // 5. Crisis Hotline
                    emergencyCard(
                        icon: "phone.arrow.up.right",
                        iconColor: .white,
                        title: "SA Helpline",
                        subtitle: "866-424-8777"
                    ) {
                        // Demo — no action
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }

            // Dismiss button
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .sheet(isPresented: $showUrgeSheet) {
            urgeLoggingSheet
        }
        .sheet(isPresented: $showPanicSheet) {
            panicSheet
        }
        .sheet(isPresented: $showBreathingSheet) {
            BreathingExerciseView()
        }
        .fullScreenCover(isPresented: $showUrgeSurfingTimer) {
            UrgeSurfingTimerView(isPresented: $showUrgeSurfingTimer)
        }
        .overlay(alignment: .top) {
            if showAutoLogDismiss {
                Button {
                    dismissAutoLog()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Urge logged. Tap to undo if accidental.")
                            .font(RRFont.caption)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showAutoLogDismiss)
        .onAppear {
            autoLogUrge()
        }
    }

    // MARK: - Auto-Logging

    private func autoLogUrge() {
        let urgeId = UUID()
        let urgeLog = RRUrgeLog(
            id: urgeId,
            userId: userId,
            date: Date(),
            intensity: 0,
            triggers: [],
            notes: "Emergency overlay activated",
            resolution: ""
        )
        modelContext.insert(urgeLog)
        try? modelContext.save()
        autoLoggedUrgeId = urgeId
        showAutoLogDismiss = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                showAutoLogDismiss = false
            }
        }
    }

    private func dismissAutoLog() {
        guard let urgeId = autoLoggedUrgeId else { return }
        let descriptor = FetchDescriptor<RRUrgeLog>(
            predicate: #Predicate { $0.id == urgeId }
        )
        if let urgeLog = try? modelContext.fetch(descriptor).first {
            modelContext.delete(urgeLog)
            try? modelContext.save()
        }
        autoLoggedUrgeId = nil
        withAnimation {
            showAutoLogDismiss = false
        }
    }

    // MARK: - Emergency Card

    private func emergencyCard(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(RRFont.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Urge Logging Sheet

    private var urgeLoggingSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Step indicator
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { step in
                        Capsule()
                            .fill(step <= urgeStep ? Color.orange : Color.rrTextSecondary.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)

                switch urgeStep {
                case 1:
                    urgeStepIntensity
                case 2:
                    urgeStepType
                case 3:
                    urgeStepTriggers
                default:
                    urgeStepNotes
                }

                Spacer()

                // Navigation
                HStack(spacing: 12) {
                    if urgeStep > 1 {
                        Button {
                            withAnimation { urgeStep -= 1 }
                        } label: {
                            Text("Back")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.rrPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    Button {
                        if urgeStep < 4 {
                            withAnimation { urgeStep += 1 }
                        } else {
                            showUrgeSheet = false
                        }
                    } label: {
                        Text(urgeStep == 4 ? "Log Urge" : "Next")
                            .font(RRFont.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(urgeStep == 4 ? Color.orange : Color.rrPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // Step 1: Intensity
    private var urgeStepIntensity: some View {
        VStack(spacing: 20) {
            Text("How intense is the urge?")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            Text("\(Int(urgeIntensity))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(intensityColor)

            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.rrSuccess, .yellow, .orange, .rrDestructive],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 44)

                Slider(value: $urgeIntensity, in: 1...10, step: 1)
                    .tint(.clear)
            }
            .padding(.horizontal)

            HStack {
                Text("Mild")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
                Text("Severe")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }

    private var intensityColor: Color {
        let value = Int(urgeIntensity)
        if value <= 3 { return .rrSuccess }
        if value <= 6 { return .yellow }
        if value <= 8 { return .orange }
        return .rrDestructive
    }

    // Step 2: Addiction Type
    private var urgeStepType: some View {
        VStack(spacing: 20) {
            Text("What type of urge?")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            RRBadge(text: "Sex Addiction (SA)", color: .rrPrimary)
                .scaleEffect(1.2)

            Text("Pre-selected based on your profile")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(.horizontal)
    }

    // Step 3: Triggers
    private var urgeStepTriggers: some View {
        VStack(spacing: 20) {
            Text("What triggered this urge?")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(triggers, id: \.self) { trigger in
                    Button {
                        if selectedTriggers.contains(trigger) {
                            selectedTriggers.remove(trigger)
                        } else {
                            selectedTriggers.insert(trigger)
                        }
                    } label: {
                        Text(trigger)
                            .font(RRFont.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedTriggers.contains(trigger) ? .white : Color.rrText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selectedTriggers.contains(trigger) ? Color.orange : Color.rrSurface)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // Step 4: Notes
    private var urgeStepNotes: some View {
        VStack(spacing: 20) {
            Text("Any notes?")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            TextEditor(text: $urgeNotes)
                .font(RRFont.body)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

            if urgeNotes.isEmpty {
                Text("Optional — write what you're feeling or thinking right now.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    // MARK: - Panic Sheet

    private var panicSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("\(currentStreakDays) Days Strong")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You are God's child. — John 1:12")
                    .font(RRFont.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Text("Take a deep breath")
                    .font(RRFont.headline)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)

                Spacer()

                // Camera placeholder
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.3))
                            Text("Camera Placeholder")
                                .font(RRFont.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    )
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    EmergencyOverlayView(isPresented: .constant(true))
}
