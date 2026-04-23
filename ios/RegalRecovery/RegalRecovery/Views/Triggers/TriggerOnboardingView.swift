// Views/Triggers/TriggerOnboardingView.swift
import SwiftUI

struct TriggerOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            icon: "bolt.trianglebadge.exclamationmark",
            title: "What are triggers?",
            body: "A trigger is anything — a feeling, a place, a thought — that activates a craving. Noticing a trigger isn't a failure. It's a recovery skill."
        ),
        (
            icon: "cross.fill",
            title: "Temptation, not sin",
            body: "Experiencing a trigger is like being tempted — it's something that happens to you, not something you chose. Recognizing it is the first step to responding well."
        ),
        (
            icon: "timer",
            title: "Three ways to log",
            body: "Quick Log: select triggers + intensity in under 15 seconds.\nStandard: add mood, situation, and what you did.\nDeep: explore unmet needs and what the trigger teaches you."
        ),
        (
            icon: "hand.raised.fingers.spread",
            title: "Coping tools at your fingertips",
            body: "After logging, you'll see coping strategies matched to your trigger type. Breathing exercises, grounding techniques, and a direct line to your accountability partner."
        ),
        (
            icon: "lock.shield",
            title: "Your data stays private",
            body: "Trigger data is encrypted on your device. Notifications never show trigger details. You control what's shared and can delete everything at any time."
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(
                        icon: pages[index].icon,
                        title: pages[index].title,
                        body: pages[index].body
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            actionButton

            if currentPage < pages.count - 1 {
                Button("Skip") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 8)
        }
    }

    private func onboardingPage(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(Color.rrPrimary)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var actionButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                dismiss()
            }
        } label: {
            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.rrPrimary)
                .cornerRadius(12)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    TriggerOnboardingView()
}
