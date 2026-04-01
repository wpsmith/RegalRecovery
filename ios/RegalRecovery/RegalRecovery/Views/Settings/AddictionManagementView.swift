import SwiftData
import SwiftUI

struct AddictionManagementView: View {
    @Query private var addictions: [RRAddiction]
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false

    var body: some View {
        Form {
            if addictions.isEmpty {
                Section {
                    Text("No addictions configured")
                        .foregroundStyle(Color.rrTextSecondary)
                }
            } else {
                ForEach(addictions) { addiction in
                    Section {
                        // Addiction name + badge
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(Color.rrPrimary)
                            Text(addiction.name)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                        }

                        // Per-addiction sobriety date
                        DatePicker(
                            "Sobriety Date",
                            selection: Binding(
                                get: { addiction.sobrietyDate },
                                set: { newDate in
                                    addiction.sobrietyDate = newDate
                                    addiction.modifiedAt = Date()
                                }
                            ),
                            displayedComponents: .date
                        )

                        // Per-addiction streak
                        let streak = streaks.first(where: { $0.addictionId == addiction.id })
                        HStack {
                            Text("Current Streak")
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Text("\(streak?.currentDays ?? 0) days")
                                .font(RRFont.body.weight(.semibold))
                                .foregroundStyle(Color.rrSuccess)
                        }

                        HStack {
                            Text("Longest Streak")
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Text("\(streak?.longestStreak ?? 0) days")
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        HStack {
                            Text("Total Relapses")
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Text("\(streak?.totalRelapses ?? 0)")
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    } header: {
                        Text(addiction.name)
                    }
                }
                .onDelete(perform: deleteAddictions)
            }

            Section {
                Button {
                    showAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.rrPrimary)
                        Text("Add Addiction")
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }

            Section {
            } footer: {
                Text("SA sobriety is defined as no sex with self and no sex with anyone other than spouse. Each addiction tracks its own sobriety date and streak independently.")
                    .font(RRFont.caption)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAddictionSheet { name, date in
                addAddiction(name: name, sobrietyDate: date)
            }
        }
    }

    private func addAddiction(name: String, sobrietyDate: Date) {
        let userId = users.first?.id ?? UUID()
        let addiction = RRAddiction(name: name, sobrietyDate: sobrietyDate, userId: userId)
        modelContext.insert(addiction)
        let streak = RRStreak(addictionId: addiction.id)
        modelContext.insert(streak)
    }

    private func deleteAddictions(at offsets: IndexSet) {
        for index in offsets {
            let addiction = addictions[index]
            // Also delete associated streak
            if let streak = streaks.first(where: { $0.addictionId == addiction.id }) {
                modelContext.delete(streak)
            }
            modelContext.delete(addiction)
        }
    }
}

// MARK: - Add Addiction Sheet

struct AddAddictionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, Date) -> Void

    @State private var name = ""
    @State private var sobrietyDate = Date()

    private let types = ["Sex Addiction (SA)", "Pornography", "Substance Use", "Alcohol", "Drugs", "Gambling", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $name) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section {
                    DatePicker("Sobriety Date", selection: $sobrietyDate, displayedComponents: .date)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.isEmpty else { return }
                        onSave(name, sobrietyDate)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddictionManagementView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
