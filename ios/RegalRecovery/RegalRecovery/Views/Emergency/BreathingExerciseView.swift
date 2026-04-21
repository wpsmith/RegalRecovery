import SwiftUI
import Combine

struct BreathingExerciseView: View {
    enum Phase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"

        var duration: Int {
            switch self {
            case .inhale: return 4
            case .hold: return 7
            case .exhale: return 8
            }
        }

        var next: Phase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .inhale
            }
        }
    }

    @State private var isRunning = false
    @State private var currentPhase: Phase = .inhale
    @State private var currentSecond = 0
    @State private var cycleCount = 0
    @State private var circleScale: CGFloat = 1.0
    @State private var isComplete = false
    @State private var timerCancellable: AnyCancellable?

    private let totalCycles = 3

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.rrPrimary.opacity(0.15))
                    .frame(width: 240, height: 240)

                Circle()
                    .fill(Color.rrPrimary.opacity(phaseOpacity))
                    .frame(width: 180, height: 180)
                    .scaleEffect(circleScale)

                if isRunning && !isComplete {
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey(currentPhase.rawValue))
                            .font(RRFont.title)
                            .foregroundStyle(.white)
                        Text("\(currentPhase.duration - currentSecond)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }

            if isComplete {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.rrSuccess)

                    Text("Great job — you completed 3 cycles")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)
                }
            } else if isRunning {
                VStack(spacing: 8) {
                    Text(LocalizedStringKey(currentPhase.rawValue))
                        .font(RRFont.largeTitle)
                        .foregroundStyle(Color.rrText)

                    Text("Cycle \(cycleCount + 1) of \(totalCycles)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            } else {
                VStack(spacing: 8) {
                    Text("4-7-8 Breathing")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)

                    Text("Inhale 4s  ·  Hold 7s  ·  Exhale 8s")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            Spacer()

            if !isRunning && !isComplete {
                RRButton("Tap to Start", icon: "play.fill") {
                    startBreathing()
                }
                .padding(.horizontal, 32)
            } else if isComplete {
                RRButton("Done", icon: "checkmark") {
                    resetExercise()
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
        .background(Color.rrBackground.ignoresSafeArea())
        .onDisappear {
            timerCancellable?.cancel()
        }
    }

    private var phaseOpacity: Double {
        switch currentPhase {
        case .inhale: return 0.5
        case .hold: return 0.7
        case .exhale: return 0.3
        }
    }

    private func startBreathing() {
        isRunning = true
        isComplete = false
        cycleCount = 0
        currentPhase = .inhale
        currentSecond = 0
        animateCircle(for: .inhale)
        startTimer()
    }

    private func resetExercise() {
        isRunning = false
        isComplete = false
        cycleCount = 0
        currentPhase = .inhale
        currentSecond = 0
        circleScale = 1.0
    }

    private func animateCircle(for phase: Phase) {
        let duration = Double(phase.duration)
        switch phase {
        case .inhale:
            withAnimation(.easeInOut(duration: duration)) {
                circleScale = 1.8
            }
        case .hold:
            // Scale stays at 1.8
            break
        case .exhale:
            withAnimation(.easeInOut(duration: duration)) {
                circleScale = 1.0
            }
        }
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                tick()
            }
    }

    private func tick() {
        currentSecond += 1

        if currentSecond >= currentPhase.duration {
            currentSecond = 0
            let nextPhase = currentPhase.next

            if currentPhase == .exhale {
                cycleCount += 1
                if cycleCount >= totalCycles {
                    timerCancellable?.cancel()
                    isComplete = true
                    isRunning = false
                    return
                }
            }

            currentPhase = nextPhase
            animateCircle(for: nextPhase)
        }
    }
}

#Preview {
    BreathingExerciseView()
}
