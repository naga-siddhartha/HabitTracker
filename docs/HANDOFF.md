# Handoff: where the modernization stands

Read this first, then `docs/MODERNIZATION_PLAN.md`, `docs/CODE_STYLE.md`, `docs/METRICS.md`.

## Repo state
- Branch: `modernization/phase-5-ui` (not pushed, not merged). Commit only when asked; never push unless asked.
- Targets: `HabitTracker` (iOS 17.6+), `HabitTracker Mac` (macOS 14+, same sources via synchronized group),
  widget extension, unit + UI tests. Swift 6, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on app targets
  (`@Model` types and pure helpers are `nonisolated`).
- New files are picked up automatically (PBXFileSystemSynchronizedRootGroup). Don't discard Xcode's pbxproj edits.

## Phase status
- Phases 1, 2, 4: done, tests passing on iOS.
- Phase 3 (metrics): code done. Owner to-do: add TelemetryDeck package, set `TelemetryDeckAppID` in Info.plist,
  App Privacy answers, merge website branch `privacy-usage-stats` (Habit-GrabIt repo) when shipping.
- Phase 5 (UI): ~80%. Done: Liquid Glass, violet/gold brand, Home snapshot + next-habit copy, progress ring
  (next habit emoji, gold check draw-on: `.symbolEffect(.drawOn)` API unverified), milestones banner,
  inline color swatches, compact emoji sheet. Remaining: widgets (tap to complete, lock screen,
  Control Center, brand colors), accessibility pass, resizable iPhone layout check.

## Immediate next task: macOS app
1. macOS 1.3 was rejected (Guideline 4): Sign in with Apple button had no Apple logo.
   Fixed in `ceeb71e` (official `SignInWithAppleButton`, `AuthService.completeSignIn(with:)`,
   `AccountSheet` in AccountMenuView.swift). NOT yet compiled.
2. Build the Mac scheme: `xcodebuild -project HabitTracker.xcodeproj -scheme "HabitTracker Mac" -destination 'platform=macOS' build`
   then iOS: `-scheme HabitTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`.
3. Fix errors, then run the Mac app and review every screen (Home, Calendar, Stats, Settings, Account,
   Add/Edit habit, onboarding) in light/dark and at small/large window sizes. Bring Mac up to parity with
   the Phase 5 iOS UI. Ads and Remove Ads are iOS-only by design.
4. Then rebuild iOS and run tests to make sure nothing regressed.

## App Store Connect (app id 6760203054)
- iOS 1.3 Ready for Distribution; macOS 1.3 Rejected (see above).
- Remove Ads IAP not created yet: blocked until the Account Holder accepts the updated
  Developer Program License Agreement. Planned: Non-Consumable, ref "Remove Ads",
  id `com.nagasiddharthadonepudi.HabitTracker.removeads`, $2.99, all countries, Family Sharing on,
  display "Remove Ads", description "Remove all ads. One-time purchase." Needs a review screenshot.
- Never accept agreements, enter passwords, or submit for review on the owner's behalf.

## Design rules (owner preferences)
- Violet (AccentColor) = brand/progress, gold (RewardGold) = achievements only, never text,
  green = done, orange = skipped. Purple removed from habit colors (brown added).
- Lightweight, no bloat. Short, warm copy ("Done for today", next-habit lines, not "1 left").
- Owner likes concise, direct, opinionated answers; no em dashes.
