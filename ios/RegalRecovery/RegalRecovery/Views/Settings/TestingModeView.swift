import SwiftUI
import SwiftData

struct TestingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var showEraseTodayConfirm = false
    @State private var showEraseAllConfirm = false
    @State private var showReseedConfirm = false
    @State private var statusMessage: String?

    var body: some View {
        List {
            // MARK: - Erase Today's Data
            Section {
                Button {
                    showEraseTodayConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Erase Today's Data")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            Text("Remove all activity logs, check-ins, moods, and commitments from today. Useful for re-testing the Today view.")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                }
            } header: {
                Text("Today's Data")
            }

            // MARK: - Erase All Data
            Section {
                Button(role: .destructive) {
                    showEraseAllConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(Color.rrDestructive)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Erase All Data")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrDestructive)
                            Text("Delete everything — user profile, streaks, activities, plan, scores. Returns to first-launch state.")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                }

                Button {
                    showReseedConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundStyle(Color.rrPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reseed Alex's Data")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            Text("Erase everything and repopulate with Alex's 270-day demo data.")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                }
            } header: {
                Text("Full Reset")
            } footer: {
                Text("These actions cannot be undone.")
            }

            // MARK: - Status
            if let statusMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.rrSuccess)
                        Text(statusMessage)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .confirmationDialog("Erase Today's Data?", isPresented: $showEraseTodayConfirm, titleVisibility: .visible) {
            Button("Erase Today", role: .destructive) {
                eraseTodaysData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all check-ins, moods, prayers, exercises, journals, commitments, and other activity logs from today.")
        }
        .confirmationDialog("Erase All Data?", isPresented: $showEraseAllConfirm, titleVisibility: .visible) {
            Button("Erase Everything", role: .destructive) {
                eraseAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes all user data, streaks, activities, and settings. The app will return to first-launch state.")
        }
        .confirmationDialog("Reseed Demo Data?", isPresented: $showReseedConfirm, titleVisibility: .visible) {
            Button("Erase & Reseed", role: .destructive) {
                reseedData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This erases all data and repopulates with Alex's 270-day demo dataset.")
        }
    }

    // MARK: - Erase Today

    private func eraseTodaysData() {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        deleteCheckIns(from: todayStart)
        deleteMoodEntries(from: todayStart)
        deletePrayerLogs(from: todayStart)
        deleteExerciseLogs(from: todayStart)
        deleteFASTEREntries(from: todayStart)
        deleteGratitudeEntries(from: todayStart)
        deleteJournalEntries(from: todayStart)
        deleteEmotionalJournals(from: todayStart)
        deleteTimeBlocks(from: todayStart)
        deleteUrgeLogs(from: todayStart)
        deletePhoneCallLogs(from: todayStart)
        deleteMeetingLogs(from: todayStart)
        deleteCommitments(from: todayStart)
        deleteActivities(from: todayStart)
        deleteDailyScores(from: todayStart)

        statusMessage = "Today's data erased"
    }

    private func deleteCheckIns(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRCheckIn>(
            predicate: #Predicate<RRCheckIn> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteMoodEntries(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRMoodEntry>(
            predicate: #Predicate<RRMoodEntry> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deletePrayerLogs(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRPrayerLog>(
            predicate: #Predicate<RRPrayerLog> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteExerciseLogs(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRExerciseLog>(
            predicate: #Predicate<RRExerciseLog> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteFASTEREntries(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRFASTEREntry>(
            predicate: #Predicate<RRFASTEREntry> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteGratitudeEntries(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRGratitudeEntry>(
            predicate: #Predicate<RRGratitudeEntry> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteJournalEntries(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRJournalEntry>(
            predicate: #Predicate<RRJournalEntry> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteEmotionalJournals(from todayStart: Date) {
        let descriptor = FetchDescriptor<RREmotionalJournal>(
            predicate: #Predicate<RREmotionalJournal> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteTimeBlocks(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRTimeBlock>(
            predicate: #Predicate<RRTimeBlock> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteUrgeLogs(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRUrgeLog>(
            predicate: #Predicate<RRUrgeLog> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deletePhoneCallLogs(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRPhoneCallLog>(
            predicate: #Predicate<RRPhoneCallLog> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteMeetingLogs(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRMeetingLog>(
            predicate: #Predicate<RRMeetingLog> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteCommitments(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRCommitment>(
            predicate: #Predicate<RRCommitment> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteActivities(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRActivity>(
            predicate: #Predicate<RRActivity> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    private func deleteDailyScores(from todayStart: Date) {
        let descriptor = FetchDescriptor<RRDailyScore>(
            predicate: #Predicate<RRDailyScore> { $0.date >= todayStart }
        )
        if let items = try? modelContext.fetch(descriptor) {
            for item in items { modelContext.delete(item) }
        }
    }

    // MARK: - Erase All

    private func eraseAllData() {
        do {
            try modelContext.delete(model: RRUser.self)
            try modelContext.delete(model: RRAddiction.self)
            try modelContext.delete(model: RRStreak.self)
            try modelContext.delete(model: RRMilestone.self)
            try modelContext.delete(model: RRRelapse.self)
            try modelContext.delete(model: RRActivity.self)
            try modelContext.delete(model: RRCheckIn.self)
            try modelContext.delete(model: RRMoodEntry.self)
            try modelContext.delete(model: RRPrayerLog.self)
            try modelContext.delete(model: RRExerciseLog.self)
            try modelContext.delete(model: RRFASTEREntry.self)
            try modelContext.delete(model: RRGratitudeEntry.self)
            try modelContext.delete(model: RRJournalEntry.self)
            try modelContext.delete(model: RREmotionalJournal.self)
            try modelContext.delete(model: RRTimeBlock.self)
            try modelContext.delete(model: RRUrgeLog.self)
            try modelContext.delete(model: RRPhoneCallLog.self)
            try modelContext.delete(model: RRMeetingLog.self)
            try modelContext.delete(model: RRCommitment.self)
            try modelContext.delete(model: RRSpouseCheckIn.self)
            try modelContext.delete(model: RRStepWork.self)
            try modelContext.delete(model: RRGoal.self)
            try modelContext.delete(model: RRSupportContact.self)
            try modelContext.delete(model: RRFeatureFlag.self)
            try modelContext.delete(model: RRAffirmationFavorite.self)
            try modelContext.delete(model: RRDevotionalProgress.self)
            try modelContext.delete(model: RRRecoveryPlan.self)
            try modelContext.delete(model: RRDailyPlanItem.self)
            try modelContext.delete(model: RRDailyScore.self)
            try modelContext.delete(model: RRSyncQueueItem.self)

            UserDefaults.standard.removeObject(forKey: "hasSeededDatabase")
            statusMessage = "All data erased. Restart app for first-launch experience."
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Reseed

    private func reseedData() {
        eraseAllData()
        statusMessage = nil

        do {
            try SeedData.seedDatabase(context: modelContext)
            SeedData.markSeeded()
            statusMessage = "Data reseeded with Alex's 270-day demo data"
        } catch {
            statusMessage = "Reseed error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        TestingModeView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
