import SwiftUI
import SwiftData

struct BowtieSessionView: View {
    var relapseTimestamp: Date?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRKnownEmotionalTrigger.createdAt) private var triggers: [RRKnownEmotionalTrigger]

    @State private var viewModel = BowtieSessionViewModel()
    @State private var selectedTab: BowtieSide? = nil
    @State private var showMarkerForm = false
    @State private var editingMarker: RRBowtieMarker?
    @State private var pendingMarkerSide: BowtieSide = .past
    @State private var pendingMarkerInterval: Int?
    @State private var showDeleteConfirmation = false
    @State private var showOnboarding = !BowtieOnboardingViewModel.isOnboardingCompleted
    @State private var showVocabularyInfo = false
    @State private var showModeInfo = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rrBackground.ignoresSafeArea()

                if viewModel.showSetup {
                    setupView
                } else {
                    sessionContentView
                }

                if viewModel.showCompletion {
                    BowtieCompletionOverlay {
                        viewModel.showCompletion = false
                        dismiss()
                    }
                }
            }
            .navigationTitle(String(localized: "Bowtie Analysis"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) {
                        dismiss()
                    }
                }

                if !viewModel.showSetup {
                    ToolbarItem(placement: .primaryAction) {
                        Button(String(localized: "Complete")) {
                            viewModel.completeSession(
                                context: modelContext,
                                userId: users.first?.id ?? UUID()
                            )
                        }
                        .disabled(viewModel.markers.isEmpty)
                    }

                    ToolbarItem(placement: .destructiveAction) {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label(String(localized: "Delete Draft"), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMarkerForm) {
                BowtieMarkerFormView(
                    vocabulary: viewModel.selectedVocabulary,
                    availableRoles: selectedRolesFromAvailable,
                    availableTriggers: triggers,
                    existingMarker: editingMarker,
                    preselectedSide: editingMarker == nil ? pendingMarkerSide : nil,
                    preselectedTimeInterval: editingMarker == nil ? pendingMarkerInterval : nil
                ) { marker in
                    if let editing = editingMarker {
                        viewModel.removeMarker(editing, context: modelContext)
                    }
                    viewModel.addMarker(marker, context: modelContext)
                    editingMarker = nil
                    pendingMarkerInterval = nil
                }
            }
            .confirmationDialog(
                String(localized: "Delete this draft session?"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Delete Draft"), role: .destructive) {
                    viewModel.deleteSession(context: modelContext)
                }
            }
            .onAppear {
                viewModel.loadRoles(context: modelContext)
                viewModel.checkForDraft(context: modelContext)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                BowtieOnboardingView()
                    .onDisappear {
                        viewModel.loadRoles(context: modelContext)
                    }
            }
        }
    }

    // MARK: - Selected Roles Helper

    private var selectedRolesFromAvailable: [RRUserRole] {
        viewModel.availableRoles.filter { viewModel.selectedRoleIds.contains($0.id) }
    }

    // MARK: - Setup View

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Role Picker
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Select Roles"))
                            .font(.headline)
                            .foregroundStyle(Color.rrText)

                        Text(String(localized: "Which roles are you reflecting on?"))
                            .font(.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)

                        if viewModel.availableRoles.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "Tap roles to add them:"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.rrTextSecondary)
                                FlowLayout(spacing: 8) {
                                    ForEach(RoleSuggestions.defaults, id: \.self) { suggestion in
                                        Button {
                                            let role = RRUserRole(label: suggestion, sortOrder: viewModel.availableRoles.count)
                                            modelContext.insert(role)
                                            viewModel.loadRoles(context: modelContext)
                                            viewModel.selectedRoleIds.insert(role.id)
                                        } label: {
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.rrSurface)
                                                .foregroundStyle(Color.rrText)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        } else {
                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.availableRoles, id: \.id) { role in
                                    roleChip(role)
                                }
                            }
                        }
                    }
                }

                // Vocabulary Picker
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(String(localized: "Emotion Vocabulary"))
                                .font(.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Button {
                                showVocabularyInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            .accessibilityLabel(String(localized: "Emotion vocabulary info"))
                        }

                        Picker(String(localized: "Vocabulary"), selection: $viewModel.selectedVocabulary) {
                            ForEach(EmotionVocabulary.allCases, id: \.rawValue) { vocab in
                                Text(vocab.displayName).tag(vocab)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .alert(String(localized: "Emotion Vocabulary"), isPresented: $showVocabularyInfo) {
                    Button(String(localized: "OK"), role: .cancel) {}
                } message: {
                    Text(String(localized: "Three I's: Insignificance, Incompetence, and Impotence \u{2014} the three core emotional wounds that drive addictive cycles.\n\nBig Ticket Emotions: Five common emotions that lead to acting out: Abandonment, Loneliness, Rejection, Sorrow, and Neglect.\n\nCombined: Use both the Three I's and Big Ticket Emotions together for deeper analysis."))
                }

                // Mode Toggle
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(String(localized: "Session Mode"))
                                .font(.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Button {
                                showModeInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            .accessibilityLabel(String(localized: "Session mode info"))
                        }

                        Picker(String(localized: "Mode"), selection: $viewModel.selectedMode) {
                            ForEach(BowtieSessionMode.allCases, id: \.rawValue) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .alert(String(localized: "Session Mode"), isPresented: $showModeInfo) {
                    Button(String(localized: "OK"), role: .cancel) {}
                } message: {
                    Text(String(localized: "Guided: Walks you through each role one at a time, asking what has stirred in the last 48 hours and what's coming. Best for learning the tool.\n\nFreeform: Opens the full Bowtie for self-directed use. Best once you're familiar with the process."))
                }

                // Start Button
                Button {
                    let entryPath: BowtieEntryPath = relapseTimestamp != nil ? .postRelapse : .activities
                    viewModel.createSession(
                        entryPath: entryPath,
                        referenceTimestamp: relapseTimestamp ?? Date(),
                        context: modelContext
                    )
                } label: {
                    Text(String(localized: "Start Session"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(viewModel.selectedRoleIds.isEmpty)
                .opacity(viewModel.selectedRoleIds.isEmpty ? 0.5 : 1.0)
            }
            .padding()
        }
    }

    private func roleChip(_ role: RRUserRole) -> some View {
        let isSelected = viewModel.selectedRoleIds.contains(role.id)
        return Button {
            if isSelected {
                viewModel.selectedRoleIds.remove(role.id)
            } else {
                viewModel.selectedRoleIds.insert(role.id)
            }
        } label: {
            Text(role.label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.rrPrimary.opacity(0.2) : Color.rrSurface)
                .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrText)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.rrPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(role.label)
        .accessibilityHint(isSelected ? String(localized: "Double tap to deselect") : String(localized: "Double tap to select"))
    }

    // MARK: - Session Content View

    private var sessionContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if sizeClass == .regular {
                    BowtieDiagramView(
                        markers: viewModel.markers,
                        onTapInterval: { side, interval in
                            editingMarker = nil
                            pendingMarkerSide = side
                            pendingMarkerInterval = interval
                            showMarkerForm = true
                        },
                        onTapMarker: { marker in
                            editingMarker = marker
                            pendingMarkerSide = marker.bowtieSide
                            showMarkerForm = true
                        }
                    )
                    .padding(.horizontal)
                }

                Picker(String(localized: "Side"), selection: $selectedTab) {
                    Text(String(localized: "Past")).tag(BowtieSide?.some(.past))
                    Text(String(localized: "All")).tag(BowtieSide?.none)
                    Text(String(localized: "Future")).tag(BowtieSide?.some(.future))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                BowtieTalliesCard(
                    pastInsignificance: viewModel.pastInsignificance,
                    pastIncompetence: viewModel.pastIncompetence,
                    pastImpotence: viewModel.pastImpotence,
                    futureInsignificance: viewModel.futureInsignificance,
                    futureIncompetence: viewModel.futureIncompetence,
                    futureImpotence: viewModel.futureImpotence
                )

                if selectedTab == nil || selectedTab == .past {
                    bowtieListEntry(side: .past, markers: viewModel.pastMarkers)
                }

                if selectedTab == nil || selectedTab == .future {
                    bowtieListEntry(side: .future, markers: viewModel.futureMarkers)
                }
            }
            .padding()
        }
    }

    private func bowtieListEntry(side: BowtieSide, markers: [RRBowtieMarker]) -> some View {
        BowtieListEntryView(
            markers: markers,
            side: side,
            roleIds: Array(viewModel.selectedRoleIds),
            roles: viewModel.availableRoles,
            vocabulary: viewModel.selectedVocabulary,
            onAddMarker: { timeInterval in
                editingMarker = nil
                pendingMarkerSide = side
                pendingMarkerInterval = timeInterval
                showMarkerForm = true
            },
            onEditMarker: { marker in
                editingMarker = marker
                pendingMarkerSide = side
                showMarkerForm = true
            },
            onDeleteMarker: { marker in
                viewModel.removeMarker(marker, context: modelContext)
            },
            onProcessMarker: { _ in
                // Processing handled in a later task
            }
        )
    }
}
