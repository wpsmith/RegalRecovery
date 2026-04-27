import SwiftUI

struct QuadrantRatingView: View {
    let quadrant: QuadrantType
    @Binding var score: Int
    @Binding var indicators: Set<String>
    @Binding var reflection: String
    let onNext: () -> Void
    let onPrevious: () -> Void
    let isFirstStep: Bool
    let isLastBeforeSummary: Bool

    @State private var sliderValue: Double = 5

    private var scoreLabel: String {
        switch score {
        case 1...3: return String(localized: "Struggling")
        case 4...6: return String(localized: "Managing")
        case 7...8: return String(localized: "Stable")
        case 9...10: return String(localized: "Thriving")
        default: return String(localized: "Managing")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                scriptureSection

                sliderSection

                indicatorsSection

                reflectionSection

                navigationButtons
                    .padding(.bottom, 32)
            }
        }
        .background(Color.rrBackground)
        .onAppear {
            sliderValue = Double(score)
        }
        .onChange(of: sliderValue) { _, newValue in
            score = Int(newValue.rounded())
        }
    }

    private var headerSection: some View {
        ZStack {
            quadrant.color
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                Image(systemName: quadrant.icon)
                    .font(.system(size: 52))
                    .foregroundStyle(.white)

                Text(quadrant.displayName)
                    .font(RRFont.largeTitle)
                    .foregroundStyle(.white)

                Text(quadrant.subtitle)
                    .font(RRFont.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var scriptureSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quadrant.scriptureText)
                .font(RRFont.callout)
                .italic()
                .foregroundStyle(Color.rrText)
                .fixedSize(horizontal: false, vertical: true)

            Text(quadrant.scriptureReference)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
    }

    private var sliderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "How are you doing in this area this week?"))
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            HStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(quadrant.color)
                    .frame(width: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scoreLabel)
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(quadrant.color)
                }
            }

            Slider(value: $sliderValue, in: 1...10, step: 1)
                .tint(quadrant.color)

            HStack {
                Text(String(localized: "1 Struggling"))
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
                Text(String(localized: "10 Thriving"))
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .padding(16)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private var indicatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Indicators (check all that apply)"))
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(quadrant.behavioralIndicators, id: \.self) { indicator in
                    let isChecked = indicators.contains(indicator)
                    Button {
                        if isChecked {
                            indicators.remove(indicator)
                        } else {
                            indicators.insert(indicator)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(isChecked ? quadrant.color : Color.rrTextSecondary)

                            Text(indicator)
                                .font(RRFont.body)
                                .foregroundStyle(isChecked ? Color.rrText : Color.rrTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(String(localized: "\(indicators.count) of \(quadrant.behavioralIndicators.count) checked"))
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(16)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Reflection (optional)"))
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            ZStack(alignment: .topLeading) {
                if reflection.isEmpty {
                    Text(String(localized: "One sentence reflection (optional)"))
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: Binding(
                    get: { reflection },
                    set: { newValue in
                        if newValue.count <= 280 {
                            reflection = newValue
                        }
                    }
                ))
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
            }

            Text(String(localized: "\(reflection.count)/280"))
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if !isFirstStep {
                Button {
                    onPrevious()
                } label: {
                    Text(String(localized: "← Back"))
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Button {
                onNext()
            } label: {
                Text(isLastBeforeSummary ? String(localized: "Review") : String(localized: "Next →"))
                    .font(RRFont.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(quadrant.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
    }
}
