import SwiftData
import SwiftUI

extension RRAddiction {
    var displayColor: Color {
        let hex = colorHex ?? Self.defaultColors[sortOrder % Self.defaultColors.count]
        return Self.colorFromHex(hex)
    }

    static func colorFromHex(_ hex: String) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard h.count == 6, let int = UInt64(h, radix: 16) else { return .blue }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}

struct AddictionManagementView: View {
    @Query(sort: \RRAddiction.name) private var addictions: [RRAddiction]
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var editMode: EditMode = .active
    @State private var expandedAddictionIds: Set<UUID> = []

    var body: some View {
        List {
            if addictions.isEmpty {
                Section {
                    Text("No addictions configured")
                        .foregroundStyle(Color.rrTextSecondary)
                }
            } else {
                Section {
                    ForEach(addictions) { addiction in
                        addictionRow(addiction)
                    }
                    .onDelete { offsets in
                        deleteAddictions(at: offsets)
                    }
                    .onMove { source, destination in
                        moveAddictions(from: source, to: destination)
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

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .foregroundStyle(Color.rrText)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(RRAddiction.defaultColors, id: \.self) { hex in
                        let color = RRAddiction.colorFromHex(hex)
                        let isSelected = addiction.colorHex == hex ||
                            (addiction.colorHex == nil && hex == RRAddiction.defaultColors[addiction.sortOrder % RRAddiction.defaultColors.count])
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.6), lineWidth: isSelected ? 1 : 0)
                                    .padding(-1)
                            )
                            .onTapGesture {
                                addiction.colorHex = hex
                                addiction.modifiedAt = Date()
                            }
                    }
                }
            }
            .moveDisabled(true)
            .deleteDisabled(true)
        } label: {
            HStack {
                Circle()
                    .fill(addiction.displayColor)
                    .frame(width: 10, height: 10)
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

    private func deleteAddictions(at offsets: IndexSet) {
        for index in offsets {
            let addiction = addictions[index]
            if let streak = streaks.first(where: { $0.addictionId == addiction.id }) {
                modelContext.delete(streak)
            }
            modelContext.delete(addiction)
        }
    }

    private func moveAddictions(from source: IndexSet, to destination: Int) {
        var reordered = Array(addictions)
        reordered.move(fromOffsets: source, toOffset: destination)
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

    private let allAddictions = [
        "Affair / Infidelity",
        "Alcohol",
        "Amphetamines",
        "Anonymous Sex",
        "Benzodiazepines",
        "Caffeine",
        "Cannabis / Marijuana",
        "Cocaine",
        "Codependency",
        "Compulsive Sexual Behavior",
        "Cybersex",
        "Eating / Food",
        "Exercise (Compulsive)",
        "Exhibitionism",
        "Fantasy",
        "Fetish Behavior",
        "Gambling",
        "Gaming",
        "Heroin / Opioids",
        "Inhalants",
        "Internet / Social Media",
        "Ketamine",
        "LSD / Psychedelics",
        "Love / Relationship",
        "Masturbation",
        "MDMA / Ecstasy",
        "Methamphetamine",
        "Nicotine / Tobacco",
        "Phone Sex / Sexting",
        "Pornography",
        "Prescription Drugs",
        "Sex",
        "Sex Buying",
        "Sexual Fantasy",
        "Sexual Massage",
        "Shopping / Spending",
        "Steroids",
        "Strip Clubs",
        "Synthetic Drugs",
        "Voyeurism",
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
                        ForEach(allAddictions, id: \.self) { type in
                            Text(type).tag(type)
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
