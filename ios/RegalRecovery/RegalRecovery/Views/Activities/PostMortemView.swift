import SwiftUI

struct PostMortemView: View {
    @State private var currentStep = 0
    @State private var sectionTexts: [String] = Array(repeating: "", count: 6)

    private let sections = [
        ("The Day Before", "Describe what happened the day before. What was your emotional state? Were there any warning signs?"),
        ("Morning", "How did your morning start? Did you follow your routine? What was different?"),
        ("Throughout the Day", "Walk through the key moments of the day. When did things start to shift?"),
        ("The Build-Up", "What were the triggers? What thoughts or feelings escalated? Where did you feel it in your body?"),
        ("The Acting Out", "Describe what happened without graphic detail. What was the sequence of decisions?"),
        ("Immediately After", "How did you feel? What did you do next? Who did you reach out to?"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // History note
                RRCard {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.title2)
                            .foregroundStyle(Color.rrSuccess)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Post-Mortem")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text("142 days ago — Before your current streak began")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)

                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<sections.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)

                // Step label
                HStack {
                    Text("Step \(currentStep + 1) of \(sections.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    Spacer()
                }
                .padding(.horizontal)

                // Current section
                RRCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(sections[currentStep].0)
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)

                        Text(sections[currentStep].1)
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()

                        TextEditor(text: $sectionTexts[currentStep])
                            .frame(minHeight: 180)
                            .font(RRFont.body)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color.rrBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(.horizontal)

                // Navigation buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button {
                            withAnimation {
                                currentStep -= 1
                            }
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

                    Button {
                        withAnimation {
                            if currentStep < sections.count - 1 {
                                currentStep += 1
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentStep < sections.count - 1 ? "Next" : "Complete")
                            if currentStep < sections.count - 1 {
                                Image(systemName: "chevron.right")
                            } else {
                                Image(systemName: "checkmark")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }
}

#Preview {
    NavigationStack {
        PostMortemView()
    }
}
