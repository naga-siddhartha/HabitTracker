---
name: habittracker-cloud-agent-starter
description: Minimal run/test playbook for Cloud agents working in this HabitTracker Apple-platform codebase.
---

# HabitTracker Cloud agent starter skill

## When to use this skill
- You are a Cloud agent making code changes in this repository and need to run, test, or validate behavior quickly.
- You need practical commands for app startup, account/iCloud setup, and high-signal test workflows by area.

## Quick reality check (Cloud environment)
- This is an Xcode/iOS/macOS codebase. Full app execution requires a macOS runner with Xcode.
- If you are on a non-macOS Cloud box, do static/code-level checks and prepare exact `xcodebuild` commands for a macOS agent to run.

## 1) Repo bootstrap and first run
1. Confirm project structure:
   - `HabitTracker.xcodeproj`
   - `HabitTracker/`, `HabitTrackerTests/`, `HabitTrackerUITests/`, `HabitTrackerWidgetExtension/`
2. On macOS + Xcode, list schemes:
   - `xcodebuild -project HabitTracker.xcodeproj -list`
3. Build app target on a simulator:
   - `xcodebuild -project HabitTracker.xcodeproj -scheme "HabitTracker" -destination 'platform=iOS Simulator,name=iPhone 16' build`
4. If build settings get stale, clean and rebuild:
   - `xcodebuild -project HabitTracker.xcodeproj -scheme "HabitTracker" clean build`

## 2) Account login + CloudKit sync area

### Required setup before testing account flows
1. In Xcode: add Apple ID and select a valid Team in Signing.
2. Ensure capability alignment for app target:
   - Sign in with Apple enabled.
   - iCloud + CloudKit enabled with container `iCloud.com.nagasiddharthadonepudi.HabitTracker`.
3. Keep `remote-notification` background mode enabled for iOS target.

### Practical workflow (manual)
1. Launch app.
2. Open `Settings` -> `Account settings`.
3. Tap **Sign in with Apple** and complete auth.
4. Verify post-login state:
   - Account row shows signed-in identity.
   - **Sync now** is available.
5. Tap **Sync now** and verify syncing indicator clears.

### Testing checklist for this area
- Happy path: sign in -> sync now -> no auth error alert.
- Error path: cancel Apple sign-in -> app surfaces cancellation safely (no hang/crash).
- Sign-out path: sign out returns to signed-out UI state.

## 3) App state toggles ("feature flag" style) and mocks
- There is no dedicated feature-flag service yet; use persisted local state toggles as practical switches.

### Useful local toggles
- Onboarding gate: `hasCompletedOnboarding` (`UserDefaults` / `@AppStorage`).
- Notifications switch: `notificationsEnabled` (`UserDefaults` / `@AppStorage`).
- Theme mode: `appearanceMode` (`UserDefaults` / `@AppStorage`).

### Fast reset/mocking workflow (simulator)
1. Erase simulator state for a clean app run:
   - `xcrun simctl erase all`
2. Or surgically reset onboarding only:
   - `xcrun simctl spawn booted defaults delete com.nagasiddharthadonepudi.HabitTracker hasCompletedOnboarding`
3. Re-launch app and verify expected entry state (onboarding visible or skipped).

## 4) Data flows (import/export/reset) area

### Practical workflow
1. Launch app -> `Settings` -> `Data`.
2. Run **Export Data** (JSON preferred for full backup).
3. Run **Restore from backup** with that JSON.
4. Run **Reset All Data**.

### Testing checklist for this area
- Export creates shareable file without error alert.
- Restore succeeds and "Restore complete" appears.
- Reset clears habits/entries and app remains responsive.

## 5) Widget extension area

### Build/test workflow
1. Build widget extension target:
   - `xcodebuild -project HabitTracker.xcodeproj -scheme "HabitTrackerWidgetExtensionExtension" -destination 'platform=iOS Simulator,name=iPhone 16' build`
2. In app, create/update habits so today's completion counts change.
3. Verify widget reflects updated `(completed/total)` values after timeline reload.

### Testing checklist for this area
- Widget reads shared app-group values (not always zero after data changes).
- Progress bar and counts update after app writes widget data.

## 6) Automated test workflows by codebase area

### Model/domain tests (`HabitTrackerTests`)
- Primary command:
  - `xcodebuild test -project HabitTracker.xcodeproj -scheme "HabitTracker" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HabitTrackerTests`
- Use when changing models, streak logic, import/export parsing, utility logic.

### UI smoke tests (`HabitTrackerUITests`)
- Primary command:
  - `xcodebuild test -project HabitTracker.xcodeproj -scheme "HabitTracker" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HabitTrackerUITests`
- Use for launch regressions and critical navigation flows.

### High-signal manual smoke pass after UI changes
1. Launch app to Home.
2. Visit tabs: Home, Calendar, Stats, Settings.
3. Open `Account settings`.
4. Run one Data action (export or reset).
5. Confirm no crash/hang and no blocking alert loops.

## 7) Common failure triage (first 5 minutes)
- Signing/provisioning error: re-select Team, toggle "Automatically manage signing", clean, rebuild.
- Sign in with Apple missing capability: re-add capability in target Signing & Capabilities.
- CloudKit not syncing: verify same iCloud account on test devices/simulators and container name matches entitlements.
- Widget not updating: confirm app group identifier is exactly `group.com.nagasiddharthadonepudi.HabitTracker` in both app + widget entitlements.

## 8) Keep this skill current (required maintenance)
Whenever you discover a new testing trick/runbook fix:
1. Add it to the relevant section above (do not create a random notes section).
2. Include:
   - exact command/UI path,
   - when to use it,
   - expected success signal.
3. If it replaces an older step, delete the old step in the same commit.
4. Keep this file minimal: practical first, theory last.
