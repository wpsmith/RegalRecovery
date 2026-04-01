import SwiftUI
import SwiftData
import Charts

struct RecoveryCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRCheckIn.date, order: .reverse) private var checkIns: [RRCheckIn]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var sobrietyStatus: Double = 95
    @State private var urgeCount: Double = 10
    @State private var meetingAttendance: Double = 80
    @State private var spiritualPractices: Double = 90
    @State private var emotionalState: Double = 75
    @State private var supportContact: Double = 85
    @State private var recoveryHealth: Double = 82

    private var questions: [(String, Binding<Double>)] {
        [
            ("Sobriety status", $sobrietyStatus),
            ("Urge count today", $urgeCount),
            ("Meeting attendance", $meetingAttendance),
            ("Spiritual practices", $spiritualPractices),
            ("Emotional state", $emotionalState),
            ("Support network contact", $supportContact),
            ("Recovery health rating", $recoveryHealth),
        ]
    }

    private var scores: [Int] {
        Array(checkIns.prefix(7).reversed().map { $0.score })
    }

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var latestScore: Int {
        checkIns.first?.score ?? 0
    }

    private var scoreProgress: Double {
        Double(latestScore) / 100.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score circle
                RRCard {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color.rrPrimary.opacity(0.15), lineWidth: 12)
                                .frame(width: 140, height: 140)
                            Circle()
                                .trim(from: 0, to: scoreProgress)
                                .stroke(Color.rrPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 140, height: 140)
                            VStack(spacing: 2) {
                                Text("\(latestScore)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.rrText)
                                Text("/ 100")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                        Text("Today's Recovery Score")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.horizontal)

                // 7-day sparkline
                if scores.count >= 2 {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RRSectionHeader(title: "7-Day Trend")

                            Chart {
                                ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                                    let label = index < dayLabels.count ? dayLabels[index] : "\(index)"
                                    LineMark(
                                        x: .value("Day", label),
                                        y: .value("Score", score)
                                    )
                                    .foregroundStyle(Color.rrPrimary)
                                    .interpolationMethod(.catmullRom)

                                    PointMark(
                                        x: .value("Day", label),
                                        y: .value("Score", score)
                                    )
                                    .foregroundStyle(Color.rrPrimary)
                                }
                            }
                            .chartYScale(domain: 50...100)
                            .chartYAxis {
                                AxisMarks(position: .leading, values: [50, 75, 100])
                            }
                            .frame(height: 140)
                        }
                    }
                    .padding(.horizontal)
                }

                // Check-in questions
                RRCard {
                    VStack(alignment: .leading, spacing: 20) {
                        RRSectionHeader(title: "Check-in Questions")

                        ForEach(0..<questions.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(questions[index].0)
                                        .font(RRFont.subheadline)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                    Text("\(Int(questions[index].1.wrappedValue))")
                                        .font(RRFont.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.rrPrimary)
                                }
                                Slider(value: questions[index].1, in: 0...100, step: 1)
                                    .tint(Color.rrPrimary)
                            }
                        }

                        RRButton("Submit Check-in", icon: "heart.text.clipboard") {
                            submitCheckIn()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    private func submitCheckIn() {
        let userId = users.first?.id ?? UUID()
        let avgScore = Int((sobrietyStatus + urgeCount + meetingAttendance + spiritualPractices + emotionalState + supportContact + recoveryHealth) / 7.0)
        let checkIn = RRCheckIn(
            userId: userId,
            date: Date(),
            score: avgScore,
            answers: JSONPayload([
                "sobrietyStatus": .int(Int(sobrietyStatus)),
                "urgeCount": .int(Int(urgeCount)),
                "meetingAttendance": .int(Int(meetingAttendance)),
                "spiritualPractices": .int(Int(spiritualPractices)),
                "emotionalState": .int(Int(emotionalState)),
                "supportContact": .int(Int(supportContact)),
                "recoveryHealth": .int(Int(recoveryHealth)),
            ])
        )
        modelContext.insert(checkIn)
    }
}

#Preview {
    NavigationStack {
        RecoveryCheckInView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
