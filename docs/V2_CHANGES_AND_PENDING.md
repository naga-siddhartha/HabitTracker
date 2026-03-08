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
- [x] **Internal privacy policy** – `docs/privacy.html` is the canonical v2 policy (Sign in with Apple, account data, optional iCloud/CloudKit, transmission, deletion). When ready to publish, copy to the public repo (e.g. `Habit-Tracker-App-push/index.html` or `privacy-page-public/index.html`). See **Privacy policy (internal vs public)** below.

### Not done on this branch (by design)
- [ ] **Public privacy policy URL** – Point app’s Privacy Policy URL (Info.plist / public site) at the updated policy once you copy `docs/privacy.html` to the public repo and deploy.

---

## Privacy policy (internal vs public)

- **Internal canonical copy:** `docs/privacy.html` in this repo. This is the v2 policy with Sign in with Apple, account data, optional iCloud sync, and account/habit deletion. Last updated: March 2026.
- **When ready to publish:** Copy `docs/privacy.html` to wherever your public-facing policy lives (e.g. the `Habit-Tracker-App-push` or `privacy-page-public` repo’s `index.html`), then deploy so the URL in Info.plist / App Store points to the updated page.

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
1. **Privacy policy (public)** – Copy `docs/privacy.html` from this repo to your public policy repo (e.g. `Habit-Tracker-App-push/index.html` or `privacy-page-public/index.html`) and deploy so the app’s Privacy Policy URL serves the v2 policy. Content is already in `docs/privacy.html`.

### Before release (optional / as needed)
2. **CloudKit (optional)** – If shipping sync: enable iCloud + CloudKit in Xcode; add container to entitlements; consider wiring `createModelContainer(useCloudKit: true)` when signed in (and container lifecycle).
3. **App Store** – Metadata for “Sign in with Apple” and “iCloud” if applicable.
4. **QA** – Run through Phase 1 QA scenarios (account, import, skip, onboarding, accessibility, regressions).

---

## Reference

- Plan: [.cursor/plans/ritual_log_v2_plan_032c0f1a.plan.md](../.cursor/plans/ritual_log_v2_plan_032c0f1a.plan.md) (or project plan file).
- Roadmap: [docs/RITUAL_LOG_V2_ROADMAP.md](RITUAL_LOG_V2_ROADMAP.md).
