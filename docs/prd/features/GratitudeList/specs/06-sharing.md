# Gratitude List: Sharing Specification

**Spec ID:** GL-SH-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Sharing

---

## 1. Share Options

### Share Scope

- **Individual item:** Share a single gratitude text
- **Full entry:** Share all items from one day's entry

### Share Targets

1. **Support network** — in-app messaging to spouse, sponsor, accountability partner, counselor (via existing messaging system)
2. **Clipboard** — copy plain text for pasting elsewhere
3. **Styled graphic** — generates an image card with typography, background, and optional scripture for social media

### Privacy Rules

- Shared content **never** includes: mood tags, category tags, or photo attachments
- Only the gratitude text itself is shared
- Sharing is always opt-in, per item or per entry
- Respects community permissions (spouse/counselor can view if permissions granted)

---

## 2. Styled Graphic

### Card Template

```
┌─────────────────────────────────┐
│                                 │
│  "Grateful for 47 days of      │
│   sobriety and my sponsor's    │
│   patience."                   │
│                                 │
│              — March 28, 2026   │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Optional scripture verse  │  │
│  └───────────────────────────┘  │
│                                 │
│         Regal Recovery          │
└─────────────────────────────────┘
```

### Design Specs

- Background: gradient or solid color (user-selectable from 4-5 options)
- Typography: serif or sans-serif (2 options)
- Optional scripture: user can add a verse or leave blank
- Rendered as PNG, shared via iOS share sheet
- Brand watermark "Regal Recovery" in small text at bottom

---

## 3. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-SH-AC1 | Individual items shareable | `TestGratitude_GL_SH_AC1_ShareItem` |
| GL-SH-AC2 | Full entry shareable as combined text | `TestGratitude_GL_SH_AC2_ShareEntry` |
| GL-SH-AC3 | Shared content excludes mood, category, photo | `TestGratitude_GL_SH_AC3_PrivacyFilter` |
| GL-SH-AC4 | Copy to clipboard works | `TestGratitude_GL_SH_AC4_Clipboard` |
| GL-SH-AC5 | Styled graphic renders with text and date | `TestGratitude_GL_SH_AC5_StyledGraphic` |
| GL-SH-AC6 | Share via iOS share sheet | `TestGratitude_GL_SH_AC6_ShareSheet` |
