# Habit: Grab It - KPIs and where to see them

Two sources, no backend:

- **App Store Connect + Xcode Organizer** (Apple, free, no code). Counts only users who agreed to share analytics with developers, so treat the numbers as a sample.
- **TelemetryDeck** (one Swift package, privacy-first, EU-hosted). Every device that has "Share anonymous usage stats" on. Sends app version, OS, device type, an anonymized user hash, sessions, plus the events below. Never habit names, notes, emoji or history.

## North-star and health KPIs

| KPI | Definition | Source |
|---|---|---|
| Daily / monthly active users (DAU, MAU) | Unique users with a session that day / in the last 30 days | TelemetryDeck (all opted-in users), App Store Connect "Active Devices" (sample) |
| Stickiness | DAU / MAU. Habit apps live or die on this; aim for 40%+ | TelemetryDeck |
| Retention D1 / D7 / D30 | % of new installs still active after 1, 7, 30 days | App Store Connect > Analytics > Retention |
| Activation rate | New users who create a first habit / new users | `Onboarding.completed` vs first `Habit.created` |
| Daily completion rate | Share of devices whose `completionYesterday` is "50-99%" or "100%" | `Daily.summary` |
| Streak health | Distribution of `bestCurrentStreak` buckets | `Daily.summary` |
| Feature adoption | % of summaries with `usesReminders`, `usesIntervalHabits`, `usesWeeklyHabits`, `usesSkip`, `hasWidget`, `iCloudSync` = true | `Daily.summary` |
| Reminder reach | % with `notificationsAllowed` = true. Low numbers mean reminders aren't landing | `Daily.summary` |
| Churn signal | `Habit.deleted` rate, and users whose `habits` bucket drops to "0" | TelemetryDeck |
| Remove Ads conversion | Purchases / MAU (added with the Phase 3 purchase) | App Store Connect > Monetization |

## Performance and quality KPIs

| KPI | Source |
|---|---|
| Crash-free sessions / crash rate | Xcode Organizer > Crashes, App Store Connect |
| Hang rate | Xcode Organizer > Hangs |
| Launch time (p50 / p90) | Xcode Organizer > Launch Time; `Performance.launch` buckets in TelemetryDeck |
| Sync failure rate | `Sync.error` / users with `iCloudSync` = true |
| Disk writes, memory, battery | Xcode Organizer |

## Events sent

| Event | When | Parameters |
|---|---|---|
| `TelemetryDeck.Session.started` | Automatic, each launch | SDK defaults |
| `Daily.summary` | First time the app becomes active each day | `habits`, `dueYesterday`, `doneYesterday` (bucketed counts), `completionYesterday`, `bestCurrentStreak` (buckets), `usesReminders`, `usesIntervalHabits`, `usesWeeklyHabits`, `usesSkip`, `iCloudSync`, `notificationsAllowed`, `hasWidget`, `appearance` |
| `Onboarding.completed` | Onboarding dismissed the first time | none |
| `Habit.created` | New habit saved | `fromTemplate`, `hasReminder`, `isInterval`, `isWeekly` |
| `Habit.deleted` | Habit deleted | none |
| `Backup.exported` / `Backup.restored` | Export / restore | `format` |
| `Account.signedIn` / `Account.deleted` | Sign in with Apple / delete account | none |
| `Sync.error` | First iCloud sync failure in a launch | none |
| `Performance.launch` | Once per launch, first screen shown | `launchBucket` |

Budget: about 3-5 events per active user per day, so the 50k-event free tier covers a few hundred monthly users, and the entry paid tier covers far more.

## Setup checklist

1. Create a TelemetryDeck account and app, copy its App ID.
2. Xcode: File > Add Package Dependencies > `https://github.com/TelemetryDeck/SwiftSDK`, add the `TelemetryDeck` product to the iOS and Mac app targets.
3. Paste the App ID into `TelemetryDeckAppID` in `HabitTracker/Info.plist`. Until then nothing is sent.
4. App Store Connect > App Privacy: add **Usage Data > Product Interaction** and **Diagnostics > Performance Data**, both "Not linked to identity", "Not used for tracking", purpose "Analytics".
5. Publish the updated privacy policy (website repo) before shipping the build.
6. In TelemetryDeck, build dashboards for the KPIs above (DAU/MAU, retention, the summary breakdowns).
