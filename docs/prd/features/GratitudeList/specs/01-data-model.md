# Gratitude List: Data Model Specification

**Spec ID:** GL-DM-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Entry Format, Saving, History, Edge Cases

---

## 1. SwiftData Model: `RRGratitudeEntry`

### Current Model (to be migrated)

```swift
@Model
final class RRGratitudeEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var items: [String]
    var createdAt: Date
    var modifiedAt: Date
}
```

### Target Model

```swift
@Model
final class RRGratitudeEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date                          // Entry timestamp
    var items: [GratitudeItem]              // Ordered list of gratitude items
    var moodScore: Int?                     // Optional 1-5 mood at time of entry
    var photoLocalPath: String?             // Local file path for attached photo
    var promptUsed: String?                 // Text of prompt if one was used
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool                    // Quick access to favorite entries
}
```

### New Value Type: `GratitudeItem`

```swift
struct GratitudeItem: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var text: String                        // 300 char max
    var category: GratitudeCategory?        // Optional category tag
    var isFavorite: Bool = false            // Individual item favoriting
    var sortOrder: Int                      // Drag-and-drop ordering
}
```

### Enum: `GratitudeCategory`

```swift
enum GratitudeCategory: String, Codable, CaseIterable, Identifiable {
    case faithGod = "Faith / God"
    case family = "Family"
    case relationships = "Relationships"
    case health = "Health"
    case recovery = "Recovery"
    case workCareer = "Work / Career"
    case natureBeauty = "Nature / Beauty"
    case smallMoments = "Small Moments"
    case growthProgress = "Growth / Progress"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .faithGod: return "cross.fill"
        case .family: return "house.fill"
        case .relationships: return "person.2.fill"
        case .health: return "heart.fill"
        case .recovery: return "arrow.trianglehead.counterclockwise.rotate.90"
        case .workCareer: return "briefcase.fill"
        case .natureBeauty: return "leaf.fill"
        case .smallMoments: return "sparkle"
        case .growthProgress: return "chart.line.uptrend.xyaxis"
        case .custom: return "tag.fill"
        }
    }
}
```

---

## 2. MongoDB Document (Backend)

Extends the existing schema-design.md pattern:

```json
{
  "PK": "USER#u_12345",
  "SK": "GRATITUDE#2026-04-07T07:00:00Z",
  "EntityType": "GRATITUDE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T07:00:00Z",
  "ModifiedAt": "2026-04-07T07:00:00Z",
  "gratitudeId": "g_88888",
  "items": [
    {
      "id": "gi_001",
      "text": "Grateful for 47 days of sobriety",
      "category": "recovery",
      "isFavorite": false,
      "sortOrder": 0
    },
    {
      "id": "gi_002",
      "text": "My sponsor's patience and wisdom",
      "category": "relationships",
      "isFavorite": true,
      "sortOrder": 1
    }
  ],
  "moodScore": 4,
  "photoKey": null,
  "promptUsed": null,
  "isFavorite": false
}
```

---

## 3. Migration Plan

The existing `RRGratitudeEntry` stores `items: [String]`. Migration converts each string to a `GratitudeItem`:

```swift
// Lightweight migration: SwiftData handles additive properties with defaults.
// items: [String] -> items: [GratitudeItem] requires a versioned migration.
```

**Migration Strategy:**
1. Add new model `RRGratitudeEntryV2` alongside existing model
2. On first launch with new version, migrate existing entries:
   - Each `String` item becomes a `GratitudeItem(text: item, sortOrder: index)`
   - All new optional fields default to `nil` / `false`
3. Delete old `RRGratitudeEntry` records after successful migration

---

## 4. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-DM-AC1 | Each gratitude item supports text up to 300 characters | `TestGratitude_GL_DM_AC1_ItemTextMaxLength` |
| GL-DM-AC2 | Items have optional category tag from predefined enum + custom | `TestGratitude_GL_DM_AC2_CategoryTagOptions` |
| GL-DM-AC3 | Entry supports optional mood score 1-5 | `TestGratitude_GL_DM_AC3_MoodScoreRange` |
| GL-DM-AC4 | Entry supports optional photo local path | `TestGratitude_GL_DM_AC4_PhotoAttachment` |
| GL-DM-AC5 | Items are ordered by sortOrder field | `TestGratitude_GL_DM_AC5_ItemOrdering` |
| GL-DM-AC6 | Individual items can be favorited independently | `TestGratitude_GL_DM_AC6_ItemFavoriting` |
| GL-DM-AC7 | Entries editable within 24 hours of creation | `TestGratitude_GL_DM_AC7_EditWindow` |
| GL-DM-AC8 | Entries read-only after 24 hours | `TestGratitude_GL_DM_AC8_ReadOnlyAfter24h` |
| GL-DM-AC9 | Multiple entries per day saved independently | `TestGratitude_GL_DM_AC9_MultiplePerDay` |
| GL-DM-AC10 | Migration converts legacy [String] items to [GratitudeItem] | `TestGratitude_GL_DM_AC10_LegacyMigration` |
