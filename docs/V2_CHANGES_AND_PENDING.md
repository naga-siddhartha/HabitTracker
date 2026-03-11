# Ritual Log v2 – Changes Made & Pending

Track of what is done on the v2 branch and what remains before merging to main and releasing v2.

---

## Branch

- **Branch name:** `ritual-log-v2` (or `feature/ritual-log-v2`)
- **Base:** `main`

---

## Changes Made (Phase 1 MVP v2)

### Schema & migration
- [x] Added optional `userId: String?` to `Habit`, `HabitEntry`, and `Streak` in `HabitTracker/Models/Habit.swift`.
- [x] Updated inits with default `userId = nil`; local-only when `userId == nil`.

### Account (Sign in with Apple)
- [x] **KeychainHelper.swift** – Keychain read/write for user identifier.
- [x] **AuthService.swift** – Sign in with Apple flow, `ObservableObject`, stores identifier in Keychain; presentation anchor for iOS/macOS.
- [x] **Settings** – New “Account” section at top: Signed in / Sign in / Sign out, loading and error handling.
- [x] **HabitTracker.entitlements** – Added `com.apple.developer.applesignin` (Default).

### Sync / CloudKit
- [x] **AppConfig.swift** – `createModelContainer(useCloudKit: Bool = false)`; when `true` uses `cloudKitDatabase: .automatic` for future sync. Default remains `.none`.

### Import from v1 JSON
- [x] **ImportService.swift** – Parses `ExportService.ExportData`, `restoreFromExport` / `replaceAllAndRestore` / `deleteAllHabits`.
- [x] **Settings** – “Restore from backup” with file importer (.json), confirmation, success/error alerts, Retry; widget refresh after restore.

### Skip day UI
- [x] **SharedComponents** – `HabitRowActions` extended with skip/unskip/skip-with-reason; `SkipReasonSheetView` and `SkipReasonSheetItem`.
- [x] **DailyView / DailyHabitRow** – Skip/Unskip/Skip with reason in context menu; skip reason sheet; skipped state (orange, “Skipped”).
- [x] **HomeView / ChecklistRow** – Same skip actions and skip state.
- [x] **WeeklyView / DayDot** – Context menu skip/unskip per day; skip reason sheet; orange pause for skipped.
- [x] **MonthlyView / MonthlyHabitRow** – Skip/Unskip/Skip with reason; skip reason sheet; skipped state.

### Accessibility
- [x] ProgressRing – `accessibilityLabel` / `accessibilityValue`.
- [x] StatCard – label, value, hint.
- [x] Contribution graph and cells – labels and values.
- [x] MainTabView – hints for tabs.
- [x] ChecklistRow – combined label and hint.
- [x] Add-habit button – label and hint.

### Onboarding
- [x] **OnboardingView.swift** – Single screen, “Get started” sets `hasCompletedOnboarding`, dismisses, then presents template picker.
- [x] **MainTabView** – `@AppStorage("hasCompletedOnboarding")`, `fullScreenCover` for onboarding.

### Core UI polish
- [x] Settings – Export failure alert; import error alert with Retry; Account at top; loading states for export/import.

### Phase 1 review & cleanup
- [x] Removed dead code (e.g. `authCredential` from AuthService).
- [x] Organized code with MARK sections (AuthService, KeychainHelper, ImportService).
- [x] Used `ImportError.invalidData` for empty backup data in `parseExportData`.

### Apple policy compliance (Phase 1)
- [x] **Account deletion (Guideline 5.1.1(v))** – "Delete account" in Account profile with confirmation; removes sign-in and Keychain data; alert explains revoking in Settings → Apple ID.
- [x] **Internal privacy policy** – `docs/privacy.html` is the single source of truth (Sign in with Apple, account data, optional iCloud/CloudKit, transmission, deletion). Copy to the RitualLog repo as `privacy.html` when updating the public site. See **Privacy policy** below.

### Research-first v2 items (implemented with sensible defaults)
- [x] **Color/emoji picker in Add/Edit habit** – New “Appearance” section in `AddEditHabitView`: color grid (all `HabitColor` options), emoji picker with “Suggested” + horizontal list (`HabitEmoji.pickerEmojis`). User can choose color and emoji when creating or editing a habit.
- [x] **“Skip doesn’t break streak” messaging** – Skip sheet: Section footer “Skipping doesn’t break your streak. Your progress is preserved.” Onboarding: added “Skip a day when you need to—your streak stays intact.” plus “Start with a template or create your first habit.”
- [x] **Dedicated “all habits” list** – Implemented then **removed for v2:** Habits tab and `AllHabitsListView` were removed; tabs are Home, Calendar, Stats, Settings. List view file was deleted as dead code.

### Add/Edit habit – custom emoji
- [x] **Custom emoji field** – In Add/Edit habit Appearance section: “Or type / paste your own emoji” TextField; first character used as habit emoji. Suggested and grid choices clear custom; custom input overrides suggested on save.

### CloudKit / iCloud sync
- [x] **Entitlements** – `HabitTracker.entitlements` includes iCloud + CloudKit (container `iCloud.com.nagasiddharthadonepudi.HabitTracker`). Both iOS and Mac targets use this file.
- [x] **ModelContainerProvider** – Single store URL (`AppConfig.habitStoreURL()`); container created at launch with or without CloudKit based on sign-in. On sign-in, container is recreated with CloudKit (switch to in-memory first to avoid duplicate CloudKit handler).
- [x] **Sync** – "Sync now" only saves and reloads widgets; it does not recreate the container. CloudKit sync is automatic with the single container. **Info.plist:** `UIBackgroundModes` includes `remote-notification` for CloudKit push.
- [x] **Schema** – Habit/HabitEntry/Streak: optional attributes with defaults; `entries` relationship optional for CloudKit compatibility; `entriesOrEmpty` used in code.

### Account UI
- [x] **Account entry points** – **iOS:** Account icon in Home header (inline with day title). **Mac:** Account icon in window toolbar (top right) via `.withAccountToolbar(accountMenuState:)`. **Settings:** "Account settings" row opens `AccountSettingsView` (sign in, profile, Sync now, sign out).
- [x] **AccountMenuView** – Used for toolbar (Mac) and menu (Account, Sync now, Sign out / Sign in); takes `accountMenuState` to avoid environment-object crash in sheet.

### AuthService & AccountMenuView fixes (Swift 6 / macOS / hang risk)
- [x] **AuthService** – Swift 6: nonisolated delegate uses `Self._sharedRef` instead of MainActor-isolated `shared`; `_sharedRef` set in init. Priority inversion: Keychain save and continuation resume moved to `DispatchQueue.global(qos: .userInitiated)`. Explicit capture in MainActor Task: use `service` (from `_sharedRef`) for state updates.
- [x] **AccountMenuView** – Added `import Combine` for ObservableObject/@Published. macOS: toolbar placement uses `.primaryAction` when not iOS (`.topBarTrailing` unavailable on macOS).

### Not done on this branch (by design)
- [ ] **Public privacy policy URL** – Point app’s Privacy Policy URL (Info.plist / public site) at the updated policy once you copy `docs/privacy.html` to the RitualLog repo and deploy.

---

## Privacy policy

- **Source of truth:** `docs/privacy.html` in this repo. This is the v2 policy with Sign in with Apple, account data, optional iCloud sync, and account/habit deletion. Last updated: March 2026.
- **Public site:** Copy `docs/privacy.html` to the **RitualLog** repo as `privacy.html`, then deploy. The app’s Privacy Policy URL (Info.plist / App Store) points to that site.

---

## Signing & Capabilities (fix provisioning errors)

If you see **"No Accounts"** or **"Provisioning profile doesn't include the Sign In with Apple capability"**:

1. **Add your Apple ID in Xcode**
   - **Xcode → Settings… (or Preferences) → Accounts**
   - Click **+** (bottom left) → **Apple ID** → sign in with your Apple ID.
   - A free Apple ID works for running on your device; **App Store distribution** needs an [Apple Developer Program](https://developer.apple.com/programs/) membership.

2. **Select the correct team**
   - In the project navigator, select the **HabitTracker** project (blue icon).
   - Select the **HabitTracker** target.
   - Open the **Signing & Capabilities** tab.
   - Under **Signing**, set **Team** to your account (e.g. "Your Name (Personal Team)" or your developer team).

3. **Add Sign in with Apple in Xcode**
   - In **Signing & Capabilities**, click **+ Capability**.
   - Search for **Sign in with Apple** and double‑click it.
   - Xcode will add it to the entitlements and register it with your provisioning profile. (Our entitlements file already has `com.apple.developer.applesignin`; adding the capability here ensures the profile is updated.)

4. **Let Xcode fix the profile**
   - If errors persist, turn **Automatically manage signing** off and on, or use **Signing (Debug)** / **Signing (Release)** and re-select the same team so Xcode regenerates the profile.

5. **Clean and build**
   - **Product → Clean Build Folder**, then build again (**⌘B**).

If you don’t want to use Sign in with Apple yet (e.g. no Apple ID in Xcode), you can temporarily remove the `com.apple.developer.applesignin` entry from **HabitTracker.entitlements** so the project builds; the Settings “Account” section will still appear, but “Sign in with Apple” will fail until the capability is re-added and the profile is fixed.

---

## Pending Before Merge to Main & Release

### Before merge
1. **Privacy policy (public)** – Copy `docs/privacy.html` from this repo to the RitualLog repo as `privacy.html` and deploy so the app’s Privacy Policy URL serves the v2 policy.

### Before release (optional / as needed)
2. **CloudKit sync (enabled)** – Sync is wired so habits can appear on both iPhone and Mac:
   - **Entitlements:** `HabitTracker.entitlements` includes iCloud + CloudKit with container `iCloud.com.nagasiddharthadonepudi.HabitTracker`. Both iOS and Mac targets use this file.
   - **In Xcode:** Ensure the **iCloud** capability is enabled for both HabitTracker and HabitTracker Mac: check **CloudKit** and add/select the container `iCloud.com.nagasiddharthadonepudi.HabitTracker`. If the capability was never added, use **Signing & Capabilities → + Capability → iCloud** and enable CloudKit with that container.
   - **Background Modes (iOS):** `Info.plist` includes `UIBackgroundModes` → `remote-notification`. In Xcode, enable **Background Modes → Remote notifications** for the iOS target.
   - **Usage:** Sign in with Apple on both devices; same iCloud account. Container is created at launch (or recreated on sign-in via `ModelContainerProvider`). "Sync now" does not recreate the container; sync is automatic. If habits don’t appear on Mac after sign-in, wait a few seconds for the delayed container switch, or restart the app.
3. **App Store** – Metadata for “Sign in with Apple” and “iCloud” if applicable.
4. **QA** – Run through Phase 1 QA scenarios (account, import, skip, onboarding, accessibility, regressions).

---

## Pending (Research-First) – Implement After User Research

The three items below were **implemented with sensible defaults** (see “Research-first v2 items” and “Add/Edit habit – custom emoji” under Changes Made). Future UX changes (e.g. reorder in All habits list, different placement for skip messaging) can be informed by user research.

| Item | Status | Notes |
|------|--------|--------|
| **Color/emoji picker in Add/Edit habit** | Done | Appearance section: color grid, emoji “Suggested” + picker list, custom “type/paste your own” field. |
| **Dedicated “all habits” list** | Removed | Habits tab and AllHabitsListView removed for v2; tabs are Home, Calendar, Stats, Settings. |
| **“Skip doesn’t break streak” messaging** | Done | Skip sheet footer + onboarding line. |

**Process for future research-first items:** Complete user research first, document findings and chosen pattern, then add to the implementation backlog and build accordingly.

---

## Reference

- Plan: [.cursor/plans/ritual_log_v2_plan_032c0f1a.plan.md](../.cursor/plans/ritual_log_v2_plan_032c0f1a.plan.md) (or project plan file).
- Roadmap: [docs/RITUAL_LOG_V2_ROADMAP.md](RITUAL_LOG_V2_ROADMAP.md).
