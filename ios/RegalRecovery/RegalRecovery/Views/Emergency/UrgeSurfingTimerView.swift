import SwiftUI
import SwiftData
import Combine

struct UrgeSurfingTimerView: View {
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [RRUser]
    @Query private var streaks: [RRStreak]
    @Query(filter: #Predicate<RRSupportContact> { $0.role == "sponsor" })
    private var sponsors: [RRSupportContact]

    @State private var viewModel = UrgeSurfingViewModel()
    @State private var timerCancellable: AnyCancellable?

    private var currentStreakDays: Int { streaks.first?.currentDays ?? 0 }
    private var userId: UUID { users.first?.id ?? UUID() }
    private var sponsor: RRSupportContact? { sponsors.first }

    private let motivations = [
        "The urge is a wave. You can ride it out.",
        "This feeling is temporary. You are not.",
        "God's grace is sufficient for you. — 2 Cor 12:9",
        "Be strong and courageous. — Joshua 1:9",
        "You have already overcome so much.",
        "Every second you wait, the urge weakens.",
        "Remember why you started this journey."
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: streak + dismiss
                topBar

                Spacer()

                // Motivation text
                motivationSection

                Spacer()

                // Wave animation area
                ZStack {
                    waveAnimation
                        .frame(height: 200)

                    // Timer display
                    timerDisplay
                }

                // Milestone progress track
                milestoneTrack
                    .padding(.top, 24)

                // Milestone message
                if let message = viewModel.milestoneMessage {
                    Text(message)
                        .font(RRFont.headline)
                        .foregroundStyle(viewModel.phase == .completed ? Color.rrSuccess : .white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.milestoneMessage)
                }

                Spacer()

                // Companion tool buttons
                if viewModel.isRunning {
                    companionTools
                        .padding(.bottom, 8)
                }

                // Action button
                actionButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }

            // Dismiss banner
            if viewModel.showDismissOption {
                VStack {
                    dismissBanner
                        .padding(.top, 100)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.showDismissOption)
            }
        }
        .sheet(isPresented: $viewModel.showCompanionBreathing) {
            BreathingExerciseView()
        }
        .sheet(isPresented: $viewModel.showCompanionPrayer) {
            prayerSheet
        }
        .sheet(isPresented: $viewModel.showCompanionAffirmations) {
            AffirmationSurfingSheet()
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            if viewModel.isRunning || viewModel.phase == .completed {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentStreakDays) Days Strong")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            Button {
                timerCancellable?.cancel()
                viewModel.stop()
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    // MARK: - Motivation

    private var motivationSection: some View {
        Group {
            if viewModel.isRunning || viewModel.phase == .completed {
                let index = (viewModel.secondsElapsed / 30) % motivations.count
                Text(motivations[index])
                    .font(RRFont.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.8), value: index)
            } else {
                VStack(spacing: 12) {
                    Text("Urge Surfing")
                        .font(RRFont.largeTitle)
                        .foregroundStyle(.white)

                    Text("The urge is a wave — ride it out for 20 minutes")
                        .font(RRFont.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Wave Animation

    private var waveAnimation: some View {
        WaveCanvasView(
            waveHeight: viewModel.waveHeight,
            phaseOffset: viewModel.wavePhaseOffset
        )
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text(viewModel.timerDisplay)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            if viewModel.isRunning {
                Text("remaining")
                    .font(RRFont.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Milestone Track

    private var milestoneTrack: some View {
        MilestoneTrackView(secondsElapsed: viewModel.secondsElapsed)
    }

    // MARK: - Companion Tools

    private var companionTools: some View {
        HStack(spacing: 16) {
            companionButton(icon: "wind", label: "Breathe") {
                viewModel.showCompanionBreathing = true
            }

            if let phone = sponsor?.phone {
                companionButton(icon: "phone.fill", label: "Call Sponsor") {
                    if let url = URL(string: "tel:\(phone.filter(\.isNumber))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            companionButton(icon: "hands.and.sparkles.fill", label: "Pray") {
                viewModel.showCompanionPrayer = true
            }

            companionButton(icon: "text.quote", label: "Affirm") {
                viewModel.showCompanionAffirmations = true
            }
        }
        .padding(.horizontal, 32)
    }

    private func companionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.rrPrimary)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Group {
            if viewModel.phase == .ready {
                Button {
                    viewModel.start(modelContext: modelContext, userId: userId)
                    startTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Timer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.rrPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else if viewModel.phase == .completed {
                Button {
                    timerCancellable?.cancel()
                    viewModel.markSurfed(modelContext: modelContext)
                    viewModel.stop()
                    isPresented = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.rrSuccess)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                Button {
                    timerCancellable?.cancel()
                    viewModel.markSurfed(modelContext: modelContext)
                    viewModel.stop()
                    isPresented = false
                } label: {
                    Text("I'm okay now")
                        .font(RRFont.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: - Dismiss Banner

    private var dismissBanner: some View {
        Button {
            viewModel.dismissAutoLog(modelContext: modelContext)
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
    }

    // MARK: - Prayer Sheet

    private var prayerSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button { viewModel.showCompanionPrayer = false } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)

                Image(systemName: "hands.and.sparkles.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.rrPrimary)

                Text("Panic Prayer")
                    .font(RRFont.largeTitle)
                    .foregroundStyle(.white)

                VStack(spacing: 16) {
                    Text("\"God, grant me the serenity to accept the things I cannot change, courage to change the things I can, and wisdom to know the difference.\"")
                        .font(RRFont.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("— Serenity Prayer")
                        .font(RRFont.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 32)

                Spacer()

                Text("Be still, and know that I am God. — Psalm 46:10")
                    .font(RRFont.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                viewModel.tick()
            }
    }
}

// MARK: - Wave Canvas

private struct WaveCanvasView: View {
    let waveHeight: Double
    let phaseOffset: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                drawWaves(context: context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func drawWaves(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let midY = size.height * 0.5
        let amplitude = size.height * 0.3 * waveHeight

        for layer in 0..<3 {
            let layerOffset = Double(layer) * 0.8
            let layerAlpha = 0.3 - Double(layer) * 0.08
            let path = buildWavePath(size: size, midY: midY, amplitude: amplitude, time: time, layerOffset: layerOffset)
            context.fill(path, with: .color(Color.rrPrimary.opacity(layerAlpha)))
        }
    }

    private func buildWavePath(size: CGSize, midY: Double, amplitude: Double, time: TimeInterval, layerOffset: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))

        for x in stride(from: 0.0, through: size.width, by: 2) {
            let normalizedX = x / size.width
            let waveY = sin(normalizedX * .pi * 2 + time * 1.5 + phaseOffset + layerOffset) * amplitude
            let secondWave = sin(normalizedX * .pi * 3 + time * 0.8 + layerOffset) * amplitude * 0.3
            path.addLine(to: CGPoint(x: x, y: midY + waveY + secondWave))
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Milestone Track

private struct MilestoneTrackView: View {
    let secondsElapsed: Int

    private let minutes = [0, 5, 10, 15, 20]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(minutes, id: \.self) { minute in
                if minute > 0 {
                    trackSegment(for: minute)
                }
                milestoneDot(for: minute)
            }
        }
        .padding(.horizontal, 32)
    }

    private func trackSegment(for minute: Int) -> some View {
        let filled = secondsElapsed >= minute * 60
        return Rectangle()
            .fill(filled ? Color.rrPrimary : Color.white.opacity(0.2))
            .frame(height: 3)
    }

    private func milestoneDot(for minute: Int) -> some View {
        let filled = secondsElapsed >= minute * 60
        let isEndpoint = minute == 0 || minute == 20
        let dotSize: CGFloat = isEndpoint ? 14 : 10

        return VStack(spacing: 4) {
            Circle()
                .fill(filled ? Color.rrPrimary : Color.white.opacity(0.3))
                .frame(width: dotSize, height: dotSize)

            Text("\(minute)m")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Affirmation Surfing Sheet

private struct AffirmationSurfingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var currentIndex = 0
    @State private var currentPackIndex = 0
    /// Tracks the highest affirmation index viewed per pack (for progress logging).
    @State private var maxViewedPerPack: [Int: Int] = [:]

    private let packs = ContentData.affirmationPacks.filter {
        $0.name == "I Am Accepted" || $0.name == "I Am Secure" || $0.name == "I Am Significant"
    }

    private var currentPack: AffirmationPack { packs[currentPackIndex] }
    private var currentAffirmation: Affirmation { currentPack.affirmations[currentIndex] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text(currentPack.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.rrPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.rrPrimary.opacity(0.15))
                        .clipShape(Capsule())

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()

                // Affirmation text
                VStack(spacing: 24) {
                    Text(currentAffirmation.text)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .id(currentAffirmation.id)

                    if !currentAffirmation.scripture.isEmpty {
                        Text("— \(currentAffirmation.scripture)")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrPrimary.opacity(0.8))
                    }
                }

                Spacer()

                // Pack dots
                HStack(spacing: 8) {
                    ForEach(Array(packs.enumerated()), id: \.offset) { idx, pack in
                        Circle()
                            .fill(idx == currentPackIndex ? Color.rrPrimary : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 12)

                // Counter
                Text("\(currentIndex + 1) of \(currentPack.affirmations.count)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 16)

                // Navigation
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentIndex > 0 {
                                currentIndex -= 1
                            } else if currentPackIndex > 0 {
                                currentPackIndex -= 1
                                currentIndex = packs[currentPackIndex].affirmations.count - 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .opacity(currentIndex == 0 && currentPackIndex == 0 ? 0.3 : 1)

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentIndex < currentPack.affirmations.count - 1 {
                                currentIndex += 1
                            } else if currentPackIndex < packs.count - 1 {
                                currentPackIndex += 1
                                currentIndex = 0
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(isLastAffirmation ? "Done" : "Next")
                                .fontWeight(.semibold)
                            if !isLastAffirmation {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
        .animation(.easeInOut(duration: 0.3), value: currentPackIndex)
        .onAppear { recordView() }
        .onChange(of: currentIndex) { recordView() }
        .onChange(of: currentPackIndex) { recordView() }
        .onDisappear { logProgress() }
    }

    private var isLastAffirmation: Bool {
        currentPackIndex == packs.count - 1 &&
        currentIndex == currentPack.affirmations.count - 1
    }

    /// Track the highest index viewed in the current pack.
    private func recordView() {
        let prev = maxViewedPerPack[currentPackIndex] ?? -1
        if currentIndex > prev {
            maxViewedPerPack[currentPackIndex] = currentIndex
        }
    }

    /// Build a progress summary string and log as an RRActivity.
    private func logProgress() {
        guard !maxViewedPerPack.isEmpty else { return }

        // Build summary like "3/11 I Am Accepted, 11/11 I Am Secure"
        var parts: [String] = []
        for (packIdx, maxIdx) in maxViewedPerPack.sorted(by: { $0.key < $1.key }) {
            guard packIdx < packs.count else { continue }
            let pack = packs[packIdx]
            let viewed = maxIdx + 1
            parts.append("\(viewed)/\(pack.affirmations.count) \(pack.name)")
        }

        let summary = parts.joined(separator: ", ")

        let activity = RRActivity(
            userId: UUID(),
            activityType: "Affirmation Log",
            date: Date(),
            data: JSONPayload([
                "source": .string("urgeSurfing"),
                "summary": .string(summary),
            ])
        )
        modelContext.insert(activity)
        try? modelContext.save()
    }
}

#Preview {
    UrgeSurfingTimerView(isPresented: .constant(true))
}
