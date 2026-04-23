import SwiftUI

struct ActivityDestinationView: View {
    let activityType: String

    var body: some View {
        switch activityType {
        case ActivityType.sobrietyCommitment.rawValue:
            MorningCommitmentView()
        case ActivityType.prayer.rawValue:
            PrayerLogView()
        case ActivityType.exercise.rawValue:
            ExerciseLogView()
        case ActivityType.journal.rawValue:
            JournalView()
        case ActivityType.mood.rawValue:
            MoodRatingView()
        case ActivityType.gratitude.rawValue:
            GratitudeTabView()
        case ActivityType.fasterScale.rawValue:
            FASTERScaleView()
        case "devotional":
            DevotionalView()
        case ActivityType.affirmationLog.rawValue:
            if let packName = AffirmationSettingsManager.shared.packForToday(),
               let pack = ContentData.affirmationPacks.first(where: { $0.name == packName }) {
                AffirmationDeckView(packName: pack.name, affirmations: pack.affirmations)
            } else {
                AffirmationPackPickerView()
            }
        case ActivityType.phoneCalls.rawValue:
            PhoneCallLogView()
        case ActivityType.meetingsAttended.rawValue:
            MeetingsAttendedView()
        case ActivityType.fanos.rawValue:
            FANOSCheckInView()
        case ActivityType.fitnap.rawValue:
            FITNAPCheckInView()
        case "lbiFoundation":
            LBIFoundationView()
        case "lbi":
            LBIEntryPointView()
        case ActivityType.weeklyGoals.rawValue:
            WeeklyGoalsView()
        case ActivityType.stepWork.rawValue:
            StepWorkView()
        case ActivityType.timeJournal.rawValue:
            TimeJournalDailyView()
        case ActivityType.postMortem.rawValue:
            PostMortemView()
        case ActivityType.urgeLog.rawValue:
            UrgeLogView()
        case "emotionalJournal":
            EmotionalJournalView()
        default:
            Text("Activity")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }
}
