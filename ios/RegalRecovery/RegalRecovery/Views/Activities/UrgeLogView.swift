import SwiftUI
import SwiftData

struct UrgeLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRAddiction.name) private var addictions: [RRAddiction]

    @State private var currentStep = 0
    @State private var intensity: Double = 5
    @State private var selectedTriggers: Set<String> = []
    @State private var notes = ""
    @State private var selectedAddictionIndex = 0

    private let triggers = ["Stress", "Loneliness", "Boredom", "Anger", "Tiredness", "Social Media", "Late Night", "Conflict"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }

                switch currentStep {
                case 0:
                    step1Intensity
                case 1:
                    step2Addiction
                case 2:
                    step3Triggers
                default:
                    step4Notes
                }

                // Navigation
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Color.rrPrimary)
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if currentStep < 3 {
                        Button {
                            withAnimation { currentStep += 1 }
                        } label: {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.rrPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Step 1: Intensity

    private var step1Intensity: some View {
        RRCard {
            VStack(spacing: 20) {
                Text("How intense is the urge?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                Text("\(Int(intensity))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(intensityColor)

                Text("/10")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrTextSecondary)

                ZStack(alignment: .leading) {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 6)
                        .clipShape(Capsule())
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 30)

                    Slider(value: $intensity, in: 1...10, step: 1)
                        .tint(.clear)
                }
            }
        }
        .padding(.horizontal)
    }

    private var intensityColor: Color {
        switch Int(intensity) {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }

    // MARK: - Step 2: Addiction

    private var step2Addiction: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Which addiction?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                ForEach(Array(addictions.enumerated()), id: \.offset) { index, addiction in
                    Button {
                        selectedAddictionIndex = index
                    } label: {
                        HStack {
                            Image(systemName: selectedAddictionIndex == index ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedAddictionIndex == index ? Color.rrPrimary : Color.rrTextSecondary)
                            Text(addiction.name)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedAddictionIndex == index ? Color.rrPrimary.opacity(0.1) : Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Step 3: Triggers

    private var step3Triggers: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("What triggered the urge?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                Text("Select all that apply")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                FlowLayout(spacing: 10) {
                    ForEach(triggers, id: \.self) { trigger in
                        Button {
                            if selectedTriggers.contains(trigger) {
                                selectedTriggers.remove(trigger)
                            } else {
                                selectedTriggers.insert(trigger)
                            }
                        } label: {
                            Text(trigger)
                                .font(RRFont.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedTriggers.contains(trigger) ? .white : Color.rrText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedTriggers.contains(trigger) ? Color.rrPrimary : Color.rrSurface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(Color.rrTextSecondary.opacity(0.2), lineWidth: selectedTriggers.contains(trigger) ? 0 : 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Step 4: Notes

    private var step4Notes: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Any notes? (optional)")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRButton("Log Urge", icon: "exclamationmark.triangle.fill") {
                submitUrge()
            }
            .padding(.horizontal)
        }
    }

    private func submitUrge() {
        let userId = users.first?.id ?? UUID()
        let addictionId = addictions.indices.contains(selectedAddictionIndex) ? addictions[selectedAddictionIndex].id : nil
        let entry = RRUrgeLog(
            userId: userId,
            date: Date(),
            intensity: Int(intensity),
            addictionId: addictionId,
            triggers: Array(selectedTriggers),
            notes: notes,
            resolution: ""
        )
        modelContext.insert(entry)
    }
}

#Preview {
    NavigationStack {
        UrgeLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
