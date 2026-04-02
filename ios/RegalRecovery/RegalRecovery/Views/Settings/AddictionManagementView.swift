import SwiftData
import SwiftUI

struct AddictionManagementView: View {
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var editMode: EditMode = .active
    @State private var expandedAddictionIds: Set<UUID> = []

    private let sexualAddictionNames: Set<String> = [
        "Sex", "Pornography", "Compulsive Sexual Behavior", "Cybersex",
        "Exhibitionism", "Voyeurism", "Sex Buying", "Anonymous Sex",
        "Affair / Infidelity", "Phone Sex / Sexting", "Sexual Fantasy",
        "Masturbation", "Strip Clubs", "Fetish Behavior", "Sexual Massage",
        "Love / Relationship",
    ]

    private var sexAddictions: [RRAddiction] {
        addictions.filter { sexualAddictionNames.contains($0.name) }
    }

    private var otherAddictions: [RRAddiction] {
        addictions.filter { !sexualAddictionNames.contains($0.name) }
    }

    var body: some View {
        List {
            if addictions.isEmpty {
                Section {
                    Text("No addictions configured")
                        .foregroundStyle(Color.rrTextSecondary)
                }
            } else {
                if !sexAddictions.isEmpty {
                    Section("Sex Addictions") {
                        Text("SA sobriety is defined as no sex with self and no sex with anyone other than your spouse. Any form of sex with yourself or outside of your marriage is a break in sobriety.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .padding(.vertical, 4)
                            .moveDisabled(true)
                            .deleteDisabled(true)

                        ForEach(sexAddictions) { addiction in
                            addictionRow(addiction)
                        }
                        .onDelete { offsets in
                            deleteAddictions(at: offsets, in: sexAddictions)
                        }
                        .onMove { source, destination in
                            moveAddictions(from: source, to: destination, in: sexAddictions)
                        }
                    }
                }

                if !otherAddictions.isEmpty {
                    Section("Other Addictions") {
                        ForEach(otherAddictions) { addiction in
                            addictionRow(addiction)
                        }
                        .onDelete { offsets in
                            deleteAddictions(at: offsets, in: otherAddictions)
                        }
                        .onMove { source, destination in
                            moveAddictions(from: source, to: destination, in: otherAddictions)
                        }
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAddictionSheet { name, date in
                addAddiction(name: name, sobrietyDate: date)
            }
        }
        .navigationTitle("Addictions")
    }

    @ViewBuilder
    private func addictionRow(_ addiction: RRAddiction) -> some View {
        let isExpanded = Binding<Bool>(
            get: { expandedAddictionIds.contains(addiction.id) },
            set: { newValue in
                if newValue {
                    expandedAddictionIds.insert(addiction.id)
                } else {
                    expandedAddictionIds.remove(addiction.id)
                }
            }
        )

        DisclosureGroup(isExpanded: isExpanded) {
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
            .moveDisabled(true)
            .deleteDisabled(true)

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
            .moveDisabled(true)
            .deleteDisabled(true)

            HStack {
                Text("Longest Streak")
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(streak?.longestStreak ?? 0) days")
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .moveDisabled(true)
            .deleteDisabled(true)

            HStack {
                Text("Total Relapses")
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(streak?.totalRelapses ?? 0)")
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .moveDisabled(true)
            .deleteDisabled(true)
        } label: {
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(Color.rrPrimary)
                Text(addiction.name)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
            }
        }
    }

    private func addAddiction(name: String, sobrietyDate: Date) {
        let userId = users.first?.id ?? UUID()
        let nextOrder = (addictions.map(\.sortOrder).max() ?? -1) + 1
        let addiction = RRAddiction(name: name, sobrietyDate: sobrietyDate, userId: userId, sortOrder: nextOrder)
        modelContext.insert(addiction)
        let streak = RRStreak(addictionId: addiction.id)
        modelContext.insert(streak)
    }

    private func deleteAddictions(at offsets: IndexSet, in subset: [RRAddiction]) {
        for index in offsets {
            let addiction = subset[index]
            if let streak = streaks.first(where: { $0.addictionId == addiction.id }) {
                modelContext.delete(streak)
            }
            modelContext.delete(addiction)
        }
    }

    private func moveAddictions(from source: IndexSet, to destination: Int, in subset: [RRAddiction]) {
        var reordered = subset
        reordered.move(fromOffsets: source, toOffset: destination)
        // Update sort orders across all addictions in this subset
        for (index, addiction) in reordered.enumerated() {
            addiction.sortOrder = index
            addiction.modifiedAt = Date()
        }
    }
}

// MARK: - Add Addiction Sheet

struct AddAddictionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, Date) -> Void

    @State private var selectedType = ""
    @State private var customAddictionName = ""
    @State private var sobrietyDate = Date()

    private let sexualAddictions = [
        "Affair / Infidelity",
        "Anonymous Sex",
        "Compulsive Sexual Behavior",
        "Cybersex",
        "Exhibitionism",
        "Fetish Behavior",
        "Love / Relationship",
        "Masturbation",
        "Phone Sex / Sexting",
        "Pornography",
        "Sex",
        "Sex Buying",
        "Sexual Fantasy",
        "Sexual Massage",
        "Strip Clubs",
        "Voyeurism",
    ]

    private let otherAddictions = [
        "Alcohol",
        "Amphetamines",
        "Benzodiazepines",
        "Caffeine",
        "Cannabis / Marijuana",
        "Cocaine",
        "Codependency",
        "Eating / Food",
        "Exercise (Compulsive)",
        "Fantasy",
        "Gambling",
        "Gaming",
        "Heroin / Opioids",
        "Inhalants",
        "Internet / Social Media",
        "Ketamine",
        "LSD / Psychedelics",
        "MDMA / Ecstasy",
        "Methamphetamine",
        "Nicotine / Tobacco",
        "Prescription Drugs",
        "Shopping / Spending",
        "Steroids",
        "Synthetic Drugs",
        "Work",
        "Other",
    ]

    private var resolvedName: String {
        if selectedType == "Other" {
            return customAddictionName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedType
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        Text("Select a type").tag("")

                        Section("Sexual Addictions") {
                            ForEach(sexualAddictions, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }

                        Section("Other Addictions") {
                            ForEach(otherAddictions, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                }

                if selectedType == "Other" {
                    Section {
                        TextField("Custom addiction name", text: $customAddictionName)
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
                        guard !resolvedName.isEmpty else { return }
                        onSave(resolvedName, sobrietyDate)
                        dismiss()
                    }
                    .disabled(resolvedName.isEmpty)
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
