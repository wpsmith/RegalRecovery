# Gratitude List: Prompts Specification

**Spec ID:** GL-PR-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Gratitude Prompts

---

## 1. Prompt Library

### Data Model

```swift
struct GratitudePrompt: Identifiable, Codable {
    let id: String
    let text: String
    let category: GratitudeCategory
}
```

### Storage

- Prompts bundled in app as static content (JSON file in content assets)
- 50+ prompts at launch, organized by category
- Daily rotation: deterministic based on day-of-year + user ID hash (consistent per user per day)

---

## 2. Prompt Categories and Examples

### Faith / God
1. "What is something God has done in your life that you didn't deserve?"
2. "How has your faith helped you through a difficult moment recently?"
3. "What scripture or truth has been meaningful to you this week?"
4. "When did you feel closest to God recently?"
5. "What spiritual growth have you noticed in yourself?"

### Family
6. "What is something a family member did recently that made you smile?"
7. "What is a quality in your spouse/partner you're thankful for?"
8. "What is a childhood memory that still brings you joy?"
9. "How has your family supported your recovery?"
10. "What is something your children (or a child in your life) taught you?"

### Relationships
11. "Who showed you kindness recently, and how did it make you feel?"
12. "Who is someone you're glad is in your life, and why?"
13. "What is a conversation you had recently that meant something to you?"
14. "How has your sponsor or accountability partner helped you grow?"
15. "What friend have you been able to count on?"

### Health
16. "What is one thing about your body or health you're grateful for?"
17. "How has your physical health improved since starting recovery?"
18. "What healthy habit are you proud of maintaining?"
19. "What is a meal or food you enjoyed recently?"
20. "How did your body serve you well today?"

### Recovery
21. "What is something about your recovery journey you're thankful for right now?"
22. "What tool or practice has been most helpful in your recovery this week?"
23. "What is a temptation you resisted recently, and how did that feel?"
24. "What is a mistake or struggle that taught you something valuable?"
25. "How have you grown since your lowest point?"
26. "What is one way you've grown in the last 30 days?"

### Work / Career
27. "What is something you accomplished at work that you're proud of?"
28. "Who at work has been supportive or encouraging?"
29. "What skill or ability do you have that you're thankful for?"
30. "What opportunity has come your way recently?"

### Nature / Beauty
31. "What is something beautiful you noticed today?"
32. "When did nature bring you peace or joy recently?"
33. "What season or weather are you enjoying right now?"
34. "What sound, sight, or smell brought you comfort today?"

### Small Moments
35. "What is one thing about today that surprised you in a good way?"
36. "What is a simple pleasure you experienced today?"
37. "What made you laugh recently?"
38. "What small comfort did you enjoy today?"
39. "What is a routine moment that you usually take for granted but are thankful for?"

### Growth / Progress
40. "What is a hard thing you did recently that you're proud of?"
41. "What is a fear you've faced or are facing with courage?"
42. "How are you different today than you were a year ago?"
43. "What boundary have you set that's protecting your recovery?"
44. "What is something you can do now that you couldn't do 6 months ago?"

### General
45. "If you could only keep three things in your life, what would they be?"
46. "What is something you have that many people wish for?"
47. "What is a lesson you learned the hard way that you're now grateful for?"
48. "What made today worth living?"
49. "What are you looking forward to?"
50. "What would you miss most if it were gone tomorrow?"

---

## 3. Prompt Selection Algorithm

```swift
func dailyPrompt(for userId: UUID, on date: Date) -> GratitudePrompt {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    let hash = userId.hashValue
    let index = abs((dayOfYear + hash) % prompts.count)
    return prompts[index]
}
```

- Deterministic: same user sees same prompt all day
- Different prompt each day
- "Different prompt" button increments an offset for the session

---

## 4. Prompt UI Behavior

1. "Need a prompt?" link visible on entry screen
2. Tapping shows a card overlay with prompt text and category pill
3. Three actions:
   - **"Use this"** — inserts prompt text as the text of a new item
   - **"Different prompt"** — rotates to next prompt (wraps around)
   - **"Dismiss"** — closes prompt card
4. Prompt card dismisses automatically after "Use this"

---

## 5. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-PR-AC1 | 50+ prompts available in bundled library | `TestGratitude_GL_PR_AC1_PromptCount` |
| GL-PR-AC2 | Daily prompt deterministic per user per day | `TestGratitude_GL_PR_AC2_DeterministicDaily` |
| GL-PR-AC3 | "Different prompt" cycles to next prompt | `TestGratitude_GL_PR_AC3_CyclePrompt` |
| GL-PR-AC4 | "Use this" inserts prompt as new gratitude item | `TestGratitude_GL_PR_AC4_InsertAsItem` |
| GL-PR-AC5 | Each prompt tagged with a category | `TestGratitude_GL_PR_AC5_PromptCategories` |
| GL-PR-AC6 | Prompts distributed across all categories | `TestGratitude_GL_PR_AC6_CategoryDistribution` |
