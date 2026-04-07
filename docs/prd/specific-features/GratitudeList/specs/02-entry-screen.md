# Gratitude List: Entry Screen Specification

**Spec ID:** GL-ES-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Gratitude Entry, Gratitude Prompts, Tone & Messaging, Edge Cases

---

## 1. Screen: `GratitudeEntryView`

### Layout

```
NavigationStack
  ScrollView
    VStack(spacing: 20)
      ┌─────────────────────────────────┐
      │ RRCard: Entry Area              │
      │  "Today's Gratitude"            │
      │  [Gratitude Item 1]        [×]  │
      │  [Gratitude Item 2]        [×]  │
      │  [Gratitude Item 3]        [×]  │
      │  [+ Add another]               │
      │                                 │
      │  ── Optional ──                 │
      │  [Category Tag Picker]          │
      │  [Mood: 1-5 emoji row]          │
      │  [Attach Photo]                 │
      │                                 │
      │  [Need a prompt?]               │
      │                                 │
      │  [Save Gratitude]               │
      └─────────────────────────────────┘

      ┌─────────────────────────────────┐
      │ Success Animation (on save)     │
      │  ✓ checkmark + warm message     │
      └─────────────────────────────────┘
```

### Behavior

1. **Item Entry:**
   - Start with one empty text field, auto-focused
   - Each field: `TextField("I'm grateful for...", text: $item, axis: .vertical)`
   - Max 300 characters per item with character counter shown at 250+
   - Tap "+" or press Enter to add another item (no max limit)
   - Swipe-to-delete or tap "x" to remove an item
   - Drag-and-drop reorder via `onMove` (optional, not required for MVP)
   - Voice-to-text via standard iOS dictation (no custom implementation needed)

2. **Category Tags (optional per item):**
   - Compact horizontal pill selector below each item or as a section
   - Tapping a category toggles it; tapping again removes
   - "Custom" shows a small text field for free-text tag

3. **Mood Tag (optional per entry):**
   - Row of 5 emoji buttons: 1=very low, 2=low, 3=neutral, 4=good, 5=great
   - Single selection; tap again to deselect
   - Captures emotional state during gratitude practice

4. **Photo Attachment (optional):**
   - Camera or photo library picker
   - Single photo per entry
   - Stored locally; thumbnail preview shown

5. **Gratitude Prompts:**
   - "Need a prompt?" link at bottom of entry area
   - Tapping shows a prompt card with rotating prompt from curated library
   - "Use this" inserts prompt text as a new item
   - "Different prompt" rotates to next
   - "Dismiss" closes prompt card

6. **Save:**
   - Requires at least 1 non-empty item
   - Save button disabled until minimum met
   - On save: gentle checkmark animation + rotating warm message
   - Fields cleared after save; ready for another entry

7. **Edit Mode:**
   - If navigating to an existing entry within 24h of creation, fields pre-populated
   - Save button reads "Update Gratitude"
   - After 24h, entry is read-only (view mode only)

---

## 2. Post-Save Messages (rotating)

```swift
static let postSaveMessages: [String] = [
    "A grateful heart is a guarded heart. Thank you for pausing to notice the good.",
    "Every item on this list is evidence that God is at work in your life.",
    "Gratitude doesn't ignore the pain — it refuses to let pain have the last word.",
    "You just trained your brain to see the good. That's recovery in action.",
    "Even one thing to be thankful for can shift your whole perspective.",
]
```

---

## 3. First-Use Onboarding Text

On first entry (no existing gratitude entries):

> "Gratitude rewires how your brain processes the world. In recovery, it's one of the most powerful antidotes to shame, self-pity, and resentment. Start with just one thing."

---

## 4. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-ES-AC1 | Entry requires minimum 1 non-empty item to save | `TestGratitude_GL_ES_AC1_MinimumOneItem` |
| GL-ES-AC2 | Items have 300 character max with counter at 250+ | `TestGratitude_GL_ES_AC2_CharacterLimit` |
| GL-ES-AC3 | Unlimited items can be added per entry | `TestGratitude_GL_ES_AC3_UnlimitedItems` |
| GL-ES-AC4 | Individual items deletable before save | `TestGratitude_GL_ES_AC4_DeleteBeforeSave` |
| GL-ES-AC5 | Optional category tag selectable per item | `TestGratitude_GL_ES_AC5_CategoryTag` |
| GL-ES-AC6 | Optional mood score 1-5 per entry | `TestGratitude_GL_ES_AC6_MoodScore` |
| GL-ES-AC7 | Gratitude prompt shown on "Need a prompt?" tap | `TestGratitude_GL_ES_AC7_PromptDisplay` |
| GL-ES-AC8 | Prompt inserts as new item on "Use this" | `TestGratitude_GL_ES_AC8_PromptInsert` |
| GL-ES-AC9 | Save shows confirmation animation + warm message | `TestGratitude_GL_ES_AC9_SaveConfirmation` |
| GL-ES-AC10 | Fields cleared after successful save | `TestGratitude_GL_ES_AC10_ClearAfterSave` |
| GL-ES-AC11 | Entry editable within 24h, read-only after | `TestGratitude_GL_ES_AC11_EditWindow` |
| GL-ES-AC12 | Single photo attachable per entry | `TestGratitude_GL_ES_AC12_PhotoAttach` |
| GL-ES-AC13 | First-use shows onboarding helper text | `TestGratitude_GL_ES_AC13_FirstUseText` |
| GL-ES-AC14 | Saving with 1 item is valid and celebrated equally | `TestGratitude_GL_ES_AC14_SingleItemValid` |
| GL-ES-AC15 | Opening without saving records no data | `TestGratitude_GL_ES_AC15_NoAbandonedTracking` |
