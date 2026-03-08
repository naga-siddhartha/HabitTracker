# Ritual Log – Version 2 Roadmap & Research

**Document purpose:** Deep research on top habit apps, full inventory of Ritual Log v1, gap analysis, UI improvement considerations, and a v2 plan including login and sync.

---

## 1. Current App (Ritual Log v1) – Feature Inventory

### 1.1 Core Habit Model
- **Habit entity:** name, optional description, icon (SF Symbol) or emoji, color (9 options), frequency (daily / weekly), active weekdays (weekly only), created/updated dates, archived flag.
- **HabitEntry:** per-day completion (completed / not), skip support (isSkipped, optional skipReason). Dates normalized to start-of-day.
- **Streak:** current streak, longest streak, last completed date, streak start date; computed via `StreakCalculator` with **skip-aware logic** (skipped days don’t break streak).

### 1.2 Home
- Today’s date and tagline; active / scheduled / completed cards; progress ring (X of Y done); checklist rows with complete, details, context menu (view details, edit, delete); floating + (From template / Add habit); empty state with CTA; **iOS-only** AdMob banner in ad card.

### 1.3 Calendar
- **Daily:** date picker, list of habits active on selected date with complete/view/edit/delete.
- **Weekly:** 7-day strip with selected date, habits per day with completion/skip state (visual only; no skip action in UI).
- **Monthly:** month grid, cells show completion/skip state (visual only).
- **Yearly:** year overview with completion density.

### 1.4 Statistics
- **Activity:** contribution-style graph (26 weeks), month labels, day labels (Mon–Fri), legend (Less → More), level from completion ratio; tap for date + level popover.
- **Timeframe picker:** Week / Month / Year / All Time.
- **Stat cards:** Total Habits, Total Completions (in range), Current Streaks; tap opens detail sheet (Completions, Streaks, Habits).
- **Top Performing Habits** (by completions in range) and **Longest Streaks** with empty states.

### 1.5 Habits – Add/Edit & Templates
- **Add/Edit:** form with name, description, frequency, active days (weekly), reminders (name, time, sound per reminder), color, icon/emoji; save/cancel; load from existing habit or template.
- **Templates:** 24 predefined habits in 6 categories (Health, Productivity, Mindfulness, Fitness, Learning, Lifestyle); “From template” from Home or Add.

### 1.6 Reminders & Notifications
- **Per-habit reminders:** multiple per habit (name, time, sound). Stored as `reminderTimes`, `reminderNames`, `reminderSounds`; scheduled via `NotificationService` (time + weekday for weekly).
- **Sounds:** Default, Chime, Bell, Alert, None.
- **Global toggle:** Settings “Notifications” respects `notificationsEnabled`; no location-based or habit-stacking reminders.

### 1.7 Settings
- Notifications on/off; **Appearance** (Theme: System / Light / Dark); **Data:** Export (JSON full backup, CSV entries, CSV summary), **Reset All Data** with confirmation.
- **Support:** Privacy Policy, Contact & Support (from Info.plist).
- **About:** Version 1.0.0, habit count, total entries.

### 1.8 Data & Platform
- **Storage:** SwiftData, local only (`cloudKitDatabase: .none`). No account, no login, no cloud backup or sync.
- **Export:** JSON (full), CSV (entries), CSV (summary). **No import/restore.**
- **Platforms:** iOS (primary), macOS (native target, shared UI with conditionals), watchOS (stub “Habits” view).

### 1.9 Widgets & System Integration
- **Widget:** single small widget – “Today” with completed/total and progress bar; timeline refreshes at midnight; display name “Ritual Log”.
- **App Intents:** `ToggleHabitIntent` (habit by ID); **App Shortcuts** – “Complete a habit in Ritual Log” / “Mark habit done in Ritual Log” (Siri + Shortcuts). No parameterized “Complete [habit name]” discovery.

### 1.10 Monetization & Ads
- **Ads:** Google Mobile Ads (AdMob) on iOS only (banner on Home). Test device IDs in code.
- No subscriptions, no paywall, no limit on habit count.

### 1.11 Gaps in v1 (from codebase)
- **Skip:** Model and streak logic support skip + reason; **no UI** to mark a day as skipped or set skip reason (`skipDay`/`unskipDay` in `HabitStore` are never called from views).
- **Accessibility:** No `accessibilityLabel` / `accessibilityHint` / `accessibilityValue`.
- **Import:** Export only; no restore from JSON/CSV.
- **Watch:** Placeholder only.
- **Error handling:** Export/notification errors not clearly surfaced to the user.

---

## 2. Competitor Feature Overview (Research Summary)

### 2.1 Streaks (iOS/Mac)
- **Streak-focused**, to-do style; **HealthKit integration** (auto-complete from health data); **12-habit limit** by design; **Apple Watch + Siri Shortcuts**; one-time purchase; **no export/backup**, minimal analytics.

### 2.2 Habitica
- **RPG gamification:** avatar, quests, guilds, rewards; **cross-platform + account sync**; social/accountability; free + optional subscription; cluttered UI; risk of focus shifting from real habits to in-app rewards.

### 2.3 Loop Habit Tracker (Android)
- **Free, open-source**, offline; **privacy-first**, local-only; strong **visualization and “honest” statistics**; no health import, no social.

### 2.4 Habitify
- **Habits, routines, goals**; group by **time of day** (morning/afternoon/evening) or folders; **time + location reminders**; **habit stacking** (next habit cued after one completes); **Live Activity / Dynamic Island** reminders; **Apple Health two-way sync**, Google Fit, calendar; **import from Streaks/Productive**, export CSV + .sqlite backup; **API / Zapier / IFTTT**; **privacy lock**; **AI habit creation**; challenges; iOS, Mac, Watch, Android, Web; **freemium** (e.g. 3 habits free, then subscription).

### 2.5 Others (Grit, DayZero, HabitKit, etc.)
- **Apple Health:** auto-complete from steps, exercise, sleep, mindful minutes, water.
- **Widgets:** home + **lock screen**, multiple sizes; some allow **check-in from widget** (iOS 17+).
- **Siri / Shortcuts:** “Complete [habit]” and automation triggers (e.g. after workout).
- **Goals:** “X times per week” or “X times per month” (Strides, Fern, HabitBoard).
- **Skip / freeze:** “Freeze streak” or “vacation mode” so streaks aren’t broken when user intentionally skips.
- **Social:** share streaks (e.g. link), accountability partners (HabitShare, HabitStreak).
- **Gamification:** points, badges, milestones (7, 21, 66, 100 days), confetti.
- **Notes / mood:** per-check-in notes or mood (Habitify, Daylio-style).
- **Premium:** freemium with limits (habit count, reminders, export); subscription + sometimes lifetime; Family Sharing.

---

## 3. Gap Analysis: What We’re Lacking

| Area | v1 State | Common in Competitors | Priority for v2 |
|------|----------|------------------------|-----------------|
| **Account / login** | None | Email/social or Apple; required for sync & backup | **Critical** |
| **Cloud sync & backup** | None | Cross-device sync, cloud backup | **Critical** |
| **Import / restore** | Export only | Import from backup or from other apps | High |
| **Skip UI** | Data model only | “Skip day” + optional reason; freeze streak | High |
| **Reminders** | Time + weekday only | Location-based, multiple times, habit stacking, Live Activity | Medium |
| **Health integration** | None | Apple Health auto-complete (steps, workouts, mindfulness) | Medium |
| **Widgets** | One small, read-only | Lock screen, multiple sizes, **check-in from widget** | Medium |
| **Goals / targets** | Daily or weekly active days | “X times per week/month” | Medium |
| **Routines / time blocks** | None | Morning/afternoon/evening grouping | Medium |
| **Siri / Shortcuts** | Toggle by ID, generic phrases | “Complete [habit name]”, richer discovery | Medium |
| **Apple Watch** | Stub | Full today list + quick complete | Medium |
| **Accessibility** | Minimal | Labels, hints, VoiceOver-friendly | High |
| **Onboarding** | None | First-run flow, templates highlight | Medium |
| **Gamification** | Streaks only | Badges, milestones, confetti | Low |
| **Social** | None | Share streak, accountability | Low |
| **Premium / paywall** | Ads only | Freemium (habit/reminder limits), subscription | Optional v2 |
| **Privacy lock** | None | PIN/biometric for app | Low |
| **Localization** | English only | Multiple languages | Medium |

---

## 4. UI Improvement Considerations

These are design and UX considerations for v2 alongside feature work. They apply across Home, Calendar, Statistics, Settings, and any new screens (e.g. account, onboarding).

### 4.1 Visual Hierarchy & Layout
- **Headings:** Use a consistent hierarchy (e.g. PageHeading vs section titles vs card titles) so users quickly scan “where they are” and what’s primary vs secondary.
- **Content width:** You already use `LayoutConfig.contentMaxWidth` and horizontal padding; consider a max width on larger Mac/iPad canvases so content doesn’t stretch too wide and remains readable.
- **Cards:** Unify corner radius, shadow, and border treatment (e.g. `cardShadowColor`, `cardShadowRadius`) so Active/Scheduled/Completed and Stats cards feel like one system; same for StatCard and StatsSectionCard.
- **Spacing:** Standardize vertical rhythm (e.g. 8 / 16 / 24 / 32) and section spacing so lists and cards breathe consistently.

### 4.2 Home Screen
- **Progress ring:** Consider subtle animation when progress changes (e.g. fill animation or gentle scale) so completion feels rewarding.
- **Active vs Scheduled:** The split is clear; ensure the “Scheduled” card doesn’t feel secondary (e.g. equal card styling, or a small time badge so it’s obvious why it’s scheduled).
- **Floating action button:** Already platform-appropriate (popover on Mac, Menu on iOS). Consider a slight bounce or haptic when habits are completed to reinforce the action.
- **Empty state:** Keep the current CTA (New + From template); consider a single illustration or icon that matches the app’s tone to make the first experience feel intentional.
- **Ad card:** On narrow screens or with long content, ensure the ad card doesn’t dominate; consider collapsing to a single line with “Advertisement” and expand on tap if needed.

### 4.3 Calendar Views
- **Daily:** List is clear; consider swipe actions (e.g. swipe to complete or skip) in addition to tap for power users.
- **Weekly/Monthly:** Ensure selected date is always obvious (e.g. strong highlight or ring) and that completion/skip states are distinguishable at a glance (color + icon if needed).
- **Yearly:** Keep the density view; consider a short legend (e.g. “Darker = more completions”) for first-time viewers.
- **Consistency:** Use the same habit row patterns (icon/emoji, name, secondary info) across Daily, Weekly list cells, and Home checklist so the mental model is one “habit row” everywhere.

### 4.4 Statistics
- **Contribution graph:** Month labels are fixed (lineLimit + minimumScaleFactor); consider a short tooltip or helper text the first time the user sees it (“Each cell is a day; tap for details”).
- **Stat cards:** Make the primary number (value) the clear focus (size/weight); keep icon and title secondary so “12” completions reads before “Total Completions.”
- **Top habits / Longest streaks:** Consider showing a small sparkline or trend (e.g. last 7 days) next to each habit so the list is more informative at a glance.
- **Timeframe:** Persist the last selected timeframe (e.g. AppStorage) so returning users see the same view by default.

### 4.5 Add/Edit Habit & Templates
- **Form flow:** Group related fields (e.g. Basic Info → Frequency → Reminders → Appearance) and consider a step indicator or “Next” for long forms so it doesn’t feel overwhelming.
- **Templates:** Categories are clear; consider search or a “Recently used” section for users who add many habits from templates.
- **Color/icon picker:** Ensure sufficient contrast in dark mode and that selected state is obvious (e.g. ring + checkmark).
- **Reminders:** When there are multiple reminders, a compact list (time + label) with edit/delete per row keeps the form scannable.

### 4.6 Settings & Account (v2)
- **Account section:** If v2 adds login, place “Account” at the top (email/Apple, sign out, delete account) and keep Notifications, Appearance, Data, Support, About below in a clear order.
- **Export/Import:** Use clear primary actions (e.g. “Export” / “Restore from backup”) and show success/error in a toast or inline message, not only an alert.
- **Destructive actions:** Keep Reset All Data behind a confirmation; use a destructive button style and, if you add account, “Delete account” in a separate section with its own confirmation.

### 4.7 Empty & Loading States
- **Empty states:** Every list (Home no habits, Calendar no habits for day, Stats no completions/streaks) should have a single message + one primary CTA so users know what to do next.
- **Loading:** For sync or export/import in v2, show a clear loading state (spinner + “Syncing…” / “Preparing export…”) and disable relevant actions until done.
- **Errors:** Replace generic failures with specific messages (e.g. “Export failed: not enough storage”) and a retry where applicable.

### 4.8 Animations & Feedback
- **Transitions:** Use consistent sheet/card transitions; consider a light scale or opacity when presenting modals so the transition doesn’t feel abrupt.
- **Completion:** You already use haptics and animation on the checkbox; consider a brief confetti or checkmark burst for “all habits done today” to celebrate the milestone.
- **Lists:** When habits are reordered or completed, consider subtle list animations (e.g. `.animation(.default, value: completedCount)`) so the UI feels responsive.

### 4.9 Consistency Across Platforms
- **iOS vs macOS:** You use `#if os(macOS)` for popovers, padding, and Settings scene; ensure keyboard shortcuts (e.g. ⌘N for new habit, ⌘,) are documented or shown in menus on Mac.
- **Widgets:** Match widget typography and colors to the app (e.g. same green for progress, same “Today” wording) so the widget feels part of Ritual Log, not generic.

### 4.10 Accessibility (UI Aspect)
- **Touch targets:** Ensure all interactive elements (checkboxes, menu buttons, list rows) meet minimum size (e.g. 44pt) and have clear hit areas.
- **Focus order:** On Mac and with VoiceOver, ensure focus moves logically (e.g. header → progress → active habits → scheduled → completed → FAB).
- **Labels:** Add `accessibilityLabel` and `accessibilityValue` to stat cards (“Total habits, 5”), contribution cells (“March 15, 75% completed”), and custom controls so every interactive element is announced correctly.
- **Dynamic Type:** Prefer semantic fonts (e.g. `.headline`, `.body`) and avoid fixed sizes where possible so the app respects user text size settings.

### 4.11 Onboarding (First Launch)
- **First-run screen:** One to three screens (e.g. “Track habits daily”, “Build streaks”, “Start with a template”) with a clear “Get started” that leads to template picker or empty Home.
- **Tooltips (optional):** A single optional “Tap the + to add your first habit” on Home when habits.isEmpty and onboarding just finished can reduce confusion without cluttering the main UI.

---

## 5. Version 2 – Scope (with Login)

### 5.1 Pillars
1. **Account & data in the cloud** – login, sync, backup, restore.
2. **Completeness of core loop** – skip UI, better reminders, import.
3. **Platform & system integration** – widgets (including lock screen + tap-to-complete), Watch, Siri, Health (optional).
4. **Quality & inclusivity** – accessibility, onboarding, error handling, **UI polish** (see Section 4).

### 5.2 Account & Login (Must-Have for v2)
- **Sign-in options:**
  - **Sign in with Apple** (required if other social login).
  - Optional: Email/password or Google (if you add a backend).
- **Account state:** Signed out (local-only, like v1) vs signed in (sync enabled).
- **Data model:**
  - User identifier (and optionally email/display name if needed).
  - Sync: link SwiftData/CloudKit or your backend to “user id”; conflict resolution (e.g. last-write-wins or merge rules for habits/entries).
- **Privacy:** Same as v1 – no selling of habit data; policy updated for “account data” (identifier, email if used) and sync/backup.

### 5.3 Sync & Backup (Must-Have for v2)
- **Cloud backend options:**
  - **CloudKit** (Apple-only, no custom backend; use with Sign in with Apple).
  - Or **Firebase / custom backend** (needed for Android/Web later).
- **Behavior:**
  - While signed in: continuous sync (create/update/delete habits and entries).
  - Optional: “Backup now” that stores a snapshot (e.g. JSON or CloudKit record) for restore.
- **Restore:** “Restore from backup” (from last snapshot or from exported file). **Import from v1 JSON** so existing users can upload an export and get it into v2.

### 5.4 Core Product Improvements
- **Skip day UI:**
  - In calendar (daily/weekly/monthly) and Home: “Skip” with optional reason; call `skipDay(for:on:reason:)`.
  - Optional: “Freeze streak” (treat as intentional skip so streak doesn’t break).
- **Import:**
  - Restore from **Ritual Log JSON export** (v1 format).
  - Optional: import from **Streaks** or **Habitify** if you define/parse their export formats.
- **Reminders:**
  - Keep current time + sound; optional: **location-based** (“when I leave home”), **habit stacking** (“after habit X”), or **Live Activity** for “next habit” (iOS).
- **Goals (optional):**
  - “Complete at least X times per week” or “per month” with progress (e.g. 3/5 this week).

### 5.5 Platform & System
- **Widgets:**
  - **Lock screen** (iOS 16+).
  - **Medium/large** home screen: today’s list.
  - **Interactive:** tap to complete a habit (iOS 17+ App Intents from widget).
- **Siri / Shortcuts:**
  - **Parameterized intent:** “Complete [habit name]” with habit picker in Shortcuts.
  - **Discoverable** habits so users can build “Complete Morning Routine” etc.
- **Apple Watch:**
  - Today’s habits list + tap to complete; optional complications.
- **Apple Health (optional):**
  - Link a habit to a Health type (e.g. “Exercise” ↔ workout minutes); auto-complete when threshold met.

### 5.6 Quality & Growth
- **Accessibility:**
  - Labels/hints/values for stat cards, contribution graph, checklist rows, tabs, key buttons.
- **Onboarding:**
  - First launch: short value prop + “Start from template” or “Create your first habit.”
- **Error handling:**
  - Export/import/sync/notification errors shown in alerts with retry where appropriate.
- **Localization:**
  - String catalogs; at least one extra language (e.g. Spanish or your target market).
- **UI improvements:**
  - Apply Section 4 (hierarchy, spacing, empty/loading states, animations, consistency, accessibility, onboarding) as part of v2.

### 5.7 Monetization (Optional for v2)
- **Keep:** AdMob on iOS for free tier.
- **Optional freemium:**
  - Free: e.g. up to 5 habits, 1 reminder per habit, no cloud backup.
  - Premium (subscription or lifetime): unlimited habits, cloud sync/backup, advanced reminders, Health, no ads.
- **Family Sharing** if you add subscription.

---

## 6. Technical Considerations for v2

- **Schema migration:** Add user id (and any sync metadata) to Habit/Entry; version SwiftData schema and provide migration from v1.
- **Sync strategy:** Prefer CloudKit with SwiftData if Apple-only; otherwise design a simple REST or Firestore model (habits, entries, last-modified) and conflict resolution.
- **Auth:** Sign in with Apple (and optionally Firebase Auth or custom JWT) with token refresh and “sign out everywhere” if you have a backend.
- **Widgets:** Shared App Group + shared storage (UserDefaults or lightweight DB) for widget timeline; use App Intents for tap-to-complete.
- **Watch:** WatchConnectivity or shared CloudKit so Watch shows same data as phone; keep UI minimal (list + complete).

---

## 7. Suggested v2 Phases

- **Phase 1 (MVP v2):** Account (Sign in with Apple), cloud sync or at least cloud backup, import from v1 JSON, skip-day UI, accessibility pass, onboarding, **core UI polish** (hierarchy, empty/loading/error states, Section 4.1–4.7).
- **Phase 2:** Better widgets (lock screen, interactive), Siri “Complete [habit name]”, Apple Watch app, **animations and consistency pass** (Section 4.8–4.9).
- **Phase 3:** Reminder upgrades (location, stacking, Live Activity), optional Health, goals (X/week), optional freemium, **localization**.

---

## 8. References (Summary)

- Competitor features: Habitify (habitify.me, Help Center), Streaks, Habitica, Loop, HabitKit, Grit, DayZero, Strides, Fern, HabitBoard.
- Monetization: Habitify pricing, Fabulous, “Habit Tracker with Widget” style freemium.
- Widgets: Habitify/HabitKit lock screen and check-in; iOS 17 App Intents.
- Health: Habituul, DayZero, Grit, DailyAI.
- Data: Habitify export/import, Lunatask, Daylio backup formats.
