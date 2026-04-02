import SwiftUI
import SwiftData

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

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
