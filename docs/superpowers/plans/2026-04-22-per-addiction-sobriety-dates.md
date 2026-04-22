# Per-Addiction Sobriety Dates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the onboarding `RecoverySetupView` into two screens — `AddictionSetupView` (addiction chips + per-addiction date pickers) and `MotivationSetupView` (motivation chips) — so users can set individual sobriety dates per addiction.

**Architecture:** Extract the existing single-screen `RecoverySetupView` into two new views. `AddictionSetupView` tracks selected addictions as an ordered array of `(name, date)` tuples, defaulting each to today. `MotivationSetupView` is a direct extraction of the motivation chips. `OnboardingFlow` gains one additional page between recovery setup and permissions. `completeSetup()` moves to the motivation screen (last data screen before permissions) and iterates per-addiction dates instead of sharing one.

**Tech Stack:** Swift, SwiftUI, SwiftData

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `Views/Onboarding/AddictionSetupView.swift` | Addiction chip selection + per-addiction date picker rows |
| Create | `Views/Onboarding/MotivationSetupView.swift` | Motivation chip multi-select + `completeSetup()` |
| Modify | `Views/Onboarding/OnboardingFlow.swift` | Add motivation page (tag 3), shift permissions to tag 4 |
| Delete | `Views/Onboarding/RecoverySetupView.swift` | Replaced by the two new views |

No model changes — `RRAddiction` already stores one `sobrietyDate` per addiction.

---

### Task 1: Create AddictionSetupView

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Onboarding/AddictionSetupView.swift`

This view lets users multi-select addiction types and set an individual sobriety date for each. Selected addictions appear as rows below the chips, each defaulting to today's date. The first selected addiction is auto-marked primary.

- [ ] **Step 1: Create AddictionSetupView.swift**

```swift
import SwiftUI

struct AddictionSetupView: View {
    @Binding var selectedAddictions: [(name: String, date: Date)]
    let onNext: () -> Void

    private let addictionTypes = [
        "Sex Addiction (SA)", "Pornography", "Substance Use",
        "Alcohol", "Drugs", "Gambling", "Other"
    ]

    private var selectedNames: Set<String> {
        Set(selectedAddictions.map(\.name))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Recovery")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What are you recovering from?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(addictionTypes, id: \.self) { type in
                            Button {
                                toggleAddiction(type)
                            } label: {
                                Text(type)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedNames.contains(type) ? .white : Color.rrText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedNames.contains(type) ? Color.rrPrimary : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedNames.contains(type) ? Color.clear : Color.rrTextSecondary.opacity(0.4),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }

                if !selectedAddictions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sobriety Dates")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        ForEach(Array(selectedAddictions.enumerated()), id: \.element.name) { index, entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.name)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    if index == 0 {
                                        Text("Primary")
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrPrimary)
                                    }
                                    Spacer()
                                }
                                DatePicker(
                                    "Sobriety date",
                                    selection: Binding(
                                        get: { selectedAddictions[index].date },
                                        set: { selectedAddictions[index].date = $0 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            .padding(12)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                Spacer(minLength: 24)

                RRButton("Continue", icon: "arrow.right") {
                    onNext()
                }
                .disabled(selectedAddictions.isEmpty)
                .opacity(selectedAddictions.isEmpty ? 0.5 : 1)
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }

    private func toggleAddiction(_ name: String) {
        if let idx = selectedAddictions.firstIndex(where: { $0.name == name }) {
            selectedAddictions.remove(at: idx)
        } else {
            selectedAddictions.append((name: name, date: Date()))
        }
    }
}

#Preview {
    AddictionSetupView(
        selectedAddictions: .constant([
            (name: "Sex Addiction (SA)", date: Date()),
            (name: "Pornography", date: Date())
        ]),
        onNext: {}
    )
}
```

- [ ] **Step 2: Build in Xcode to verify no compile errors**

Run: Cmd+B in Xcode
Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Onboarding/AddictionSetupView.swift
git commit -m "feat(ios): add AddictionSetupView with per-addiction date pickers"
```

---

### Task 2: Create MotivationSetupView

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Onboarding/MotivationSetupView.swift`

Extracts the motivation chip grid from `RecoverySetupView` into its own screen. This view also runs `completeSetup()` since it's the last data-collection screen before permissions.

- [ ] **Step 1: Create MotivationSetupView.swift**

```swift
import SwiftUI
import SwiftData

struct MotivationSetupView: View {
    let name: String
    let email: String
    let selectedAddictions: [(name: String, date: Date)]
    let onNext: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var selectedMotivations: Set<String> = ["Faith", "Family", "Freedom"]

    private static let motivations = [
        "Faith", "Family", "Freedom", "Health", "Honesty",
        "Hope", "Integrity", "Intimacy", "Joy", "Love",
        "Marriage", "Peace", "Purpose", "Self-Respect", "Sobriety",
        "Spirituality", "Trust", "Wholeness"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Motivations")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What motivates your recovery?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(Self.motivations, id: \.self) { motivation in
                            Button {
                                if selectedMotivations.contains(motivation) {
                                    selectedMotivations.remove(motivation)
                                } else {
                                    selectedMotivations.insert(motivation)
                                }
                            } label: {
                                Text(motivation)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedMotivations.contains(motivation) ? .white : Color.rrText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedMotivations.contains(motivation) ? Color.rrPrimary : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedMotivations.contains(motivation) ? Color.clear : Color.rrTextSecondary.opacity(0.4),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }

                Spacer(minLength: 24)

                RRButton("Continue", icon: "arrow.right") {
                    completeSetup()
                    onNext()
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }

    private func completeSetup() {
        let user = RRUser(
            name: name,
            email: email,
            birthYear: 0,
            gender: "",
            timezone: TimeZone.current.identifier,
            bibleVersion: "ESV",
            motivations: Array(selectedMotivations),
            avatarInitial: String(name.prefix(1).uppercased())
        )
        modelContext.insert(user)

        for (index, entry) in selectedAddictions.enumerated() {
            let addiction = RRAddiction(
                name: entry.name,
                sobrietyDate: entry.date,
                userId: user.id,
                sortOrder: index
            )
            modelContext.insert(addiction)

            let streak = RRStreak(addictionId: addiction.id)
            modelContext.insert(streak)
        }
    }
}

#Preview {
    MotivationSetupView(
        name: "Alex",
        email: "alex@example.com",
        selectedAddictions: [
            (name: "Sex Addiction (SA)", date: Date()),
            (name: "Pornography", date: Date())
        ],
        onNext: {}
    )
}
```

- [ ] **Step 2: Build in Xcode to verify no compile errors**

Run: Cmd+B in Xcode
Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Onboarding/MotivationSetupView.swift
git commit -m "feat(ios): add MotivationSetupView with chip grid and completeSetup"
```

---

### Task 3: Update OnboardingFlow and remove RecoverySetupView

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Onboarding/OnboardingFlow.swift`
- Delete: `ios/RegalRecovery/RegalRecovery/Views/Onboarding/RecoverySetupView.swift`

Wire the two new views into the flow. The page order becomes: Welcome (0) → Account (1) → AddictionSetup (2) → MotivationSetup (3) → Permissions (4). Add `@State` for `selectedAddictions` array. Delete the old combined view.

- [ ] **Step 1: Update OnboardingFlow.swift**

Replace the entire file contents with:

```swift
import SwiftUI

struct OnboardingFlow: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var selectedAddictions: [(name: String, date: Date)] = [
        (name: "Sex Addiction (SA)", date: Date()),
        (name: "Pornography", date: Date())
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                WelcomeView {
                    withAnimation { currentPage = 1 }
                }
                .tag(0)

                AccountSetupView(name: $userName, email: $userEmail) {
                    withAnimation { currentPage = 2 }
                }
                .tag(1)

                AddictionSetupView(selectedAddictions: $selectedAddictions) {
                    withAnimation { currentPage = 3 }
                }
                .tag(2)

                MotivationSetupView(
                    name: userName,
                    email: userEmail,
                    selectedAddictions: selectedAddictions
                ) {
                    withAnimation { currentPage = 4 }
                }
                .tag(3)

                PermissionsView(onComplete: onComplete)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                onComplete()
            } label: {
                Text("Skip to Demo")
                    .font(RRFont.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.rrSurface)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }
}

#Preview {
    OnboardingFlow(onComplete: {})
}
```

- [ ] **Step 2: Delete RecoverySetupView.swift**

```bash
git rm ios/RegalRecovery/RegalRecovery/Views/Onboarding/RecoverySetupView.swift
```

- [ ] **Step 3: Remove RecoverySetupView.swift from Xcode project if needed**

If the project uses file references in `project.pbxproj`, Xcode will show a missing file warning. Open the project navigator and confirm the file is gone. The two new files should be added to the project (drag into Onboarding group or via File → Add Files).

- [ ] **Step 4: Build in Xcode to verify no compile errors**

Run: Cmd+B in Xcode
Expected: Build succeeds. No references to `RecoverySetupView` remain.

- [ ] **Step 5: Run the app in simulator and walk through onboarding**

Verify:
1. Welcome → Account → Addiction Setup → Motivation → Permissions flow works
2. Selecting/deselecting addiction chips adds/removes rows with date pickers
3. Each addiction row has its own date picker defaulting to today
4. First selected addiction shows "Primary" label
5. Changing a date on one addiction doesn't affect others
6. Motivation screen shows chip grid, "Continue" saves data and advances
7. Page indicator dots show 5 pages
8. "Skip to Demo" still works from any page

- [ ] **Step 6: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Onboarding/OnboardingFlow.swift
git commit -m "feat(ios): wire AddictionSetup + MotivationSetup into onboarding flow

Split RecoverySetupView into two screens so users can set individual
sobriety dates per addiction during onboarding."
```
