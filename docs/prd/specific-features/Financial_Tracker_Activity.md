# Activity: Financial Tracker

**Priority:** P2

**Description:** Track addiction-related financial impact and recovery spending.

---

## User Stories

- As a **recovering user**, I want to see how much money I've saved since getting sober, so that I have a tangible, motivating reminder of the financial benefits of recovery
- As a **recovering user**, I want to estimate the cost of each acting-out incident, so that I can confront the real financial toll my addiction has taken
- As a **recovering user**, I want to track what I'm spending on recovery (therapy, resources, meetings), so that I can see it as an investment rather than a burden
- As a **recovering user**, I want to see a net savings or cost dashboard, so that I can understand the full financial picture of addiction versus recovery
- As a **recovering user**, I want to set a goal for what I'll do with the money I'm saving, so that I have something positive and concrete to work toward
- As a **recovering user**, I want to track the financial consequences of my addiction (legal fees, medical bills, lost income), so that I have an honest accounting of what this has cost me and my family
- As a **recovering user**, I want my financial data to remain private by default, so that I feel safe being honest about the numbers
- As a **spouse**, I want to understand the financial impact of addiction on our household, so that we can plan our recovery and finances together with full transparency

---

## Cost Estimation Setup

- **Per-incident cost:** User enters an estimated average cost per acting-out incident
  - Guided prompts to help estimate: "Consider money spent on: subscriptions, purchases, travel, gifts, hotels, meals, cover-up expenses, etc."
  - Multiple cost profiles allowed (different addictions may have different costs)
  - Editable at any time — recalculates historical estimates when updated

- **Historical baseline (optional):**
  - "Before recovery, how often were you acting out?" (times per week/month)
  - "How long has this been going on?" (years)
  - Calculates estimated lifetime cost of addiction for perspective

---

## Money Saved Calculator

- Automatically calculates money saved based on sobriety days and per-incident cost estimate
- Formula: (Days sober ÷ average days between incidents before recovery) × per-incident cost
- Displayed prominently: "You've saved an estimated $X,XXX since starting recovery"
- Updates daily alongside sobriety streak
- Milestone celebrations tied to savings amounts (e.g., $100, $500, $1,000, $5,000)

---

## Recovery Investment Tracking

- Log recovery-related expenses by category:
  - **Therapy/Counseling** — session fees, insurance copays
  - **Recovery Programs** — retreat fees, intensive outpatient costs, workshop registrations
  - **Resources** — books, courses, app subscriptions, workbooks
  - **Meetings** — travel costs, childcare during meetings, donations
  - **Medical** — prescriptions, psychiatric appointments
  - **Other** — custom category with free-text label
- Each entry: amount, date, category, optional note
- Running total per category and overall

---

## Consequence Costs

- Track financial consequences directly resulting from addiction:
  - **Legal** — attorney fees, court costs, fines, settlements
  - **Medical** — STI treatment, emergency visits, rehab stays
  - **Lost Income** — job loss, missed work, reduced productivity, career setbacks
  - **Relationship** — marriage counseling, separation costs, divorce proceedings
  - **Other** — custom category with free-text label
- Each entry: amount, date, category, optional note
- Running total per category and overall
- These costs are presented compassionately — framed as information for reflection, not punishment

---

## Net Savings/Cost Dashboard

- **Summary view:**
  - Money saved (estimated from sobriety)
  - Recovery investment (total spent on recovery)
  - Consequence costs (total financial fallout from addiction)
  - Net position: Money saved − Recovery investment − Consequence costs
- **Visual breakdown:** Pie chart or bar chart showing proportions across categories
- **Time-based view:** Monthly or weekly spending/savings trends over time
- **Comparison:** "Before recovery you were spending an estimated $X/month on your addiction. Now you're investing $Y/month in recovery."

---

## Goal Setting

- "What will you do with the money you're saving?"
- User sets one or more financial goals:
  - Goal name (e.g., "Family vacation," "Pay off debt," "Emergency fund," "Date nights with spouse")
  - Target amount
  - Target date (optional)
- Progress bar showing savings toward each goal
- Milestone notifications when goals are reached
- Goals displayed alongside sobriety streak for dual motivation

---

## History & Reports

- Browse all financial entries by date, category, or type (savings, investment, consequence)
- Search and filter entries
- Monthly and annual summaries
- Export as CSV or PDF for personal records, therapy sessions, or financial planning

---

## Privacy & Permissions

- Financial data is **excluded from default sharing permissions** — even for spouse, counselor, and sponsor roles
- User must explicitly grant financial viewing access on a per-person basis
- Rationale: Financial data is uniquely sensitive and may involve shame, legal exposure, or marital conflict — the user must feel fully in control of who sees it

---

## Integration Points

- Feeds into Tracking System (consecutive days of financial logging, if user chooses to log regularly)
- Feeds into Analytics Dashboard (spending trends, savings milestones)
- Savings amount displayed as optional widget on main Dashboard
- Linked from Post-Mortem Analysis (prompt: "Would you like to log any financial costs associated with this relapse?")
- Linked from Relapse Logging flow (optional prompt to estimate incident cost)

---

## Notifications

- Weekly savings update: "This week you saved an estimated $XX by staying sober"
- Goal milestone: "You've reached 50% of your goal: Family Vacation!"
- Monthly summary: "Here's your financial recovery snapshot for [month]"
- All financial notifications optional and independently togglable in Settings

---

## Edge Cases

- User doesn't know their per-incident cost → Provide guided estimation prompts with common ranges; allow "I'm not sure" with option to revisit later
- User relapses → Prompt to log estimated cost of relapse; recalculate net savings
- Currency → Default to user's locale currency; manual currency selection available in Settings
- User has no recovery expenses → Dashboard still functional showing savings and goals only
- Shared finances with spouse → User can optionally note which expenses are from shared vs. personal funds
- Offline → All entries saved locally, synced when connection restored
