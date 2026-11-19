# Habit: Grab It - Modernization Plan

Guiding rule: lightweight and bloat-free. Prefer system components over custom chrome, add no new dependencies, and only add features that remove friction from the daily check-in.

1. **Correctness** (done): streaks (weekly schedules, live-streak off-by-one, interval habits, longest recompute), deterministic same-day entry lookup with CloudKit duplicates, time zone travel, reminder remove/add race, 64 pending notification cap, Siri intent consistency, backup restore recomputes streaks, unit tests.
2. **Sync and data safety** (done): no container-swap "Sync now" (status row instead, from real CloudKit events), no silent in-memory fallback, duplicate habits/entries merged on launch and after every iCloud import (deterministic across devices), duplicate names blocked when adding, sign-out actually stops sync, account deletion deletes the iCloud copy, backups keep reminders, emoji, custom color and interval progress.
3. **Remove Ads purchase**: one-time non-consumable "Remove Ads" via StoreKit 2 (no extra SDK). Hide the ad card and skip AdMob start-up for buyers, Restore Purchases in Settings, entitlement re-verified with `Transaction.currentEntitlements`. AdMob test device IDs in Debug only. Later option: drop AdMob entirely and rely on the purchase plus an optional tip jar.
4. **Performance and code health**: day-keyed lookups, computed streaks (retire synced Streak model), nothing heavy on launch, Swift 6 + @Observable, align deployment targets.
5. **UI refresh (iOS 26/27 Liquid Glass)**: remove hardcoded colors, shadows, floating button and tab bar overrides; Tab API with iOS 27 `Tab(role: .prominent)` for Add; haptics, symbol effects, numeric transitions; iOS 27 swipeActions outside List, `.reorderable()`, `toolbarMinimizeBehavior`; resizable iPhone layouts; interactive widget, lock screen widget, Control Center control; accessibility pass; remove the name-grouping workarounds in Home/Stats (no-ops now that duplicates are merged). iOS 27 APIs gated with availability checks.

Later: X-times-per-week goals, vacation mode on top of skip, optional note per check-in.
