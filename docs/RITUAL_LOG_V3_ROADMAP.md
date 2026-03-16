# Ritual Log – Version 3 Roadmap: In-App Purchase & Premium

**Purpose:** Introduce sustainable monetization via (1) a one-time “Remove Ads” IAP and (2) a Premium subscription tier, with feature set and pricing informed by behavioral research and competitor analysis.

---

## 0. Current App (as of V3 Baseline)

This section reflects what the app already has so the roadmap and “free vs. Premium” split are accurate.

### 0.1 Habit model & data
- **Habit:** name, optional description, color (9 presets + custom hex), emoji/icon (suggested + picker + custom text), frequency (daily / weekly), active weekdays (weekly), created/updated, archived.
- **HabitEntry:** per-day completion (completed / not), optional skip (isSkipped, skipReason). Repeating habits: completionCount, expectedCompletions; reminderIntervalMinutes + reminderEndTime on Habit.
- **Streak:** current streak, longest streak; skip-aware (skipped days don’t break streak). Computed via StreakCalculator.
- **Reminders:** Multiple per habit: time, label, sound (Default, Chime, Bell, Alert, None). Optional repeating: “every N minutes” with optional end time (reminderIntervalMinutes, reminderEndTime).
- **Storage:** SwiftData, local or CloudKit when signed in. Optional userId on Habit/Entry/Streak for sync.

### 0.2 Home (iOS & macOS)
- Today’s date; progress ring (X of Y done); **Active** card (due now), **Scheduled** card (due later today), **Completed** card; checklist rows with complete, details, context menu (view details, edit, delete, skip/unskip/skip with reason). Skipped state shown in row (orange, “Skipped” + optional reason). Floating + (From template / Add habit); empty state with CTA.
- **iOS only:** Ad card (AdMob banner) below main content.

### 0.3 Calendar
- **Daily:** date picker, list of habits for selected date with complete/skip/unskip, skip reason sheet.
- **Weekly:** 7-day strip, habits per day with completion/skip state; context menu skip/unskip per day.
- **Monthly:** month grid, completion/skip state per cell; **Yearly:** year overview (density).
- All views support skip with optional reason; skip doesn’t break streak.

### 0.4 Statistics
- **Activity:** contribution-style graph, 26 weeks, month/day labels, tap for date + level.
- **Summary:** timeframe picker **Week / Month / Year / All Time**; stat cards: **Total Habits**, **Total Completions** (in range), **Current Streaks** (tap for detail sheets: Completions, Streaks, Habits).
- **Top Performing Habits** (by completions in range), **Longest Streaks**; empty states.

### 0.5 Add/Edit habit & templates
- **Add/Edit:** name, note, **Appearance** (color grid, emoji suggested + picker + “type your own”), **Schedule** (Repeats: Daily/Weekly + weekdays), reminders (time, label, sound; optional “every N hours” with end time). Save/cancel; load from existing habit or template.
- **Templates:** 24 predefined habits in 6 categories (Health, Productivity, Mindfulness, Fitness, Learning, Lifestyle); “From template” from Home or Add.

### 0.6 Settings
- **Account:** “Account settings” → AccountSettingsView: Sign in with Apple, profile, **Sync now** (CloudKit), sign out. Delete account (confirmation).
- **Notifications:** global on/off; per-habit reminders (time + weekday for weekly).
- **Appearance:** Theme (System / Light / Dark).
- **Data:** **Export** (menu: JSON full backup, CSV entries, CSV summary), **Restore from backup** (JSON only via file importer), **Reset All Data** (confirmation).
- **Support:** Privacy Policy, Contact & Support (from Info.plist).
- **About:** Version 1.0.0, habit count, total entries.

### 0.7 Widgets & system
- **Widget:** one **systemSmall** (“Ritual Log”) – Today’s completed/total and progress bar; timeline refreshes at midnight. No lock screen, no medium/large, no tap-to-complete.
- **App Intents:** ToggleHabitIntent (by **habit ID**). App Shortcuts: “Complete a habit in Ritual Log” / “Mark habit done in Ritual Log” (Siri + Shortcuts). No parameterized “Complete [habit name]” discovery.

### 0.8 Platforms & sync
- **iOS** (primary), **macOS** (shared UI). **watchOS:** stub “Habits” view only.
- **Sync:** Sign in with Apple; iCloud/CloudKit (container); “Sync now” triggers sync; no location-based or habit-stacking reminders.

### 0.9 Gaps (not in app today)
- No goals/targets (“X times per week/month”).
- No streak freeze / vacation mode.
- No notes or mood per check-in.
- No location-based or habit-stacking reminders.
- No Apple Health integration.
- No lock screen or interactive widgets; no “Complete [habit name]” Siri.
- No PDF/advanced export; no themes beyond System/Light/Dark.
- No in-app purchase or subscription; ads (iOS) with no way to remove.

---

## 1. Research Summary: What Drives App Purchases

### 1.1 Psychological Drivers of In-App Purchase

| Factor | Finding | Implication for Ritual Log |
|--------|---------|----------------------------|
| **Perceived value** | Playfulness, connectedness, flexibility, and reward drive loyalty → IAP intention. “Good price” and loyalty are the two values that most directly predict purchase. | Deliver clear, tangible value in Premium; avoid vague “pro” labels. |
| **Perceived fairness** | Fairness increases likelihood of *ever* spending; perceived *aggressive* monetization (reactance + unfairness) is a major barrier. | No dark patterns. Transparent pricing. Don’t gate core habit-tracking behind paywall. |
| **App stickiness** | Time in app and consistent engagement (stickiness) predict purchase intention. | Invest in retention (onboarding, streaks, widgets) so users form a habit of using the app before seeing paywall. |
| **Attitude & social** | Subjective norms and perceived behavioral control influence IAP intention. | Social proof (“Join 10k+ Premium users”), clear benefits list, and “Restore purchases” build trust. |
| **Emotional engagement** | Flow, enjoyment, hedonic satisfaction mediate purchase decisions. | Completion feedback, streaks, and small celebrations reinforce positive association with the app. |

**Sources:** Extended Planned Behavior models for IAP; perceived value & loyalty (e.g. Hsiao et al.); perceived fairness vs. aggressive monetization (Springer, SSRN).

### 1.2 Conversion: Free → Paid

| Mechanism | Finding | Implication |
|-----------|---------|-------------|
| **Endowment effect** | People value what they “own.” Once users invest time in the app, they’re more likely to pay to keep it. | Free tier should be fully usable so users build real habit data and attachment. |
| **Loss aversion** | Loss is felt ~2× more than gain. “Lose access to Premium” at trial end is a strong conversion lever. | Free trial (e.g. 7–14 days) with clear “You’ll lose X” messaging. |
| **IKEA effect** | Investment of effort (e.g. setting up habits, logging) increases attachment. | Onboarding and early setup should feel productive, not blocked by paywalls. |
| **First purchase** | Barriers (fairness, self-control) affect *whether* users spend at all; after first purchase, spending can become more impulsive. | “Remove Ads” as a low-friction first purchase can open the door to Premium later. |

**Sources:** Endowment effect & free trials (GetMonetizely, UX Planet); freemium conversion (Adapty); trial-to-paid workflows.

### 1.3 What to Avoid

- **Aggressive monetization:** Paywalls on core flows (e.g. “complete a habit”) or constant pop-ups → reactance and refusal to pay.
- **Hiding value:** Showing premium features with “Upgrade to access” converts ~17% better than hiding them entirely.
- **Unfair limits:** Arbitrary caps that feel punitive (e.g. “3 habits only”) can work for some apps (Habitify) but feel harsh if the app has always been unlimited; introduce limits only with care and clear value exchange.

---

## 2. Monetization Model for V3

### 2.1 Two-Tier Structure

| Tier | Mechanism | Goal |
|------|-----------|------|
| **Remove Ads** | One-time IAP (StoreKit 2) | Capture users who want an ad-free experience but resist subscriptions. Acts as a low-friction first purchase. |
| **Premium** | Auto-renewable subscription (monthly + annual; optional lifetime) | Recurring revenue; power users and those who want advanced features. |

**Hybrid rationale:** Industry data suggests hybrid (ads + IAP + subscription) yields meaningfully higher ARPU and retention than a single model. “Remove Ads” and Premium serve different segments and can coexist.

### 2.2 What Stays Free (Baseline)

All of **Section 0 (Current App)** remains free except ad visibility:

- Full habit CRUD, unlimited habits (no cap).
- Home: today list, progress ring, Active / Scheduled / Completed cards, complete / skip / unskip (with optional reason), skip doesn’t break streak.
- All calendar views (daily, weekly, monthly, yearly) with skip/unskip.
- Statistics: 26-week contribution graph, Week/Month/Year/All Time, Total Habits / Total Completions / Current Streaks, Top Performing Habits, Longest Streaks.
- Reminders: multiple per habit (time, label, sound) plus optional “every N minutes” with end time.
- Export: JSON (full backup), CSV (entries), CSV (summary). Restore from backup (JSON only).
- Account (Sign in with Apple), Sync now (iCloud/CloudKit).
- One systemSmall “Today” widget; Siri/Shortcuts (complete by habit ID; no “Complete [habit name]” yet).
- Onboarding and 24 templates in 6 categories.
- Appearance: color (presets + custom), emoji; Theme: System / Light / Dark.

**Ads (iOS only):** Shown on Home in the existing ad card for users who have not purchased “Remove Ads” or Premium.

### 2.3 Remove Ads (One-Time IAP)

- **Entitlement:** User no longer sees the ad card on Home (iOS). No other feature change.
- **Persistence:** Restore via StoreKit 2 (transaction history / currentEntitlements).
- **Pricing:** Set at a one-time price that feels fair and is comparable to “tip” or “coffee” pricing (e.g. $2.99–$4.99). A/B test if needed.
- **UX:** In Settings, “Remove Ads” row: if not purchased, show price and purchase; if purchased, show “Ads removed” and optionally “Restore purchases.”

### 2.4 Premium Subscription

- **Includes:** Remove Ads + all Premium features below.
- **Pricing (suggested; validate with real users):**
  - **Monthly:** e.g. $4.99–$6.99/month (anchor for annual).
  - **Annual:** e.g. $29.99–$39.99/year (~$2.50–$3.33/month) — “Best value” and default upsell.
  - **Lifetime (optional):** e.g. $59.99–$79.99 one-time; limited-time or permanent offer.
- **Trial:** 7- or 14-day free trial for Premium to let users build endowment and see value before card on file.
- **Family Sharing:** Support if we use subscriptions (Apple’s subscription Family Sharing).

---

## 3. Premium Feature Set (Research- and Competitor-Informed)

### 3.1 Feature Ideas (Prioritized)

| Feature | Current state in app | Premium adds | Effort | Priority |
|---------|----------------------|--------------|--------|----------|
| **Remove Ads** | Ad card on Home (iOS) for all. | No ad card when purchased or Premium. | IAP only. | P0 |
| **Advanced analytics & insights** | Contribution graph (26 weeks), 3 stat cards, top habits, longest streaks, timeframe filter. | Trends over time, “best day/time,” weekly/monthly summary insights, exportable insights. | Medium. | P0 |
| **Goals / targets** | None. | “Complete at least X times per week/month” per habit with progress. | Medium. | P0 |
| **Streak freeze / vacation mode** | None. | Mark days as “vacation” so streak isn’t broken; user-requested in many apps. | Low–medium. | P1 |
| **Notes or mood per check-in** | None. | Optional note or mood per completion (or per day) for journaling and stickiness. | Medium. | P1 |
| **Location-based reminders** | Time + weekday only. | “When I leave/arrive [place]” (CLLocationManager). | Medium. | P1 |
| **Habit stacking reminders** | None. | “Remind me after [Habit A]” (after current habit completes). | Medium. | P1 |
| **More widgets** | One systemSmall “Today” (read-only). | Lock screen widget, medium/large home screen, interactive (tap to complete). | Medium. | P1 |
| **Apple Health integration** | None. | Auto-complete habits from steps, workouts, mindful minutes, etc. | Medium–high. | P2 |
| **Advanced export** | JSON + CSV (entries) + CSV (summary). | CSV with date filters, PDF reports (e.g. monthly summary). | Low–medium. | P2 |
| **Themes / accent customization** | Theme: System / Light / Dark only. | Accent color or extra themes for personalization. | Low. | P2 |
| **Siri “Complete [habit name]”** | Toggle by habit ID in Shortcuts; generic “Complete a habit” phrase. | Parameterized “Complete [habit name]” discoverable in Shortcuts. | Medium. | P2 |

### 3.2 What We Explicitly Do *Not* Gate in Free

- Core loop: creating habits, completing/skipping, viewing today and calendar.
- Sync and backup (export/restore) — keep as differentiator for trust.
- Single “Today” widget and current Siri complete-by-ID.

This keeps perceived fairness high and avoids “aggressive monetization” that research shows blocks first purchase.

---

## 4. Pricing Psychology Checklist

- **Anchoring:** Annual as “Best value” and default option; monthly as higher per-month.
- **Fairness:** Clear list of what’s free vs. Premium; no surprise paywalls mid-flow.
- **Visibility of value:** Show Premium features in-app with “Premium” badge and “Upgrade to access” rather than hiding them.
- **Trial:** 7–14 day Premium trial; remind before trial ends with loss-framed message (“You’ll lose access to…”).
- **Restore purchases:** Prominent in Settings and on paywall to build trust and reduce support.
- **Localization:** Plan for local currency and localized copy (e.g. “Remove Ads” vs. “Premium” messaging).

---

## 5. Implementation Phases

### Phase 1 – Foundation (V3.0)

- **StoreKit 2 setup:** Products for “Remove Ads” (consumable/non-consumable or non-consumable) and Premium (monthly + annual subscriptions).
- **Entitlement state:** Single source of truth (e.g. `EntitlementManager` or `PurchaseManager`) for `hasRemovedAds` and `hasPremium`.
- **UI:**  
  - Show ad card on Home (iOS) only when `!hasRemovedAds && !hasPremium`.  
  - Settings: “Remove Ads” and “Premium” / “Manage subscription” with restore.
- **Paywall:** One clear paywall screen (e.g. modal) listing Premium benefits and trial; show after onboarding or from Settings.
- **Privacy & legal:** Update privacy policy if we add subscription/IAP (e.g. no new data; mention “purchase history” handled by Apple). Link to terms if needed for subscriptions.

### Phase 2 – Premium Features (V3.1+)

- Ship Premium features in order of priority (e.g. advanced analytics, goals, streak freeze, notes/mood).
- Gate each behind `hasPremium` with soft prompts (“Upgrade to Premium to unlock”) and deep link to paywall.
- Optional: A/B test paywall copy and trial length (7 vs 14 days).

### Phase 3 – Optimization (Ongoing)

- Monitor conversion (free → Remove Ads, free → Premium trial, trial → paid).
- Experiment with pricing (e.g. annual discount, lifetime offer windows).
- Consider “Premium Lite” only if data shows a segment that would pay for a subset (e.g. “Remove Ads + Goals only”) without cannibalizing full Premium.

---

## 6. Technical Notes

- **StoreKit 2:** Use `Transaction.currentEntitlements` and `Product.SubscriptionInfo` for subscription status; listen for `Transaction.updates` and update entitlement state.
- **Persistence:** Store “Remove Ads” and subscription state in memory + UserDefaults or in-memory only and re-derive from StoreKit on launch.
- **Server (optional):** No server required for entitlement checks; Apple’s receipt/transaction APIs are sufficient. Optional server-side receipt validation for extra security later.
- **Testing:** StoreKit Configuration file in Xcode for sandbox products and subscription testing.

---

## 7. Success Metrics

- **Remove Ads:** Conversion rate (free → one-time purchase); revenue per paying user.
- **Premium:** Trial start rate, trial → paid conversion, churn (monthly/annual), LTV by cohort.
- **Fairness/UX:** Support tickets about “unexpected” paywalls; App Store review sentiment related to pricing.

---

## 8. References (Summary)

- **Behavioral / IAP:** Extended Planned Behavior and IAP intention; perceived value & loyalty (IEEE, Sci-Hub); perceived fairness vs. aggressive monetization (Springer, SSRN); app stickiness and IAP (ScienceDirect).
- **Conversion:** Endowment effect & free trials (GetMonetizely, UX Planet); freemium conversion (Adapty); trial-to-paid (Medium); pricing psychology (Apphud).
- **Monetization:** Hybrid ads + IAP + subscription (Rehmall, RevenueCat, Appwill); Habitify pricing (habitify.me); mobile app monetization 2025/2026 (Adapty, Apps Finboard).

---

*Document version: 1.1. Last updated: March 2026. Aligned with current app inventory (Section 0) and Premium “current vs. adds” (Section 3.1).*
