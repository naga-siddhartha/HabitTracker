# Privacy policy – source of truth

**Single source of truth:** `docs/privacy.html` in this repo.

This file is the canonical privacy policy for Ritual Log. It includes:

- Sign in with Apple (user identifier, optional name/email)
- Account data storage (Keychain on device)
- Optional iCloud/CloudKit sync and transmission (Section 5)
- Account deletion and how to revoke Apple ID access (Section 3)
- Last updated date (e.g. March 2026)

**When you update the public site:** Copy `docs/privacy.html` to the **RitualLog** repo as `privacy.html`, then deploy. The app’s **Privacy Policy URL** (Info.plist `PrivacyPolicyURL` and App Store Connect) points to that site. Edit only this file first; then copy to RitualLog so both stay in sync.
