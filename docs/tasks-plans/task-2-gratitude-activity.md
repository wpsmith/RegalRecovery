# Task 2: Gratitude Activity — Custom Tags and Pre-Entry Prompt

## Feature 1: Custom Tag Names

### Problem

The `GratitudeCategory` enum (`GratitudeTypes.swift` lines 6-49) has a `.custom` case with `rawValue: "Custom"`, but there is no mechanism for the user to supply a name for the custom tag. The `GratitudeItem` struct (lines 91-97) stores `category: GratitudeCategory?` but has no field for a custom tag name. When `.custom` is selected, it just displays "Custom".

### Implementation

#### Step 1: Update `GratitudeItem` model

**File:** `ios/.../Models/GratitudeTypes.swift` (lines 91-97)

Add `customTagName` property and computed display name:

```swift
struct GratitudeItem: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var category: GratitudeCategory?
    var customTagName: String?
    var isFavorite: Bool = false
    var sortOrder: Int

    var displayCategoryName: String? {
        guard let category else { return nil }
        if category == .custom {
            return customTagName?.isEmpty == false ? customTagName : category.rawValue
        }
        return category.rawValue
    }
}
```

Backward-compatible: existing data decodes `customTagName` as `nil`.

#### Step 2: Update `GratitudeItemDraft`

**File:** `ios/.../ViewModels/GratitudeEntryViewModel.swift` (lines 7-11)

```swift
struct GratitudeItemDraft: Identifiable {
    let id: UUID = UUID()
    var text: String = ""
    var category: GratitudeCategory?
    var customTagName: String = ""
}
```

#### Step 3: Update `save()` to pass custom tag name

**File:** `ios/.../ViewModels/GratitudeEntryViewModel.swift` (lines 118-126)

```swift
return GratitudeItem(
    text: trimmed,
    category: draft.category,
    customTagName: draft.category == .custom ? draft.customTagName : nil,
    sortOrder: index
)
```

#### Step 4: Add custom tag name input in category pills

**File:** `ios/.../Views/Activities/GratitudeListView.swift` (lines 176-205)

After the `ScrollView` of category pills, add conditional `TextField`:

```swift
if viewModel.items[safe: index]?.category == .custom {
    TextField("Tag name (e.g., Pets, Music)", text: customTagNameBinding(for: index))
        .font(RRFont.caption)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 200)
}
```

Add binding helper alongside existing `binding(for:)` (~line 411):
```swift
private func customTagNameBinding(for index: Int) -> Binding<String> {
    Binding(
        get: { viewModel.items[safe: index]?.customTagName ?? "" },
        set: { newValue in
            guard viewModel.items.indices.contains(index) else { return }
            viewModel.items[index].customTagName = newValue
        }
    )
}
```

#### Step 5: Update all display locations

- **`GratitudeListView.swift`** (lines 389-396): Use `item.displayCategoryName` in history card
- **`GratitudeDetailView.swift`** (line 178): `RRBadge(text: item.displayCategoryName ?? category.rawValue, ...)`
- **`GratitudeHistoryView.swift`** (line 202, 384): Use `displayCategoryName` in `entryCard` and `favoritesTab`
- **`GratitudeTrendsView.swift`** (line 153): Keep `category.rawValue` since trends aggregate by enum, not custom names

---

## Feature 2: Prompt Before Today's Gratitude List

### Problem

The daily gratitude prompt is only available on-demand via "Need a prompt?" link. It should appear automatically before the entry card.

### Implementation

#### Step 1: Add auto-prompt state to ViewModel

**File:** `ios/.../ViewModels/GratitudeEntryViewModel.swift` (~line 40)

```swift
var dailyPromptDismissed: Bool = false
var dailyPrompt: GratitudePrompt?

func loadDailyPrompt(userId: UUID) {
    if dailyPrompt == nil && !dailyPromptDismissed {
        dailyPrompt = promptService.dailyPrompt(for: userId, on: Date())
    }
}

func dismissDailyPrompt() {
    dailyPromptDismissed = true
}

func useDailyPrompt() {
    guard let prompt = dailyPrompt else { return }
    var draft = GratitudeItemDraft()
    draft.text = prompt.text
    items.append(draft)
    dailyPromptDismissed = true
}
```

In `save()` (line 147-151), reset state:
```swift
dailyPrompt = nil
dailyPromptDismissed = false
```

#### Step 2: Add daily prompt card to `GratitudeListView`

**File:** `ios/.../Views/Activities/GratitudeListView.swift`

Insert between `firstUseCard` (line 29) and `entryCard` (line 32):

```swift
if !viewModel.dailyPromptDismissed, let prompt = viewModel.dailyPrompt {
    dailyPromptCard(prompt: prompt)
}
```

Add the card view:
```swift
private func dailyPromptCard(prompt: GratitudePrompt) -> some View {
    RRCard {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Today's Reflection")
                    .font(RRFont.headline)
                Spacer()
                Button {
                    withAnimation { viewModel.dismissDailyPrompt() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(prompt.text)
                .font(RRFont.body)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
            
            RRBadge(text: prompt.category, color: .rrPrimary)
            
            Button {
                withAnimation { viewModel.useDailyPrompt() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.insert")
                        .font(.caption)
                    Text("Use this prompt")
                        .font(RRFont.callout)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.rrPrimary)
            }
        }
    }
    .padding(.horizontal)
    .transition(.move(edge: .top).combined(with: .opacity))
}
```

#### Step 3: Trigger prompt loading on appear

```swift
.onAppear { viewModel.loadDailyPrompt(userId: userId) }
.animation(.easeInOut(duration: 0.3), value: viewModel.dailyPromptDismissed)
```

## Files Modified Summary

| File | Changes |
|------|--------|
| `Models/GratitudeTypes.swift` | Add `customTagName` to `GratitudeItem`; add `displayCategoryName` |
| `ViewModels/GratitudeEntryViewModel.swift` | Add `customTagName` to draft; add daily prompt state/methods; update `save()` |
| `Views/Activities/GratitudeListView.swift` | Custom tag input in pills; daily prompt card; `.onAppear` trigger |
| `Views/Activities/GratitudeDetailView.swift` | Use `displayCategoryName` in badges |
| `Views/Activities/GratitudeHistoryView.swift` | Use `displayCategoryName` in entry cards and favorites |

## Sequencing

1. Model layer (GratitudeTypes.swift) — backward-compatible Codable change
2. ViewModel layer (GratitudeEntryViewModel.swift) — custom tag + daily prompt
3. Entry view (GratitudeListView.swift) — custom tag input + prompt card
4. Display views (GratitudeDetailView, GratitudeHistoryView) — custom tag display
