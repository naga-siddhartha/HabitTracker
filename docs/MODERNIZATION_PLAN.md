# Habit: Grab It - Modernization Plan

Guiding rule: lightweight and bloat-free. Prefer system components over custom chrome, add no new dependencies, and only add features that remove friction from the daily check-in.

## Phase 1 - Correctness (in progress)
- Streaks: respect weekly schedules (inactive days don't break streaks), no off-by-one on a live streak, count interval habits consistently, recompute longest streak from history.
- Entries: deterministic same-day lookup even with CloudKit duplicates; merge duplicates on write.
- Reminders: fix remove/add race that can delete freshly scheduled reminders; stay under iOS's 64 pending notification cap.
- Widget/Siri intent: use shared store logic (day matching, interval habits, streak + widget refresh).
- Unit tests for all of the above.

## Phase 2 - Sync and data safety
- Remove the container-swap "Sync now" (CloudKit syncs on its own); show real sync status instead.
- No silent in-memory fallback: surface the error and keep data on disk.
- One-time dedupe of habits/entries created by sync, then delete the name-grouping workarounds in Home/Stats.
- Delete account also wipes the user's iCloud data (Guideline 5.1.1(v)).

## Phase 3 - Performance and code health
- Day-keyed entry lookup; compute streaks on demand and retire the synced `Streak` model.
- Move streak work off app launch.
- Swift 6 language mode, `@Observable` instead of `ObservableObject`, drop `nonisolated(unsafe)` in AuthService.
- Align deployment targets; stop tracking `.DS_Store`; ship AdMob test IDs only in Debug.

## Phase 4 - UI refresh (iOS 26/27 Liquid Glass)
Strip custom chrome so the system design does the work:
- Replace hardcoded colors, custom shadows and the hand-rolled blue floating button with system backgrounds and glass button styles. Remove `UITabBar.appearance()` overrides. Lets the iOS 27 Liquid Glass slider, Reduce Transparency and Increase Contrast work properly.
- Move to the `Tab` API; on iOS 27 use `Tab(role: .prominent)` for "Add habit" instead of the floating button.
- Feel: `.sensoryFeedback(.success)` on check-off, `.symbolEffect` on the checkmark, `.contentTransition(.numericText())` on counts and the progress ring.
- iOS 27: `.swipeActions` on Home rows (now works outside `List`) for complete/skip, `.reorderable()` for custom habit order, `.toolbarMinimizeBehavior` on scroll, item-bound alerts/dialogs.
- Resizable iPhone apps (iOS 27): verify layouts at narrow/wide widths.
- Widgets: tap-to-complete (`Button(intent:)`), a lock screen accessory widget, and a Control Center control. Skip the extra-large size.
- Accessibility pass: Dynamic Type at XXL, VoiceOver labels on rows, contrast with glass.
- Gate iOS 27-only APIs with `if #available(iOS 27, *)`; keep iOS 17 as the minimum.

Decision needed: AdMob is the heaviest dependency (SDK size, tracking, ATT prompt). Replacing it with a one-time "Remove Ads"/tip purchase fits the bloat-free goal.

## Later (small, high-value features)
- "X times per week" goals.
- Vacation mode built on existing skip.
- Optional one-line note per check-in.
