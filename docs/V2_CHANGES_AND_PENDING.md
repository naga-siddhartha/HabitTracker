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

### Not done on this branch (by design)
- [ ] **Privacy policy** – Left unchanged. To be updated when merging v2 to main (account data, Sign in with Apple, optional iCloud/CloudKit sync).

---

## Pending Before Merge to Main & Release

### Before merge
1. **Privacy policy** – Update `Habit-Tracker-App-push/index.html` (or app’s policy URL) for:
   - Sign in with Apple (user identifier, optional name/email).
   - Optional iCloud/CloudKit sync and backup.
   - Section 5: transmission of habit data when signed in (iCloud only).
   - “Last updated” date.

### Before release (optional / as needed)
2. **CloudKit (optional)** – If shipping sync: enable iCloud + CloudKit in Xcode; add container to entitlements; consider wiring `createModelContainer(useCloudKit: true)` when signed in (and container lifecycle).
3. **App Store** – Metadata for “Sign in with Apple” and “iCloud” if applicable.
4. **QA** – Run through Phase 1 QA scenarios (account, import, skip, onboarding, accessibility, regressions).

---

## Reference

- Plan: [.cursor/plans/ritual_log_v2_plan_032c0f1a.plan.md](../.cursor/plans/ritual_log_v2_plan_032c0f1a.plan.md) (or project plan file).
- Roadmap: [docs/RITUAL_LOG_V2_ROADMAP.md](RITUAL_LOG_V2_ROADMAP.md).
